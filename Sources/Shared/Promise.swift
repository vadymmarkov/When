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

  public init(queue: dispatch_queue_t = mainQueue, @noescape _ body: Void throws -> T) {
    state = .Pending
    self.queue = queue

    do {
      let value = try body()
      resolve(value)
    } catch {
      reject(error)
    }
  }

  public init(queue: dispatch_queue_t = mainQueue, state: State<T> = .Pending) {
    self.state = state
    self.queue = queue
  }

  // MARK: - States

  public func reject(error: ErrorType) {
    guard self.state.isPending else {
      return
    }

    let state: State<T> = .Rejected(error: error)
    update(state: state)
  }

  public func resolve(value: T) {
    guard self.state.isPending else {
      return
    }

    let state: State<T> = .Resolved(value: value)
    update(state: state)
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

  private func update(state state: State<T>?) {
    dispatch(queue) {
      guard let state = state, result = state.result else {
        return
      }

      self.state = state
      self.notify(result)
    }
  }

  private func notify(result: Result<T>) {
    switch result {
    case let .Success(value):
      doneHandler?(value)
    case let .Failure(error):
      failureHandler?(error)
    }

    completionHandler?(result)

    if let observer = observer {
      dispatch(observer.queue) {
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

    update(state: state)
  }

  private func dispatch(queue: dispatch_queue_t, closure: () -> Void) {
    if queue === instantQueue {
      closure()
    } else {
      dispatch_async(queue, closure)
    }
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

  public func thenInBackground<U>(body: T throws -> U) -> Promise<U> {
    return then(on: backgroundQueue, body)
  }

  public func thenInBackground<U>(body: T throws -> Promise<U>) -> Promise<U> {
    return then(on: backgroundQueue, body)
  }

  func asVoid() -> Promise<Void> {
    return then(on: instantQueue) { _ in return }
  }
}
