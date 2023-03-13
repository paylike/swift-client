import XCTest

@testable import PaylikeClient

final class PaylikeClient_Tokenize_Live_Tests: XCTestCase {
    
    private static var paylikeClient = PaylikeClient()
    
    private static let cardNumber = "4100000000000000"
    private static let cardSecurityCode = "111"
    
    public class override func setUp() {
        /**
         * Initializing client and HTTPclient without logging. We do not log in tests
         */
        paylikeClient.loggingFn = { _ in }
        paylikeClient.httpClient.loggingFn = { _ in }
    }

    func test_tokenize_withCardNumber() throws {
        if E2E_DISABLED {
            return
        }
        let expectation = expectation(description: "Value should be received")
        Self.paylikeClient.tokenize(
            cardData: TokenizeCardDataRequest(type: .PCN, value: Self.cardNumber)
        ) { result in
            do {
                let response = try result.get()
                XCTAssertNotNil(response)
                expectation.fulfill()
            } catch {
                XCTFail("Unexpected error: \(error)")
            }
        }
        wait(for: [expectation], timeout: 20)
    }
    
    func test_tokenize_withCardSecurityCode() throws {
        if E2E_DISABLED {
            return
        }
        let expectation = expectation(description: "Value should be received")
        Self.paylikeClient.tokenize(
            cardData: TokenizeCardDataRequest(type: .PCSC, value: Self.cardSecurityCode)
        ) { result in
            do {
                let response = try result.get()
                XCTAssertNotNil(response)
                expectation.fulfill()
            } catch {
                XCTFail("Unexpected error: \(error)")
            }
        }
        wait(for: [expectation], timeout: 20)
    }
    
    func test_tokenize_withCardNumber_async() throws {
        if E2E_DISABLED {
            return
        }
        let expectation = expectation(description: "Value should be received")
        Task {
            do {
                let response = try await Self.paylikeClient.tokenize(cardData: TokenizeCardDataRequest(type: .PCN, value: Self.cardNumber))
                XCTAssertNotNil(response)
                expectation.fulfill()
            } catch {
                print(error)
                XCTFail("Unexpected error: \(error)")
            }
        }
        wait(for: [expectation], timeout: 20)
    }

    func test_tokenize_withCardSecurityCode_async() throws {
        if E2E_DISABLED {
            return
        }
        let expectation = expectation(description: "Value should be received")
        Task {
            do {
                let response = try await Self.paylikeClient.tokenize(cardData: TokenizeCardDataRequest(type: .PCSC, value: Self.cardSecurityCode))
                XCTAssertNotNil(response)
                expectation.fulfill()
            } catch {
                print(error)
                XCTFail("Unexpected error: \(error)")
            }
        }
        wait(for: [expectation], timeout: 20)
    }
    
    func test_tokenizeSync_withCardNumber() throws {
        if E2E_DISABLED {
            return
        }
        Self.paylikeClient.tokenizeSync(
            cardData: TokenizeCardDataRequest(type: .PCN, value: Self.cardNumber)
        ) { result in
            do {
                let response = try result.get()
                XCTAssertNotNil(response)
            } catch {
                XCTFail("Unexpected error: \(error)")
            }
        }
    }
    
    func test_tokenizeSync_withCardSecurityCode() throws {
        if E2E_DISABLED {
            return
        }
        Self.paylikeClient.tokenizeSync(
            cardData: TokenizeCardDataRequest(type: .PCSC, value: Self.cardSecurityCode)
        ) { result in
            do {
                let response = try result.get()
                XCTAssertNotNil(response)
            } catch {
                XCTFail("Unexpected error: \(error)")
            }
        }
    }
}
