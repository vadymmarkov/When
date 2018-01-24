import Foundation
import Dispatch

let backgroundQueue = DispatchQueue.global(qos: DispatchQoS.QoSClass.background)
let instantQueue = DispatchQueue(label: "When.InstantQueue", attributes: [])
let barrierQueue = DispatchQueue(label: "When.BarrierQueue", attributes: [])

public func when<T, U>(_ p1: Promise<T>, _ p2: Promise<U>) -> Promise<(T, U)> {
  return when([p1.asVoid(on: instantQueue), p2.asVoid(on: instantQueue)]).then(on: instantQueue) { _ in
    (p1.state.result!.value!, p2.state.result!.value!)
  }
}

public func when<T, U, V>(_ p1: Promise<T>, _ p2: Promise<U>, _ p3: Promise<V>) -> Promise<(T, U, V)> {
  return when([p1.asVoid(on: instantQueue), p2.asVoid(on: instantQueue), p3.asVoid(on: instantQueue)])
    .then(on: instantQueue, ({ _ in
      (p1.state.result!.value!, p2.state.result!.value!, p3.state.result!.value!)
    }))
}

public func when<T>(_ promises: [Promise<T>]) -> Promise<[T]> {
  let masterPromise = Promise<[T]>()
  var (total, resolved) = (promises.count, 0)
  
  if promises.isEmpty {
    masterPromise.resolve([])
  } else {
    promises.forEach { promise in
      _ = promise
        .done({ value in
          barrierQueue.sync {
            resolved += 1
            if resolved == total {
              masterPromise.resolve(promises.map{ $0.state.result!.value! })
            }
          }
        })
        .fail({ error in
          barrierQueue.sync {
            masterPromise.reject(error)
          }
        })
    }
  }
  
  return masterPromise
}
