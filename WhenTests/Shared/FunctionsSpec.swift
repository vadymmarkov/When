import Quick
import Nimble
import Dispatch
@testable import When

class FunctionsSpec: QuickSpec {
  override func spec() {
    describe("Functions") {
      describe("#then") {
        let string = "Success!"
        var promise1: Promise<Int>!
        var promise2: Promise<String>!
        var promise3: Promise<Int>!

        beforeEach {
          promise1 = Promise<Int>()
          promise2 = Promise<String>()
          promise3 = Promise<Int>()
        }

        context("with a body throws an error") {
          it("rejects the promise") {
            let failExpectation = self.expectation(description: "Fail expectation")

            when(promise1, promise2, promise3)
              .fail({ error in
                expect(error is SpecError).to(beTrue())
                failExpectation.fulfill()
              })

            promise1.resolve(1)
            promise2.reject(SpecError.notFound)
            promise3.resolve(1)

            self.waitForExpectations(timeout: 2.0, handler:nil)
          }
        }

        context("with a body that returns a value") {
          it("resolves the promise") {
            let doneExpectation = self.expectation(description: "Done expectation")

            when(promise1, promise2, promise3)
              .done({ value1, value2, value3 in
                expect(value1).to(equal(1))
                expect(value2).to(equal(string))
                expect(value3).to(equal(3))
                doneExpectation.fulfill()
              })

            promise1.resolve(1)
            promise2.resolve(string)
            promise3.resolve(3)

            self.waitForExpectations(timeout: 2.0, handler:nil)
          }
        }

        context("with many concurrent tasks") {
          it("resolves the promise") {
            let promises: [Promise<Int>] = (0..<10000).map { _ in
              return Promise<Int>(queue: DispatchQueue.global())
            }

            let doneExpectation = self.expectation(description: "Done expectation")

            when(promises)
              .done({ result in
                doneExpectation.fulfill()
              })

            promises.forEach {
                $0.resolve(1)
            }

            self.waitForExpectations(timeout: 5.0, handler:nil)
          }
        }
      }
    }
  }
}
