import XCTest
@testable import PaylikeClient

final class PaylikeClientTests: XCTestCase {
    func testExample() throws {
        let client = PaylikeClient()
        print(PaylikeClient.generateClientID())
    }
}
