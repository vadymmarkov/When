import Foundation

struct Observer<T> {
  let queue: DispatchQueue
  let notify: (Result<T>) -> Void
}
