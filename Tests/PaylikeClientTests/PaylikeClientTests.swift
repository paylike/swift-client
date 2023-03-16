import XCTest

@testable import PaylikeClient

final class PaylikeClientTests: XCTestCase {
    
    var client = PaylikeClient()
    
    func test_PaylikeClient_IDGeneration() throws {
        XCTAssertNotNil(PaylikeClient.generateClientID())
        XCTAssertEqual(PaylikeClient.generateClientID().count, "swift-1-123456".count)
    }
}
