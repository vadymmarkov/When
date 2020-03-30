import Quick
import Nimble
@testable import When

class StateSpec: QuickSpec {
  override func spec() {
    describe("State") {
      var state: State<String>!

      context("when it's pending") {
        beforeEach {
          state = .pending
        }

        describe("#isPending") {
          it("is true") {
            expect(state.isPending).to(beTrue())
          }
        }

        describe("#isResolved") {
          it("is false") {
            expect(state.isResolved).to(beFalse())
          }
        }

        describe("#isRejected") {
          it("is false") {
            expect(state.isRejected).to(beFalse())
          }
        }

        describe("#map") {
          it("transforms to the same state with a new type") {
            let nextState: State<Int> = state.map { value in
              return 11
            }

            expect(nextState.isPending).to(beTrue())
            expect(state.isResolved).to(beFalse())
            expect(state.isRejected).to(beFalse())
            expect(nextState.result).to(beNil())
          }
        }
      }

      context("when it's resolved") {
        beforeEach {
          state = .resolved(value: "Yay!")
        }

        describe("#isPending") {
          it("is false") {
            expect(state.isPending).to(beFalse())
          }
        }

        describe("#isResolved") {
          it("is true") {
            expect(state.isResolved).to(beTrue())
          }
        }

        describe("#isRejected") {
          it("is false") {
            expect(state.isRejected).to(beFalse())
          }
        }

        describe("#map") {
          it("transforms to the same state with a new type") {
            let nextState: State<Int> = state.map { value in
              return 11
            }

            expect(nextState.isPending).to(beFalse())
            expect(nextState.isResolved).to(beTrue())
            expect(nextState.isRejected).to(beFalse())
            expect(try! nextState.result?.get()).to(equal(11))
          }
        }
      }

      context("when it's rejected") {
        beforeEach {
          state = .rejected(error: SpecError.notFound)
        }

        describe("#isPending") {
          it("is false") {
            expect(state.isPending).to(beFalse())
          }
        }

        describe("#isResolved") {
          it("is false") {
            expect(state.isResolved).to(beFalse())
          }
        }

        describe("#isRejected") {
          it("is true") {
            expect(state.isRejected).to(beTrue())
          }
        }

        describe("#map") {
          it("transforms to the same state with a new type") {
            let nextState: State<Int> = state.map { value in
              return 11
            }
            
            guard case .failure(let error) = nextState.result else {
                fail()
                return
            }

            expect(nextState.isPending).to(beFalse())
            expect(nextState.isResolved).to(beFalse())
            expect(nextState.isRejected).to(beTrue())
            expect(error is SpecError).to(beTrue())
          }
        }
      }
    }
  }
}
