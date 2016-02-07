import Foundation

enum State<T> {
  case Pending, Fulfilled, Rejected
}

class Promise<T> {

  typealias Executor = (resolve: (object: T) -> Void, revoke: (error: ErrorType) -> Void) -> Void

  var state = State<T>.Pending
  var executor: Executor
}
