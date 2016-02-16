import Foundation

struct Observer<T> {
  let queue: dispatch_queue_t
  let notify: Result<T> -> Void
}
