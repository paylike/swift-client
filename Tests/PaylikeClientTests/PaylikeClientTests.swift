import XCTest

@testable import PaylikeClient

final class PaylikeClientTests: XCTestCase {
    
    var client = PaylikeClient()
    
    convenience override init() {
        self.init()
        
        /**
         * Initializing HTTP client without logging. We do not log in tests
         */
        client.loggingFn = { _ in
            // do nothing
        }
    }
    
    func testClientIDGeneration() throws {
        XCTAssertNotNil(PaylikeClient.generateClientID())
        XCTAssertEqual(PaylikeClient.generateClientID().count, "swift-1-123456".count)
    }
}
