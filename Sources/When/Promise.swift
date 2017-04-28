import Foundation

open class Promise<T> {

  public typealias DoneHandler = (T) -> Void
  public typealias FailureHandler = (Error) -> Void
  public typealias CompletionHandler = (Result<T>) -> Void

  open let key = UUID().uuidString

  var queue: DispatchQueue
  fileprivate(set) public var state: State<T>

  fileprivate(set) var observers: [Observer<T>]?
  fileprivate(set) var doneHandlers: [DoneHandler]?
  fileprivate(set) var failureHandlers: [FailureHandler]?
  fileprivate(set) var completionHandlers: [CompletionHandler]?

  // MARK: - Initialization

  public init(queue: DispatchQueue = mainQueue, _ body: @escaping (Void) throws -> T) {
    state = .pending
    self.queue = queue

    dispatch(queue) {
      do {
        let value = try body()
        self.resolve(value)
      } catch {
        self.reject(error)
      }
    }
  }
    
  public init(queue: DispatchQueue = mainQueue,
              _ body: @escaping (_ resolve: (T) -> Void, _ reject: (Error) -> Void) -> Void) {
    state = .pending
    self.queue = queue
    
    dispatch(queue) {
      body(self.resolve, self.reject)
    }
  }

  public init(queue: DispatchQueue = mainQueue, state: State<T> = .pending) {
    self.queue = queue
    self.state = state
  }

  // MARK: - States

  open func reject(_ error: Error) {
    guard self.state.isPending else {
      return
    }

    let state: State<T> = .rejected(error: error)
    update(state: state)
  }

  open func resolve(_ value: T) {
    guard self.state.isPending else {
      return
    }

    let state: State<T> = .resolved(value: value)
    update(state: state)
  }

  // MARK: - Callbacks

  @discardableResult open func done(_ handler: @escaping DoneHandler) -> Self {
    doneHandlers?.append(handler) ?? { doneHandlers = [handler] }()
    return self
  }

  @discardableResult open func fail(_ handler: @escaping FailureHandler) -> Self {
    failureHandlers?.append(handler) ?? { failureHandlers = [handler] }()
    return self
  }

  @discardableResult open func always(_ handler: @escaping CompletionHandler) -> Self {
    completionHandlers?.append(handler) ?? { completionHandlers = [handler] }()
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

  fileprivate func notify(_ result: Result<T>) {
    switch result {
    case let .success(value):
      for doneHandler in doneHandlers ?? [] {
        doneHandler(value)
      }
    case let .failure(error):
      for failureHandler in failureHandlers ?? [] {
        failureHandler(error)
      }
    }

    for completionHandler in completionHandlers ?? [] {
      completionHandler(result)
    }

    for observer in observers ?? [] {
      dispatch(observer.queue) {
        observer.notify(result)
      }
    }

    doneHandlers = nil
    failureHandlers = nil
    completionHandlers = nil
    observers = nil
  }

  fileprivate func addObserver<U>(on queue: DispatchQueue, promise: Promise<U>, _ body: @escaping (T) throws -> U?) {
    let observer = Observer<T>(queue: queue) { result in
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
    observers?.append(observer) ?? { observers = [observer] }()

    update(state: state)
  }

  fileprivate func dispatch(_ queue: DispatchQueue, closure: @escaping () -> Void) {
    if queue === instantQueue {
      closure()
    } else {
      queue.async(execute: closure)
    }
  }
}

// MARK: - Then

extension Promise {

  public func then<U>(on queue: DispatchQueue = mainQueue, _ body: @escaping (T) throws -> U) -> Promise<U> {
    let promise = Promise<U>()
    addObserver(on: queue, promise: promise, body)

    return promise
  }

  public func then<U>(on queue: DispatchQueue = mainQueue, _ body: @escaping (T) throws -> Promise<U>) -> Promise<U> {
    let promise = Promise<U>()

    addObserver(on: queue, promise: promise) { value -> U? in
      let nextPromise = try body(value)
      nextPromise.addObserver(on: queue, promise: promise) { value -> U? in
        return value
      }

      return nil
    }

    return promise
  }

  public func thenInBackground<U>(_ body: @escaping (T) throws -> U) -> Promise<U> {
    return then(on: backgroundQueue, body)
  }

  public func thenInBackground<U>(_ body: @escaping (T) throws -> Promise<U>) -> Promise<U> {
    return then(on: backgroundQueue, body)
  }

  func asVoid() -> Promise<Void> {
    return then(on: instantQueue) { _ in return }
  }
}
