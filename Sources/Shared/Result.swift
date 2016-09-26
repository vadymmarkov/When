public enum Result<T> {
  case success(value: T)
  case failure(error: Error)

  public var value: T? {
    let value: T?

    switch self {
    case let .success(successValue):
      value = successValue
    case .failure:
      value = nil
    }

    return value
  }

  public var error: Error? {
    let error: Error?

    switch self {
    case let .failure(errorValue):
      error = errorValue
    case .success:
      error = nil
    }

    return error
  }

  public func map<U>(_ closure: (T) -> U) -> Result<U> {
    switch self {
    case let .success(value):
      return .success(value: closure(value))
    case let .failure(error):
      return Result<U>.failure(error: error)
    }
  }
}
