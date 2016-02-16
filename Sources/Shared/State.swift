public enum State<T>: Equatable {
  case Pending
  case Resolved(value: T)
  case Rejected(error: ErrorType)

  public var isPending: Bool {
    return result == nil
  }

  public var isResolved: Bool {
    if case .Resolved = self {
      return true
    } else {
      return false
    }
  }

  public var isRejected: Bool {
    if case .Rejected = self {
      return true
    } else {
      return false
    }
  }

  public func map<U>(closure: T -> U) -> State<U> {
    switch self {
    case let .Resolved(value):
      return .Resolved(value: closure(value))
    case let .Rejected(error):
      return State<U>.Rejected(error: error)
    case .Pending:
      return State<U>.Pending
    }
  }

  public var result: Result<T>? {
    switch self {
    case let .Resolved(value):
      return .Success(value: value)
    case let .Rejected(error):
      return .Failure(error: error)
    case .Pending:
      return nil
    }
  }
}

public func ==<T>(lhs: State<T>, rhs: State<T>) -> Bool {
  return lhs.isPending == rhs.isPending
    || lhs.isResolved == rhs.isResolved
    || lhs.isRejected == rhs.isRejected
}
