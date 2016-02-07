import Foundation

enum State<T> {
  case Pending, Fulfilled, Rejected
}

class Promise<T> {

  var state = State<T>.Pending
}
