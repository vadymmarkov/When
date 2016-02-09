import Foundation

struct Observer<T> {
  let notify: Result<T> -> Void
  let queue: dispatch_queue_t
}
