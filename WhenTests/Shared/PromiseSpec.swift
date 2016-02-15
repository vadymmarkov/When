import Quick
import Nimble
@testable import When

class PromiseSpec: QuickSpec {

  override func spec() {
    describe("Promise") {
      var promise: Promise<String>!

      describe("#init:state:queue") {
        context("with default values") {
          beforeEach {
            promise = Promise()
          }

          it("sets values") {
            expect(promise.state.isPending).to(beTrue())
            expect(promise.state.result).to(beNil())
          }
        }

        context("with custom values") {
          let state = State.Resolved(value: "Yay!")
          let queue = dispatch_get_main_queue()

          beforeEach {
            promise = Promise(state: state, queue: queue)
          }

          it("sets values") {
            expect(promise.state).to(equal(state))
            expect(promise.state.result?.value).to(equal(state.result?.value))
            expect(promise.queue === queue).to(beTrue())
          }
        }
      }

      describe("#init:body:queue") {
        context("with a body throws an error") {
          beforeEach {
            promise = Promise({
              throw SpecError.NotFound
            })
          }

          it("rejects the promise") {
            expect(promise.state.isRejected).to(beTrue())
            expect(promise.state.result?.value).to(beNil())
            expect(promise.state.result?.error is SpecError).to(beTrue())
          }
        }

        context("with a body that returns a value") {
          let string = "Success!"

          beforeEach {
            promise = Promise({
              return string
            })
          }

          it("resolves the promise") {
            expect(promise.state.isResolved).to(beTrue())
            expect(promise.state.result?.value).to(equal(string))
            expect(promise.state.result?.error).to(beNil())
          }
        }
      }

      describe("#reject") {
        beforeEach {
          promise = Promise<String>()
        }

        it("rejects the promise") {
          promise.reject(SpecError.NotFound)

          expect(promise.state.isRejected).to(beTrue())
          expect(promise.state.result?.value).to(beNil())
          expect(promise.state.result?.error is SpecError).to(beTrue())
        }

        it("calls callbacks") {
          let failExpectation = self.expectationWithDescription("Fail expectation")
          let alwaysExpectation = self.expectationWithDescription("Always expectation")

          promise
            .fail({ error in
              expect(error is SpecError).to(beTrue())
              failExpectation.fulfill()
            })
            .always({ result in
              switch result {
              case let .Failure(error):
                expect(error is SpecError).to(beTrue())
                alwaysExpectation.fulfill()
              default:
                break
              }
            })

          promise.reject(SpecError.NotFound)
          self.waitForExpectationsWithTimeout(2.0, handler:nil)
        }
      }

      describe("#resolve") {
        let string = "Success!"

        beforeEach {
          promise = Promise<String>()
        }

        it("resolves the promise") {
          promise.resolve(string)

          expect(promise.state.isResolved).to(beTrue())
          expect(promise.state.result?.value).to(equal(string))
          expect(promise.state.result?.error).to(beNil())
        }

        it("calls callbacks") {
          let doneExpectation = self.expectationWithDescription("Done expectation")
          let alwaysExpectation = self.expectationWithDescription("Always expectation")

          promise
            .done({ object in
              expect(object).to(equal(string))
              doneExpectation.fulfill()
            })
            .always({ result in
              switch result {
              case let .Success(value):
                expect(value).to(equal(string))
                alwaysExpectation.fulfill()
              default:
                break
              }
            })

          promise.resolve(string)
          self.waitForExpectationsWithTimeout(2.0, handler:nil)
        }
      }

    }
  }
}
