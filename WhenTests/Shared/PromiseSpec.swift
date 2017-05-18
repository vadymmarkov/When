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

          it("has default optional fields") {
            expect(promise.observer).to(beNil())
            expect(promise.doneHandler).to(beNil())
            expect(promise.failureHandler).to(beNil())
            expect(promise.completionHandler).to(beNil())
          }

          it("sets values") {
            expect(promise.state.isPending).to(beTrue())
            expect(promise.state.result).to(beNil())
          }
        }

        context("with custom values") {
          let state = State.resolved(value: "Yay!")
          let queue = DispatchQueue.main

          beforeEach {
            promise = Promise(queue: queue, state: state)
          }

          it("has default optional fields") {
            expect(promise.observer).to(beNil())
            expect(promise.doneHandler).to(beNil())
            expect(promise.failureHandler).to(beNil())
            expect(promise.completionHandler).to(beNil())
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
              throw SpecError.notFound
            })
          }

          it("rejects the promise") {
            let failExpectation = self.expectation(description: "Fail expectation")

            promise
              .fail({ object in
                expect(promise.state.isRejected).to(beTrue())
                expect(promise.state.result?.value).to(beNil())
                expect(promise.state.result?.error is SpecError).to(beTrue())

                failExpectation.fulfill()
              })

            self.waitForExpectations(timeout: 2.0, handler:nil)
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
            let doneExpectation = self.expectation(description: "Done expectation")

            promise
              .done({ object in
                expect(promise.state.isResolved).to(beTrue())
                expect(promise.state.result?.value).to(equal(string))
                expect(promise.state.result?.error).to(beNil())

                doneExpectation.fulfill()
              })

            self.waitForExpectations(timeout: 2.0, handler:nil)
          }
        }

        context("with an async body that returns a value") {
          let string = "Success!"

          func loadString(withCompletionHandler handler: @escaping (String) -> Void) {
            DispatchQueue(label: "async closure").async {
              handler(string)
            }
          }

          beforeEach {
            promise = Promise(loadString)
          }

          it("resolves the promise") {
            let doneExpectation = self.expectation(description: "Done expectation")

            promise.done { value in
              expect(value).to(equal(string))
              expect(promise.state.isResolved).to(beTrue())
              expect(promise.state.result?.value).to(equal(string))
              expect(promise.state.result?.error).to(beNil())

              doneExpectation.fulfill()
            }

            self.waitForExpectations(timeout: 2.0, handler: nil)
          }
        }
      }

      describe("#reject") {
        beforeEach {
          promise = Promise<String>()
          promise.reject(SpecError.notFound)
        }

        it("calls callbacks") {
          let failExpectation = self.expectation(description: "Fail expectation")
          let alwaysExpectation = self.expectation(description: "Always expectation")

          promise
            .fail({ error in
              expect(error is SpecError).to(beTrue())
              expect(promise.state.isRejected).to(beTrue())
              expect(promise.state.result?.value).to(beNil())
              expect(promise.state.result?.error is SpecError).to(beTrue())

              failExpectation.fulfill()
            })
            .always({ result in
              switch result {
              case let .failure(error):
                expect(error is SpecError).to(beTrue())
                alwaysExpectation.fulfill()
              default:
                break
              }
            })

          promise.reject(SpecError.notFound)
          self.waitForExpectations(timeout: 2.0, handler:nil)
        }
      }

      describe("#resolve") {
        let string = "Success!"

        beforeEach {
          promise = Promise<String>()
          promise.resolve(string)
        }

        it("calls callbacks") {
          let doneExpectation = self.expectation(description: "Done expectation")
          let alwaysExpectation = self.expectation(description: "Always expectation")

          promise
            .done({ object in
              expect(object).to(equal(string))
              expect(promise.state.isResolved).to(beTrue())
              expect(promise.state.result?.value).to(equal(string))
              expect(promise.state.result?.error).to(beNil())

              doneExpectation.fulfill()
            })
            .always({ result in
              switch result {
              case let .success(value):
                expect(value).to(equal(string))
                alwaysExpectation.fulfill()
              default:
                break
              }
            })

          promise.resolve(string)
          self.waitForExpectations(timeout: 2.0, handler:nil)
        }
      }

      describe("#done") {
        beforeEach {
          promise = Promise<String>()
            .done({ object in })
        }

        it("sets a callback") {
          expect(promise.doneHandler).toNot(beNil())
        }
      }

      describe("#fail") {
        beforeEach {
          promise = Promise<String>()
            .fail({ error in })
        }

        it("sets a callback") {
          expect(promise.failureHandler).toNot(beNil())
        }
      }

      describe("#always") {
        beforeEach {
          promise = Promise<String>()
            .always({ result in })
        }

        it("sets a callback") {
          expect(promise.completionHandler).toNot(beNil())
        }
      }

      describe("#then") {
        let string = "Success!"

        beforeEach {
          promise = Promise<String>()
        }

        context("with a body that transforms result") {
          context("with a body throws an error") {
            it("rejects the promise") {
              let failExpectation = self.expectation(description: "Then fail expectation")

              promise
                .then({ value in
                  throw SpecError.notFound
                })
                .fail({ error in
                  expect(error is SpecError).to(beTrue())
                  failExpectation.fulfill()
                })

              promise.resolve(string)
              self.waitForExpectations(timeout: 2.0, handler:nil)
            }
          }

          context("with a body that returns a value") {
            it("resolves the promise") {
              let doneExpectation = self.expectation(description: "Then done expectation")

              promise
                .then({ value in
                  return value + "?"
                })
                .done({ value in
                  expect(value).to(equal(string + "?"))
                  doneExpectation.fulfill()
                })

              promise.resolve(string)
              self.waitForExpectations(timeout: 2.0, handler:nil)
            }
          }
        }

        context("with a body that returns a new promise") {
          context("with a rejected promise") {
            it("rejects the promise") {
              let failExpectation = self.expectation(description: "Then fail expectation")

              promise
                .then({ value in
                  return Promise({
                    throw SpecError.notFound
                  })
                })
                .fail({ error in
                  expect(error is SpecError).to(beTrue())
                  failExpectation.fulfill()
                })

              promise.resolve(string)
              self.waitForExpectations(timeout: 2.0, handler:nil)
            }
          }

          context("with a body that returns a value") {
            it("with a resolved promise") {
              let doneExpectation = self.expectation(description: "Then done expectation")

              promise
                .then({ value in
                  return Promise({
                    return value + "?"
                  })
                })
                .done({ value in
                  expect(value).to(equal(string + "?"))
                  doneExpectation.fulfill()
                })

              promise.resolve(string)
              self.waitForExpectations(timeout: 2.0, handler:nil)
            }
          }
        }
      }
    }
  }
}
