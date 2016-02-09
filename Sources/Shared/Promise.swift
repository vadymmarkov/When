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

  public init(state: State<T> = .Pending, queue: dispatch_queue_t = serialQueue()) {
    self.state = state
    self.queue = queue
  }

  // MARK: - States

  public func reject(error: ErrorType) {
    dispatch_sync(queue) {
      guard self.state.isPending() else {
        return
      }

      let state: State<T> = .Rejected(error: error)
      self.notify(state: state)
    }
  }

  public func resolve(value: T) {
    dispatch_sync(queue) {
      guard self.state.isPending() else {
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
}

// MARK: - Then

extension Promise {

  public func then<U>(
    queue: dispatch_queue_t = backgroundQueue(),
    doneFilter: (T -> State<U>?)? = nil,
    failFilter: (ErrorType -> State<U>?)? = nil) -> Promise<U> {

      let promise = Promise<U>()

      observer = Observer(queue: queue) { result in
        switch result {
        case let .Success(value):
          promise.notify(state: doneFilter?(value))
        case let .Failure(error):
          promise.notify(state: failFilter?(error))
        }
      }

      notify(state: state)

      return promise
  }

  public func then<U>(
    queue: dispatch_queue_t = backgroundQueue(),
    doneFilter: ((T, Promise<U>) -> Void)? = nil,
    failFilter: ((ErrorType, Promise<U>) -> Void)? = nil) -> Promise<U> {

      let promise = Promise<U>()

      observer = Observer(queue: queue) { result in
        switch result {
        case let .Success(value):
          doneFilter?(value, promise)
        case let .Failure(error):
          failFilter?(error, promise)
        }
      }

      notify(state: state)

      return promise
  }
}
