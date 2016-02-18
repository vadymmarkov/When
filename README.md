![When](https://github.com/vadymmarkov/When/blob/master/Resources/WhenPresentation.png)

[![CI Status](http://img.shields.io/travis/vadymmarkov/When.svg?style=flat)](https://travis-ci.org/vadymmarkov/When)
[![Version](https://img.shields.io/cocoapods/v/When.svg?style=flat)](http://cocoadocs.org/docsets/When)
[![Carthage Compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![License](https://img.shields.io/cocoapods/l/When.svg?style=flat)](http://cocoadocs.org/docsets/When)
[![Platform](https://img.shields.io/cocoapods/p/When.svg?style=flat)](http://cocoadocs.org/docsets/When)

## Description

**When** is a lightweight implementation of [Promises](https://en.wikipedia.org/wiki/Futures_and_promises)
in Swift. It doesn't include any helper functions for iOS and OSX and it's
intentional, to remove redundant complexity and give you more freedom and
flexibility in your choices. It is type safe, thanks Swift generics, so you
could create ***promises*** with whatever type you want.

**When** can easily be integrated into your projects and libraries to move your
asynchronous code up to the next level.

## Table of Contents

<img src="https://github.com/vadymmarkov/When/blob/master/Resources/WhenIcon.png" alt="When Icon" width="190" height="190" align="right" />

* [Why?](#why)
* [Usage](#usage)
  * [Promise](#promise)
  * [Done](#done)
  * [Fail](#fail)
  * [Always](#always)
  * [Then](#then)
  * [When](#when)
* [Installation](#installation)
* [Author](#author)
* [Credits](#credits)
* [Contributing](#contributing)
* [License](#license)

## Why?

To make asynchronous code more readable and standardized:

```swift
fetchJSON().then({ data: NSData -> [[String: AnyObject]] in
  // Convert to JSON
  return json
}).then({ json: [[String: AnyObject]] -> [Entity] in
  // Map JSON
  // Save to database
  return items
}).done({ items: [Entity] in
  self.items = items
  self.tableView.reloadData()
}).error({ error in
  print(error)
})
```

## Usage

### Promise
A ***promise*** represents the future value of a task. Promises start in a pending
state and then could be resolved with a value or rejected with an error.

```swift
// Creates a new promise that could be resolved with a String value
let promise = Promise<String>()

// Resolves the promise
promise.resolve("String")

// Or rejects the promise
promise.reject(Error.NotFound)
```

```swift
// Creates a new promise that is resolved with a String value
let promise = Promise({
  return "String"
})
```

```swift
// Creates a new promise that is rejected with an ErrorType
let promise = Promise({
  //...
  throw Error.NotFound
})
```

Callbacks of the current ***promise*** and all the chained promises
(created with [then](#then)) are executed on the main queue by default, but
you can always specify the needed queue in `init`:

```swift
let promise = Promise<String>(queue: dispatch_get_main_queue())
```

### Done
Add a handler to be called when the ***promise*** object is resolved with a value:

```swift
// Create a new promise in a pending state
let promise = Promise<String>()

// Add done callback
promise.done({ value in
  print(value)
})

// Resolve the promise
promise.resolve("String")
```

### Fail
Add a handler to be called when the ***promise*** object is rejected with
an `ErrorType`:

```swift
// Create a new promise in a pending state
let promise = Promise<String>()

// Add done callback
promise.fail({ error in
  print(error)
})

// Reject the promise
promise.reject(Error.NotFound)
```

### Always
Add a handler to be called when the ***promise*** object is either resolved or
rejected. This callback will be called after [done](#done) or [fail](#fail)
handlers.

```swift
// Create a new promise in a pending state
let promise = Promise<String>()

// Add done callback
promise.always({ result in
  switch result {
  case let .Success(value):
    print(value)
  case let .Failure(error):
    print(error)
  }
})

// Resolve or reject the promise
promise.resolve("String") // promise.reject(Error.NotFound)
```

### Then
Returns a new ***promise*** that can use the result value of the current
promise. It means that you could easily create chains of ***promises*** to
simplify complex asynchronous operations into clear and simple to understand
logic.

A new ***promise*** is resolved with the value returned from the provided
closure:

```swift
let promise = Promise<NSData>()

promise
  .then({ data -> Int in
    return data.length
  }).then({ length -> Bool in
    return length > 5
  }).done({ value in
    print(value)
  })

promise.resolve("String".dataUsingEncoding(NSUTF8StringEncoding)!)
```

A new ***promise*** is resolved when the ***promise*** returned from the
provided closure resolves:
```swift
struct Networking {
  static func GET(url: NSURL) -> Promise<NSData> {
    let promise = Promise<NSData>()
    //...
    return promise
  }
}

Networking.GET(url1)
  .then({ data -> Promise<NSData> in
    //...
    return Networking.GET(url2)
  }).then({ data -> Int in
    return data.length
  }).done({ value in
    print(value)
  })
```

***then*** closure is executed on the main queue by default, but you can pass a
needed queue as a parameter:

```swift
promise.then(on: dispatch_get_global_queue(QOS_CLASS_UTILITY, 0))({ data -> Int in
  //...
})
```

If you want to use background queue there are the helper methods for this case:

```swift
promise1.thenInBackground({ data -> Int in
  //...
})

promise2.thenInBackground({ data -> Promise<NSData> in
  //...
})
```

### When
Provides a way to execute callback functions based on one or more
***promises***. The ***when*** method returns a new "master" ***promise*** that
tracks the aggregate state of all the passed ***promises***. The method will
resolve its "master" ***promise*** as soon as all the ***promises*** resolve,
or reject the "master" ***promise*** as soon as one of the ***promises*** is
rejected. If the "master" ***promise*** is resolved, the ***done*** callback is
executed with resolved values for each of the ***promises***:

```swift
let promise1 = Promise<Int>()
let promise2 = Promise<String>()
let promise3 = Promise<Int>()

when(promise1, promise2, promise3)
  .done({ value1, value2, value3 in
    print(value1)
    print(value2)
    print(value3)
  })

promise1.resolve(1)
promise2.resolve("String")
promise3.resolve(3)
```

## Installation

**When** is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'When'
```

**When** is also available through [Carthage](https://github.com/Carthage/Carthage).
To install just write into your Cartfile:

```ruby
github "vadymmarkov/When"
```

## Author

Vadym Markov, markov.vadym@gmail.com

## Credits

Credits for inspiration go to [PromiseKit](https://github.com/mxcl/PromiseKit)
and [Then](https://github.com/onmyway133/Then).

## Contributing

Check the [CONTRIBUTING](https://github.com/vadymmarkov/When/blob/master/CONTRIBUTING.md) file for more info.

## License

**When** is available under the MIT license. See the [LICENSE](https://github.com/vadymmarkov/When/blob/master/LICENSE.md) file for more info.
