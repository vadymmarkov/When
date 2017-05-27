public enum PromiseError: Error {
  case cancelled
}

public enum FailurePolicy {
  case allErrors
  case notCancelled
}
