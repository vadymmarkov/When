public enum Result<T> {
  case Success(value: T)
  case Failure(error: ErrorType)

  public var value: T? {
    let value: T?

    switch self {
    case let .Success(successValue):
      value = successValue
    case .Failure:
      value = nil
    }

    return value
  }

  public var error: ErrorType? {
    let error: ErrorType?

    switch self {
    case let .Failure(errorValue):
      error = errorValue
    case .Success:
      error = nil
    }

    return error
  }

  public func map<U>(closure: T -> U) -> Result<U> {
    switch self {
    case let .Success(value):
      return .Success(value: closure(value))
    case let .Failure(error):
      return Result<U>.Failure(error: error)
    }
  }
}
