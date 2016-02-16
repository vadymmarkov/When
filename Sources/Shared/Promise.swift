import Foundation

public final class Promise<T> {

  public typealias DoneHandler = T -> Void
  public typealias FailureHandler = ErrorType -> Void
  public typealias CompletionHandler = Result<T> -> Void

  public let key = NSUUID().UUIDString

  var queue: dispatch_queue_t
  private(set) var state: State<T>

  private(set) var observer: Observer<T>?
  private(set) var doneHandler: DoneHandler?
  private(set) var failureHandler: FailureHandler?
  private(set) var completionHandler: CompletionHandler?

  // MARK: - Initialization

  public init(@noescape _ body: Void throws -> T, queue: dispatch_queue_t = mainQueue) {
    state = .Pending
    self.queue = queue

    do {
      let value = try body()
      resolve(value)
    } catch {
      reject(error)
    }
  }

  public init(state: State<T> = .Pending, queue: dispatch_queue_t = mainQueue) {
    self.state = state
    self.queue = queue
  }

  // MARK: - States

  public func reject(error: ErrorType) {
    dispatch_async(queue) {
      guard self.state.isPending else {
        return
      }

      let state: State<T> = .Rejected(error: error)
      self.notify(state: state)
    }
  }

  public func resolve(value: T) {
    dispatch_async(queue) {
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

    doneHandler = nil
    failureHandler = nil
    completionHandler = nil
    observer = nil
  }

  private func addObserver<U>(on queue: dispatch_queue_t, promise: Promise<U>, _ body: T throws -> U?) {
    observer = Observer(queue: queue) { result in
      switch result {
      case let .Success(value):
        do {
          if let result = try body(value) {
            promise.resolve(result)
          }
        } catch {
          promise.reject(error)
        }
      case let .Failure(error):
        promise.reject(error)
      }
    }

    notify(state: state)
  }
}

// MARK: - Then

extension Promise {

  public func then<U>(on queue: dispatch_queue_t = mainQueue, _ body: T throws -> U) -> Promise<U> {
    let promise = Promise<U>()
    addObserver(on: queue, promise: promise, body)

    return promise
  }

  public func then<U>(on queue: dispatch_queue_t = mainQueue, _ body: T throws -> Promise<U>) -> Promise<U> {
    let promise = Promise<U>()

    addObserver(on: queue, promise: promise) { value -> U? in
      let nextPromise = try body(value)
      nextPromise.addObserver(on: queue, promise: promise) { value -> U in
        return value
      }

      return nil
    }

    return promise
  }

  public func asVoid() -> Promise<Void> {
    return then(on: asyncQueue) { _ in return }
  }
}
