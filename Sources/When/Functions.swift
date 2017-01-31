import Foundation

let mainQueue = DispatchQueue.main
let backgroundQueue = DispatchQueue.global(qos: DispatchQoS.QoSClass.background)
let instantQueue = DispatchQueue(label: "When.InstantQueue", attributes: [])
let barrierQueue = DispatchQueue(label: "When.BarrierQueue", attributes: DispatchQueue.Attributes.concurrent)

public func when<T, U>(_ p1: Promise<T>, _ p2: Promise<U>) -> Promise<(T, U)> {
  return when([p1.asVoid(), p2.asVoid()]).then(on: instantQueue) {
    (p1.state.result!.value!, p2.state.result!.value!)
  }
}

public func when<T, U, V>(_ p1: Promise<T>, _ p2: Promise<U>, _ p3: Promise<V>) -> Promise<(T, U, V)> {
  return when([p1.asVoid(), p2.asVoid(), p3.asVoid()]).then(on: instantQueue) {
    (p1.state.result!.value!, p2.state.result!.value!, p3.state.result!.value!)
  }
}

private func when<T>(_ promises: [Promise<T>]) -> Promise<Void> {
  let masterPromise = Promise<Void>()
  var (total, resolved) = (promises.count, 0)

  promises.forEach { promise in
    promise
      .done({ value in
        barrierQueue.sync(flags: .barrier, execute: {
          resolved += 1
          if resolved == total {
            masterPromise.resolve()
          }
        }) 
      })
      .fail({ error in
        barrierQueue.sync(flags: .barrier, execute: {
          masterPromise.reject(error)
        }) 
      })
  }

  return masterPromise
}
