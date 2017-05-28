// When iOS Playground

import Foundation
import XCPlayground
import PlaygroundSupport
import When

enum Error: Swift.Error {
  case notFound
}

// MARK: - Basic usage

Promise({
  return "String"
}).always({ result in
  print("Always")
  print(result.value ?? "")
}).done({ value in
  print(value)
}).fail({ error in
  print(error)
})

// MARK: - A chain example

let promise = Promise<Data>()
promise
  .then({ data -> Int in
    return data.count
  }).then({ length -> Bool in
    return length > 5
  }).done({ value in
    print(value)
  })

promise.resolve("String".data(using: .utf8)!)

// MARK: - With a body that transforms a result

// Failing example
let promise1 = Promise<String>()
promise1
  .then({ value in
    throw Error.notFound
  })
  .fail({ error in
    print(error)
  })

promise1.resolve("String")

// Success example
let promise2 = Promise<String>()
promise2
  .then({ value in
    return "This is a " + value
  })
  .done({ value in
    print(value)
  })

promise2.resolve("String")

// MARK: - With a body that returns a new promise

// Failing example
let promise3 = Promise<String>()
promise3
  .then({ value in
    return Promise({
      throw Error.notFound
    })
  })
  .fail({ error in
    print(error)
  })

promise3.resolve("String")

// Success example
let promise4 = Promise<String>()
promise4
  .then({ value in
    return Promise({
      return "This is a " + value
    })
  })
  .done({ value in
    print(value)
  })

promise4.resolve("String")

// MARK: - Recover

let promise5 = Promise<String>()
promise5
  .then({ value -> String in
    throw Error.notFound
  })
  .recover({ error -> String in
    return "String"
  })
  .done({ value in
    print(value)
  })

// MARK: - When

let promise6 = Promise<Int>()
let promise7 = Promise<String>()
let promise8 = Promise<Int>()

when(promise6, promise7, promise8)
  .done({ value1, value2, value3 in
    print(value1)
    print(value2)
    print(value3)
  })

promise6.resolve(1)
promise7.resolve("String")
promise8.resolve(3)

PlaygroundPage.current.needsIndefiniteExecution = true
