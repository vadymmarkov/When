import Foundation

public final class Promise<T> {

  public typealias DoneHandler = T -> Void
  public typealias FailureHandler = ErrorType -> Void
  public typealias CompletionHandler = Result<T> -> Void

  public let key = NSUUID().UUIDString

  var queue: dispatch_queue_t
  private(set) var state: State<T>

  private var observer: Observer<T>?
  private var doneHandler: DoneHandler?
  private var failureHandler: FailureHandler?
  private var completionHandler: CompletionHandler?

  // MARK: - Initialization

  public init(@noescape _ throwingExpr: Void throws -> T, queue: dispatch_queue_t = serialQueue()) {
    state = .Pending
    self.queue = queue

    do {
      let value = try throwingExpr()
      resolve(value)
    } catch {
      reject(error)
    }
  }

  public init(state: State<T> = .Pending, queue: dispatch_queue_t = serialQueue()) {
    self.state = state
    self.queue = queue
  }

  // MARK: - States

  public func reject(error: ErrorType) {
    dispatch_sync(queue) {
      guard self.state.isPending else {
        return
      }

      let state: State<T> = .Rejected(error: error)
      self.notify(state: state)
    }
  }

  public func resolve(value: T) {
    dispatch_sync(queue) {
      guard self.state.isPending else {
        return
      }

      let state: State<T> = .Resolved(value: value)
      self.notify(state: state)
    }
  }

  // MARK: - Callbacks

  public func done(handler: DoneHandler) -> Self {
    doneHandler = handler
    return self
  }

  public func fail(handler: FailureHandler) -> Self {
    failureHandler = handler
    return self
  }

  public func always(handler: CompletionHandler) -> Self {
    completionHandler = handler
    return self
  }

  // MARK: - Helpers

  private func notify(state state: State<T>?) {
    guard let state = state, result = state.result else {
      return
    }

    self.state = state

    switch result {
    case let .Success(value):
      doneHandler?(value)
    case let .Failure(error):
      failureHandler?(error)
    }

    completionHandler?(result)

    if let observer = observer {
      dispatch_async(observer.queue) {
        observer.notify(result)
      }
    }

    observer = nil
  }

  private func addObserver<U>(promise: Promise<U>, _ body: T throws -> U) {
    observer = Observer(queue: queue) { result in
      switch result {
      case let .Success(value):
        do {
          promise.resolve(try body(value))
        } catch {
          promise.reject(error)
        }
      case let .Failure(error):
        promise.reject(error)
      }
    }
  }
}

// MARK: - Then

extension Promise {

  public func then<U>(on q: dispatch_queue_t = dispatch_get_main_queue(), _ body: T throws -> U) -> Promise<U> {
    let promise = Promise<U>()

    addObserver(promise, body)
    notify(state: state)

    return promise
  }

  public func then<U>(on q: dispatch_queue_t = dispatch_get_main_queue(), _ body: T throws -> Promise<U>) -> Promise<U> {
    let promise = Promise<U>()

    observer = Observer(queue: queue) { result in
      switch result {
      case let .Success(value):
        do {
          let nextPromise = try body(value)
          nextPromise.addObserver(promise, { value -> U in
            return value
          })
        } catch {
          promise.reject(error)
        }
      case let .Failure(error):
        promise.reject(error)
      }
    }

    notify(state: state)

    return promise
  }
}
