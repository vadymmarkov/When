import UIKit
import When

class ViewController: UIViewController {

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = UIColor.whiteColor()

    var stringQueue = Queue<String>()
    stringQueue.enqueue("String")
    stringQueue.dequeue() // "String"

    var intQueue = Queue<Int>()
    intQueue.enqueue(1)
    intQueue.dequeue() // 1

    Request.make()
      .done({ object in
        print("Done 1")
        print(object)
      })
      .fail({ error in
        print("Fail 1")
        print(error)
      })
      .always({ result in
        print("Always 1")
        switch result {
        case let .Success(value):
          print(value)
        case let .Failure(error):
          print(error)
          break
        }
      })
      .then(map: { result in
        return State.Fulfilled(value: "Hello")
      })
      .next(next: { result, promise in
        print("Next 1")
        delay(2.0) {
          switch result {
          case let .Success(value):
            promise.fulfill(value + "Stringy")
          case let .Failure(error):
            promise.reject(error)
            break
          }
        }
      })
      .done({ object in
        print(object)
      })
  }
}

struct Queue<T> {

  private var items = [T]()

  mutating func enqueue(item: T) {
    items.append(item)
  }

  mutating func dequeue() -> T? {
    return items.removeFirst()
  }

  func peek() -> T? {
    return items.first
  }

  func isEmpty() -> Bool {
    return items.isEmpty
  }
}




struct Request {

  enum Error: ErrorType {
    case Er
  }

  static func make() -> Promise<String> {
    let promise = Promise<String>()

    delay(2.0) {() -> Void in
      promise.reject(Error.Er)
    }

    return promise
  }
}

public enum DispatchQueue {
  case Main, Interactive, Initiated, Utility, Background, Custom(dispatch_queue_t)
}

private func getQueue(queue queueType: DispatchQueue = .Main) -> dispatch_queue_t {
  let queue: dispatch_queue_t

  switch queueType {
  case .Main:
    queue = dispatch_get_main_queue()
  case .Interactive:
    queue = dispatch_get_global_queue(QOS_CLASS_USER_INTERACTIVE, 0)
  case .Initiated:
    queue = dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0)
  case .Utility:
    queue = dispatch_get_global_queue(QOS_CLASS_UTILITY, 0)
  case .Background:
    queue = dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0)
  case .Custom(let userQueue):
    queue = userQueue
  }

  return queue
}

public func delay(delay:Double, queue queueType: DispatchQueue = .Main, closure: () -> Void) {
  dispatch_after(
    dispatch_time(DISPATCH_TIME_NOW, Int64(delay * Double(NSEC_PER_SEC))),
    getQueue(queue: queueType),
    closure
  )
}

public func dispatch(queue queueType: DispatchQueue = .Main, closure: () -> Void) {
  dispatch_async(getQueue(queue: queueType), {
    closure()
  })
}

