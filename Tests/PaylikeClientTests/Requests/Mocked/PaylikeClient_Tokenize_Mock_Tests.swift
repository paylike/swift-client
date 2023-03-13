import XCTest

@testable import PaylikeClient

final class PaylikeClient_Tokenize_Mock_Tests: XCTestCase {
    
    private static var mockedPaylikeClient = PaylikeClient(clientID: "mocked")
    private static var mockPaylikeServer = MockHTTPServer()
    
    private static let applePayToken = "applePayToken"
    private static let cardNumber = "4100000000000000"
    private static let cardSecurityCode = "111"
    
    public class override func setUp() {
        
        /*
         * Initializing client and HTTPclient without logging. We do not log in tests
         */
        mockedPaylikeClient.loggingFn = { _ in }
        mockedPaylikeClient.httpClient.loggingFn = { _ in }
        
        /*
         * Mock the internal HTTP client
         */
        mockedPaylikeClient.httpClient = MockHTTPClient(MockPort)
        
        /*
         * Mock server start
         */
        do {
            try mockPaylikeServer.start(MockPort)
        } catch {
            XCTFail("Server start error: \(error)")
        }
    }
    
    public class override func tearDown() {
        mockPaylikeServer.stop()
    }
    
    func test_tokenize_withCardNumber_async() throws {
        let expectation = expectation(description: "Value should be received")
        Task {
            do {
                let tokenizeToken = TokenizeCardDataRequest(type: .PCN, value: Self.cardNumber)
                let response = try await Self.mockedPaylikeClient.tokenize(cardData: tokenizeToken)
                XCTAssertEqual(response.token, Self.mockPaylikeServer.tokenization + tokenizeToken.value)
                expectation.fulfill()
            } catch {
                XCTFail("Should not get error: \(error)")
            }
        }
        wait(for: [expectation], timeout: 10)
    }
    
    func test_tokenize_withCardSecurityCode_async() throws {
        let expectation = expectation(description: "Value should be received")
        Task {
            do {
                let tokenizeToken = TokenizeCardDataRequest(type: .PCSC, value: PaylikeClient_Tokenize_Mock_Tests.cardSecurityCode)
                let response = try await Self.mockedPaylikeClient.tokenize(cardData: tokenizeToken)
                XCTAssertEqual(response.token, Self.mockPaylikeServer.tokenization + tokenizeToken.value)
                expectation.fulfill()
            } catch {
                XCTFail("Should not get error: \(error)")
            }
        }
        wait(for: [expectation], timeout: 10)
    }
    
    func test_tokenize_withApplePay_async() throws {
        let expectation = expectation(description: "Value should be received")
        Task {
            do {
                let tokenizeToken = TokenizeApplePayDataRequest(token: PaylikeClient_Tokenize_Mock_Tests.applePayToken)
                let response = try await Self.mockedPaylikeClient.tokenize(applePayData: tokenizeToken)
                XCTAssertEqual(response.token, Self.mockPaylikeServer.tokenization + tokenizeToken.token)
                expectation.fulfill()
            } catch {
                XCTFail("Should not get error: \(error)")
            }
        }
        wait(for: [expectation], timeout: 10)
    }
    
    func test_tokenizeSync_withCardNumber() throws {
        let tokenizeToken = TokenizeCardDataRequest(type: .PCN, value: PaylikeClient_Tokenize_Mock_Tests.cardNumber)
        Self.mockedPaylikeClient.tokenizeSync(
            cardData: tokenizeToken
        ) { result in
            do {
                let response = try result.get()
                XCTAssertEqual(response.token, Self.mockPaylikeServer.tokenization + tokenizeToken.value)
            } catch {
                XCTFail("Should not get error: \(error)")
            }
        }
    }
    
    func test_tokenizeSync_withCardSecurityCode() throws {
        let tokenizeToken = TokenizeCardDataRequest(type: .PCSC, value: PaylikeClient_Tokenize_Mock_Tests.cardSecurityCode)
        Self.mockedPaylikeClient.tokenizeSync(
            cardData: tokenizeToken
        ) { result in
            do {
                let response = try result.get()
                XCTAssertEqual(response.token, Self.mockPaylikeServer.tokenization + tokenizeToken.value)
            } catch {
                XCTFail("Should not get error: \(error)")
            }
        }
    }
    
    func test_tokenizeSync_withApplePay() throws {
        let tokenizeToken = TokenizeApplePayDataRequest(token: PaylikeClient_Tokenize_Mock_Tests.applePayToken)
        Self.mockedPaylikeClient.tokenizeSync(
            applePayData: tokenizeToken
        ) { result in
            do {
                let response = try result.get()
                XCTAssertEqual(response.token, Self.mockPaylikeServer.tokenization + tokenizeToken.token)
            } catch {
                XCTFail("Should not get error: \(error)")
            }
        }
    }
    
}

