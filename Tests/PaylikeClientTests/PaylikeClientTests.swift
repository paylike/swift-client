import XCTest
@testable import PaylikeClient
import Combine



final class PaylikeClientTests: XCTestCase {
    func testClientIDGeneration() throws {
        XCTAssertNotNil(PaylikeClient.generateClientID())
        XCTAssertEqual(PaylikeClient.generateClientID().count, "swift-1-123456".count)
    }
    
    func testTokenization() throws {
        let client = PaylikeClient()
        let promise = client.tokenize(type: PaylikeTokenizedTypes.PCN, value: "4100000000000000")
        let expectation = expectation(description: "Value should be received")
        var bag: Set<AnyCancellable> = []
        promise.sink(receiveCompletion: { completion in
            switch completion {
            case .failure(let error):
                print(error)
                XCTFail("Unexpected error")
            default:
                return
            }
        }, receiveValue: { tokenized in
            XCTAssertNotNil(tokenized)
            expectation.fulfill()
        }).store(in: &bag)
        wait(for: [expectation], timeout: 50)
    }
}
