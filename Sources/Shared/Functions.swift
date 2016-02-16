import Foundation

let mainQueue = dispatch_get_main_queue()
let backgroundQueue = dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0)
let instantQueue = dispatch_queue_create("When.InstantQueue", nil)
let barrierQueue = dispatch_queue_create("When.BarrierQueue", DISPATCH_QUEUE_CONCURRENT)

public func when<T, U>(p1: Promise<T>, _ p2: Promise<U>) -> Promise<(T, U)> {
  return when([p1.asVoid(), p2.asVoid()]).then(on: instantQueue) {
    (p1.state.result!.value!, p2.state.result!.value!)
  }
}

public func when<T, U, V>(p1: Promise<T>, _ p2: Promise<U>, _ p3: Promise<V>) -> Promise<(T, U, V)> {
  return when([p1.asVoid(), p2.asVoid(), p3.asVoid()]).then(on: instantQueue) {
    (p1.state.result!.value!, p2.state.result!.value!, p3.state.result!.value!)
  }
}

private func when<T>(promises: [Promise<T>]) -> Promise<Void> {
  let masterPromise = Promise<Void>()
  var (total, resolved) = (promises.count, 0)

  promises.forEach { promise in
    promise
      .done({ value in
        dispatch_barrier_sync(barrierQueue) {
          resolved++
          if resolved == total {
            masterPromise.resolve()
          }
        }
      })
      .fail({ error in
        dispatch_barrier_sync(barrierQueue) {
          masterPromise.reject(error)
        }
      })
  }

  return masterPromise
}
