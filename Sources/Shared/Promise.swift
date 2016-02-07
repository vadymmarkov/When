import Foundation

enum State<T> {
  case Pending, Fulfilled, Rejected
}

class Promise<T> {

  typealias Executor = (resolve: (instance: T) -> Void, revoke: (error: ErrorType) -> Void) -> Void

  var state = State<T>.Pending
  var executor: Executor
  var fulfillment: T?
  var error: ErrorType?

  init(executor: Executor) {
    self.executor = executor
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), { () -> Void in
      self.executor(resolve: self.resolve, revoke: self.revoke)
    })
  }

  func resolve(instance: T) {
    if state == .Pending {
      fulfillment = instance
      state = .Fulfilled
    }
  }

  func revoke(error: ErrorType) {
    if state == .Pending {
      self.error = error
      state = .Rejected
    }
  }
}
