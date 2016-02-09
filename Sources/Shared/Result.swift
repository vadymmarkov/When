import Foundation

public enum Result<T> {
  case Success(value: T)
  case Failure(error: ErrorType)

  public func map<U>(closure: T -> U) -> Result<U> {
    switch self {
    case let .Success(value):
      return .Success(value: closure(value))
    case let .Failure(error):
      return Result<U>.Failure(error: error)
    }
  }
}
