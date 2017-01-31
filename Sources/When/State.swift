public enum State<T>: Equatable {
  case pending
  case resolved(value: T)
  case rejected(error: Error)

  public var isPending: Bool {
    return result == nil
  }

  public var isResolved: Bool {
    if case .resolved = self {
      return true
    } else {
      return false
    }
  }

  public var isRejected: Bool {
    if case .rejected = self {
      return true
    } else {
      return false
    }
  }

  public func map<U>(_ closure: (T) -> U) -> State<U> {
    switch self {
    case let .resolved(value):
      return .resolved(value: closure(value))
    case let .rejected(error):
      return State<U>.rejected(error: error)
    case .pending:
      return State<U>.pending
    }
  }

  public var result: Result<T>? {
    switch self {
    case let .resolved(value):
      return .success(value: value)
    case let .rejected(error):
      return .failure(error: error)
    case .pending:
      return nil
    }
  }
}

public func ==<T>(lhs: State<T>, rhs: State<T>) -> Bool {
  return lhs.isPending == rhs.isPending
    || lhs.isResolved == rhs.isResolved
    || lhs.isRejected == rhs.isRejected
}
