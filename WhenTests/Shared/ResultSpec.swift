import Quick
import Nimble
@testable import When

class ResultSpec: QuickSpec {

  override func spec() {
    describe("Result") {
      var result: Result<String>!
      let string = "Yay!"

      context("when it's success") {
        beforeEach {
          result = .Success(value: string)
        }

        describe("#value") {
          it("has a value") {
            expect(result.value).to(equal(string))
          }
        }

        describe("#error") {
          it("is nil") {
            expect(result.error).to(beNil())
          }
        }

        describe("#map") {
          it("transforms to the same result with a new type") {
            let nextResult: Result<Int> = result.map { value in
              return 11
            }

            expect(nextResult.value).to(equal(11))
            expect(nextResult.error).to(beNil())
          }
        }
      }

      context("when it's failure") {
        beforeEach {
          result = .Failure(error: SpecError.NotFound)
        }

        describe("#value") {
          it("has no value") {
            expect(result.value).to(beNil())
          }
        }

        describe("#error") {
          it("is not nil") {
            expect(result.error is SpecError).to(beTrue())
          }
        }

        describe("#map") {
          it("transforms to the same result with a new type") {
            let nextResult: Result<Int> = result.map { value in
              return 11
            }

            expect(nextResult.value).to(beNil())
            expect(nextResult.error is SpecError).to(beTrue())
          }
        }
      }
    }
  }
}
