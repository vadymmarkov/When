//
//import Foundation
//
//describe("clearExpired") {
//  it("removes expired objects") {
//    let expectation1 = self.expectationWithDescription(
//      "Clear If Expired Expectation")
//    let expectation2 = self.expectationWithDescription(
//      "Don't Clear If Not Expired Expectation")
//
//    let expiry1: Expiry = .Date(NSDate().dateByAddingTimeInterval(-100000))
//    let expiry2: Expiry = .Date(NSDate().dateByAddingTimeInterval(100000))
//
//    let key1 = "item1"
//    let key2 = "item2"
//
//    storage.add(key1, object: object, expiry: expiry1)
//    storage.add(key2, object: object, expiry: expiry2)
//
//    storage.clearExpired {
//      storage.object(key1) { (receivedObject: User?) in
//        expect(receivedObject).to(beNil())
//        expectation1.fulfill()
//      }
//
//      storage.object(key2) { (receivedObject: User?) in
//        expect(receivedObject).toNot(beNil())
//        expectation2.fulfill()
//      }
//    }
//
//    self.waitForExpectationsWithTimeout(5.0, handler:nil)
//  }
//}
