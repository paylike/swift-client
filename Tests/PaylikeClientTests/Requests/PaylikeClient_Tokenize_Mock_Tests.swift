import Swifter
import XCTest

@testable import PaylikeClient



final class PaylikeClient_Tokenize_Mock_Tests: XCTestCase {
    
    static var paylikeClient = PaylikeClient(clientId: "mocked")
    var server = HttpServer()
    
    let applePayToken = "applePayToken"
    let tokenization = "tokenized+"
    
    public class override func setUp() {
        /**
         * Initializing client and HTTPclient without logging. We do not log in tests
         */
        paylikeClient.loggingFn = { _ in
            // do nothing
        }
        paylikeClient.httpClient.loggingFn = { _ in
            // do nothing
        }
    }
    
    func testAsyncApplePayTokenization() throws {
        let server = HttpServer()
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
        try server.start(in_port_t(MockPort))
        
        let expectation = expectation(description: "Value should be received")

        Task {
            do {
                let tokenizeToken = TokenizeApplePayDataRequest(token: applePayToken)
                let response = try await PaylikeClient_Tokenize_Mock_Tests.paylikeClient.tokenize(applePayData: tokenizeToken)
            
                XCTAssertEqual(response.token, tokenization + tokenizeToken.token)
                
                expectation.fulfill()
            } catch {
                XCTFail("\(error)")
            }
            server.stop()
        }
        wait(for: [expectation], timeout: 10)
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
