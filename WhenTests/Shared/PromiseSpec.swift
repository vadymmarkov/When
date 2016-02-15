import Quick
import Nimble
@testable import When

class PromiseSpec: QuickSpec {

  override func spec() {
    describe("Promise") {
      var promise: Promise<String>!

      describe("init") {
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
          }
        }
      }
    }
  }
}
