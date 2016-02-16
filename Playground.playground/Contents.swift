// When iOS Playground

import Foundation
import XCPlayground
import When

enum Error: ErrorType {
  case NotFound
}

// MARK: - Basic usage

Promise({
  return "String"
}).always({ result in
  print("Always")
  print(result.value)
}).done({ value in
  print(value)
}).fail({ error in
  print(error)
})


// MARK: - With a body that transforms a result

// Failing example
let promise1 = Promise<String>()
promise1
  .then({ value in
    throw Error.NotFound
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
      throw Error.NotFound
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

// MARK: - When

let promise5 = Promise<Int>()
let promise6 = Promise<String>()
let promise7 = Promise<Int>()

when(promise5, promise6, promise7)
  .done({ value1, value2, value3 in
    print(value1)
    print(value2)
    print(value3)
  })

promise5.resolve(1)
promise6.resolve("String")
promise7.resolve(3)

XCPlaygroundPage.currentPage.needsIndefiniteExecution = true
