import Swifter
import XCTest

@testable import PaylikeClient

final class PaylikeClient_Tokenize_Mock_Tests: XCTestCase {
    
    static var paylikeClient = PaylikeClient(clientID: "mocked")
    static var server = HttpServer()
    
    static let applePayToken = "applePayToken"
    static let cardNumber = "4100000000000000"
    static let cardSecurityCode = "111"
    static let tokenization = "tokenized+"
    
    public class override func setUp() {
        
        /*
         * Mock the internal HTTP client
         */
        paylikeClient.httpClient = MockHTTPClient()
        
        /*
         * Initializing client and HTTPclient without logging. We do not log in tests
         */
        paylikeClient.loggingFn = { _ in
            // do nothing
        }
        paylikeClient.httpClient.loggingFn = { _ in
            // do nothing
        }
        
        /*
         * Initializing mocking server
         */
        server[MockEndpoints.CARD_DATA_VAULT.rawValue] = { request in
            XCTAssertEqual(request.method, "POST")
            XCTAssertEqual(request.headers["accept-version"], "1")
            XCTAssertEqual(request.headers["x-client"], "swift-1-mocked")
            
            let bodyData = Data(request.body)
            do {
                let tokenizeRequest = try JSONDecoder().decode(TokenizeCardDataRequest.self, from: bodyData)
                let responseBody = TokenizeResponse(token: tokenization + tokenizeRequest.value)
                let responseEncoded = try JSONEncoder().encode(responseBody)
                return HttpResponse.ok(.data(responseEncoded, contentType: nil))
            } catch {
                print("Caught server error: \(error)")
                return .internalServerError
            }
        }
        server[MockEndpoints.APPLE_PAY_VAULT.rawValue] = { request in
            XCTAssertEqual(request.method, "POST")
            XCTAssertEqual(request.headers["accept-version"], "1")
            XCTAssertEqual(request.headers["x-client"], "swift-1-mocked")
            
            let bodyData = Data(request.body)
            do {
                let tokenizeRequest = try JSONDecoder().decode(TokenizeApplePayDataRequest.self, from: bodyData)
                let responseBody = TokenizeResponse(token: self.tokenization + tokenizeRequest.token)
                let responseEncoded = try JSONEncoder().encode(responseBody)
                return HttpResponse.ok(.data(responseEncoded, contentType: nil))
            } catch {
                print("Caught server error: \(error)")
                return .internalServerError
            }
        }
        do {
            try server.start(in_port_t(MockPort))
        } catch {
            XCTFail("Server start error: \(error)")
        }
    }
    
    public class override func tearDown() {
        PaylikeClient_Tokenize_Mock_Tests.server.stop()
    }
    
    
    func test_tokenize_withCardNumber_async() throws {
        let expectation = expectation(description: "Value should be received")
        Task {
            do {
                let tokenizeToken = TokenizeCardDataRequest(type: .PCN, value: PaylikeClient_Tokenize_Mock_Tests.cardNumber)
                let response = try await PaylikeClient_Tokenize_Mock_Tests.paylikeClient.tokenize(cardData: tokenizeToken)
                XCTAssertEqual(response.token, PaylikeClient_Tokenize_Mock_Tests.tokenization + tokenizeToken.value)
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
                let response = try await PaylikeClient_Tokenize_Mock_Tests.paylikeClient.tokenize(cardData: tokenizeToken)
                XCTAssertEqual(response.token, PaylikeClient_Tokenize_Mock_Tests.tokenization + tokenizeToken.value)
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
                let response = try await PaylikeClient_Tokenize_Mock_Tests.paylikeClient.tokenize(applePayData: tokenizeToken)
                XCTAssertEqual(response.token, PaylikeClient_Tokenize_Mock_Tests.tokenization + tokenizeToken.token)
                expectation.fulfill()
            } catch {
                XCTFail("Should not get error: \(error)")
            }
        }
        wait(for: [expectation], timeout: 10)
    }
    
    func test_tokenizeSync_withCardNumber() throws {
        let tokenizeToken = TokenizeCardDataRequest(type: .PCN, value: PaylikeClient_Tokenize_Mock_Tests.cardNumber)
        PaylikeClient_Tokenize_Mock_Tests.paylikeClient.tokenizeSync(
            cardData: tokenizeToken
        ) { result in
            do {
                let response = try result.get()
                XCTAssertEqual(response.token, PaylikeClient_Tokenize_Mock_Tests.tokenization + tokenizeToken.value)
            } catch {
                XCTFail("Should not get error: \(error)")
            }
        }
    }
    
    func test_tokenizeSync_withCardSecurityCode() throws {
        let tokenizeToken = TokenizeCardDataRequest(type: .PCSC, value: PaylikeClient_Tokenize_Mock_Tests.cardSecurityCode)
        PaylikeClient_Tokenize_Mock_Tests.paylikeClient.tokenizeSync(
            cardData: tokenizeToken
        ) { result in
            do {
                let response = try result.get()
                XCTAssertEqual(response.token, PaylikeClient_Tokenize_Mock_Tests.tokenization + tokenizeToken.value)
            } catch {
                XCTFail("Should not get error: \(error)")
            }
        }
    }
    
    func test_tokenizeSync_withApplePay() throws {
        let tokenizeToken = TokenizeApplePayDataRequest(token: PaylikeClient_Tokenize_Mock_Tests.applePayToken)
        PaylikeClient_Tokenize_Mock_Tests.paylikeClient.tokenizeSync(
            applePayData: tokenizeToken
        ) { result in
            do {
                let response = try result.get()
                XCTAssertEqual(response.token, PaylikeClient_Tokenize_Mock_Tests.tokenization + tokenizeToken.token)
            } catch {
                XCTFail("Should not get error: \(error)")
            }
        }
    }
    
}

extension TokenizeApplePayDataRequest : Decodable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: Keys.self)
        
        let token: String = try container.decode(String.self, forKey: .token)
        
        self.init(token: token)
    }
    private enum Keys : String, CodingKey {
        case token
    }
}

extension TokenizeCardDataRequest : Decodable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: Keys.self)
        
        let type: CardDataType = try container.decode(CardDataType.self, forKey: .type)
        let value: String = try container.decode(String.self, forKey: .value)

        self.init(type: type, value: value)
    }
    private enum Keys : String, CodingKey {
        case type
        case value
    }
}

extension CardDataType : Decodable {}
