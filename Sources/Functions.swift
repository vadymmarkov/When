import Foundation
import Dispatch

let backgroundQueue = DispatchQueue.global(qos: DispatchQoS.QoSClass.background)
let instantQueue = DispatchQueue(label: "When.InstantQueue", attributes: [])
let barrierQueue = DispatchQueue(label: "When.BarrierQueue", attributes: [])

public func when<T, U>(_ p1: Promise<T>, _ p2: Promise<U>) -> Promise<(T, U)> {
  return when([p1.asVoid(on: instantQueue), p2.asVoid(on: instantQueue)]).then(on: instantQueue) { _ in
    (try! p1.state.result!.get(), try! p2.state.result!.get())
  }
}

public func when<T, U, V>(_ p1: Promise<T>, _ p2: Promise<U>, _ p3: Promise<V>) -> Promise<(T, U, V)> {
  return when([p1.asVoid(on: instantQueue), p2.asVoid(on: instantQueue), p3.asVoid(on: instantQueue)])
    .then(on: instantQueue, ({ _ in
      (try! p1.state.result!.get(), try! p2.state.result!.get(), try! p3.state.result!.get())
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
              masterPromise.resolve(promises.map{ try! $0.state.result!.get() })
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
