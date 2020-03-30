import Foundation
import Dispatch

struct Observer<T> {
  let queue: DispatchQueue
  let notify: (Result<T, Error>) -> Void
}
