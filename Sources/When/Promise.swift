import Foundation
import Dispatch

open class Promise<T> {
  public typealias DoneHandler = (T) -> Void
  public typealias FailureHandler = (Error) -> Void
  public typealias CompletionHandler = (Result<T>) -> Void

  public let key = UUID().uuidString
  let queue: DispatchQueue
  fileprivate let observerQueue = DispatchQueue(label: "When.ObserverQueue", attributes: [])
  fileprivate(set) public var state: State<T>

  private var _observer: Observer<T>?
  fileprivate(set) var observer: Observer<T>? {
    get {
      return observerQueue.sync {
        return _observer
      }
    }
    set {
      observerQueue.sync {
        _observer = newValue
      }
    }
  }
  fileprivate(set) var doneHandlers = [DoneHandler]()
  fileprivate(set) var failureHandlers = [FailureHandler]()
  fileprivate(set) var completionHandlers = [CompletionHandler]()

  // MARK: - Initialization

  /// Create a promise with a given state.
  public init(queue: DispatchQueue = .main, state: State<T> = .pending) {
    self.queue = queue
    self.state = state
  }

  /// Create a promise that resolves using a synchronous closure.
  public convenience init(queue: DispatchQueue = .main, _ body: @escaping () throws -> T) {
    self.init(queue: queue, state: .pending)
    dispatch(queue) {
      do {
        let value = try body()
        self.resolve(value)
      } catch {
        self.reject(error)
      }
    }
  }

  /// Create a promise that resolves using an asynchronous closure that can either resolve or reject.
  public convenience init(queue: DispatchQueue = .main,
                          _ body: @escaping (_ resolve: (T) -> Void, _ reject: (Error) -> Void) -> Void) {
    self.init(queue: queue, state: .pending)
    dispatch(queue) {
      body(self.resolve, self.reject)
    }
  }

  /// Create a promise that resolves using an asynchronous closure that can only resolve.
  public convenience init(queue: DispatchQueue = .main, _ body: @escaping (@escaping (T) -> Void) -> Void) {
    self.init(queue: queue, state: .pending)
    dispatch(queue) {
      body(self.resolve)
    }
  }

  // MARK: - States

  /**
   Rejects a promise with a given error.
   */
  public func reject(_ error: Error) {
    guard self.state.isPending else {
      return
    }

    let state: State<T> = .rejected(error: error)
    update(state: state)
  }

  /**
   Resolves a promise with a given value.
   */
  public func resolve(_ value: T) {
    guard self.state.isPending else {
      return
    }

    let state: State<T> = .resolved(value: value)
    update(state: state)
  }

  /// Rejects a promise with the cancelled error.
  open func cancel() {
    reject(PromiseError.cancelled)
  }

  // MARK: - Callbacks

  /**
   Adds a handler to be called when the promise object is resolved with a value.
   */
  @discardableResult public func done(_ handler: @escaping DoneHandler) -> Self {
    doneHandlers.append(handler)
    return self
  }

  /**
   Adds a handler to be called when the promise object is rejected with an error.
   */
  @discardableResult public func fail(policy: FailurePolicy = .notCancelled,
                                      _ handler: @escaping FailureHandler) -> Self {
    let failureHandler: FailureHandler = { error in
      if case PromiseError.cancelled = error, policy == .notCancelled {
        return
      }
      handler(error)
    }
    failureHandlers.append(failureHandler)
    return self
  }

  /**
   Adds a handler to be called when the promise object is either resolved or rejected.
   This callback will be called after done or fail handlers
   **/
  @discardableResult public func always(_ handler: @escaping CompletionHandler) -> Self {
    completionHandlers.append(handler)
    return self
  }

  // MARK: - Helpers

  fileprivate func update(state: State<T>?) {
    dispatch(queue) {
      guard let state = state, let result = state.result else {
        return
      }

      self.state = state
      self.notify(result)
    }
  }

  private func notify(_ result: Result<T>) {
    switch result {
    case let .success(value):
      for doneHandler in doneHandlers {
        doneHandler(value)
      }
    case let .failure(error):
      for failureHandler in failureHandlers {
        failureHandler(error)
      }
    }
    for completionHandler in completionHandlers {
      completionHandler(result)
    }

    if let observer = observer {
      dispatch(observer.queue) {
        observer.notify(result)
        self.observer = nil
      }
    }

    doneHandlers.removeAll()
    failureHandlers.removeAll()
    completionHandlers.removeAll()
  }

  private func dispatch(_ queue: DispatchQueue, closure: @escaping () -> Void) {
    if queue === instantQueue {
      closure()
    } else {
      queue.async(execute: closure)
    }
  }
}

// MARK: - Then

extension Promise {
  @discardableResult public func then<U>(on queue: DispatchQueue = .main, _ body: @escaping (T) throws -> U) -> Promise<U> {
    let promise = Promise<U>(queue: queue)
    addObserver(on: queue, promise: promise, body)
    return promise
  }

  @discardableResult public func then<U>(on queue: DispatchQueue = .main, _ body: @escaping (T) throws -> Promise<U>) -> Promise<U> {
    let promise = Promise<U>(queue: queue)
    addObserver(on: queue, promise: promise) { value -> U? in
      let nextPromise = try body(value)
      nextPromise.addObserver(on: queue, promise: promise) { value -> U? in
        return value
      }

      return nil
    }
    return promise
  }

  @discardableResult public func thenInBackground<U>(_ body: @escaping (T) throws -> U) -> Promise<U> {
    return then(on: backgroundQueue, body)
  }

  @discardableResult public func thenInBackground<U>(_ body: @escaping (T) throws -> Promise<U>) -> Promise<U> {
    return then(on: backgroundQueue, body)
  }

  fileprivate func addObserver<U>(on queue: DispatchQueue, promise: Promise<U>, _ body: @escaping (T) throws -> U?) {
    observer = Observer(queue: queue) { result in
      switch result {
      case let .success(value):
        do {
          if let result = try body(value) {
            promise.resolve(result)
          }
        } catch {
          promise.reject(error)
        }
      case let .failure(error):
        promise.reject(error)
      }
    }

    update(state: state)
  }

  /**
   Returns a promise with Void as a result type.
   */
  public func asVoid(on queue: DispatchQueue = .main) -> Promise<Void> {
    return then(on: queue) { _ in return }
  }
}

// MARK: - Recover

extension Promise {
  /**
   Helps to recover from certain errors. Continues the chain if a given closure does not throw.
   */
  public func recover(on queue: DispatchQueue = .main, _ body: @escaping (Error) throws -> T) -> Promise<T> {
    let promise = Promise<T>(queue: queue)
    addRecoverObserver(on: queue, promise: promise, body)
    return promise
  }

  /**
   Helps to recover from certain errors. Continues the chain if a given closure does not throw.
   */
  public func recover(on queue: DispatchQueue = .main,
                      _ body: @escaping (Error) throws -> Promise<T>) -> Promise<T> {
    let promise = Promise<T>(queue: queue)
    addRecoverObserver(on: queue, promise: promise) { error -> T? in
      let nextPromise = try body(error)
      nextPromise.addObserver(on: queue, promise: promise) { value -> T? in
        return value
      }

      return nil
    }
    return promise
  }

  /**
   Adds a recover observer.
   */
  private func addRecoverObserver(on queue: DispatchQueue, promise: Promise<T>,
                                  _ body: @escaping (Error) throws -> T?) {
    observer = Observer(queue: queue) { result in
      switch result {
      case let .success(value):
        promise.resolve(value)
      case let .failure(error):
        do {
          if let result = try body(error) {
            promise.resolve(result)
          }
        } catch {
          promise.reject(error)
        }
      }
    }
    
    update(state: state)
  }
}
