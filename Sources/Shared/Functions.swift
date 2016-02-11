import Foundation

func backgroundQueue() -> dispatch_queue_t {
  return dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0)
}

func serialQueue() -> dispatch_queue_t {
  return dispatch_queue_create("When.SerialQueue", DISPATCH_QUEUE_SERIAL)
}

public func when<T>(promises: [Promise<T>]) -> Promise<[String: T]> {
  return when(promises) as Promise<[String: T]>
}

public func when(promises: [Promise<Any>]) -> Promise<[String: Any]> {
  let masterPromise = Promise<[String: Any]>()
  var values = [String: Any]()

  var (total, resolved) = (promises.count, 0)

  promises.forEach { promise in
    promise.then(
      doneFilter: { value -> State<Any>? in
        dispatch_sync(masterPromise.queue) {
          resolved++
          values[promise.key] = value

          if resolved == total {
            masterPromise.resolve(values)
          }
        }

        return nil
      },
      failFilter: { error -> State<Any>? in
        dispatch_sync(masterPromise.queue) {
          masterPromise.reject(error)
        }

        return nil
      }
    )
  }

  return masterPromise
}
