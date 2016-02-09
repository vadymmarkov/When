// When iOS Playground

import UIKit
import When

var str = "Hello, playground"




Promise({ (resolve: (instance: String) -> Void, revoke: (error: ErrorType) -> Void) in
  sleep(2)
  resolve(instance: "hello")
}).then({ object in
  NSError(domain: "Promise", code: 1234, userInfo: [NSLocalizedDescriptionKey:"Promise broken :("])
}).then({ object -> Void in
  print("ff")
}).catchError({ (error) -> Void in
  print("Error: \(error)")
})
