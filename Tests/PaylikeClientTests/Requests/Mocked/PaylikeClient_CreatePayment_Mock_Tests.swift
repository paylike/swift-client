import Swifter
import XCTest

@testable import PaylikeClient

final class PaylikeClient_CreatePayment_Mock_Tests: XCTestCase {
    
    static var paylikeClient = PaylikeClient(clientID: "mocked")
    static var server = HttpServer()

    static let applePayToken = "applePayToken"
    static let cardNumber = "4100000000000000"
    static let cardSecurityCode = "111"
    static let tokenization = "tokenized+"

    public class override func setUp() {
        return // @TODO: Implement test
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
        server[MockEndpoints.CREATE_PAYMENT_API.rawValue] = { request in
            XCTAssertEqual(request.method, "POST")
            XCTAssertEqual(request.headers["accept-version"], "1")
            XCTAssertEqual(request.headers["x-client"], "swift-1-mocked")
            let bodyData = Data(request.body)
            do {
                
                // @TODO: mock the API
                return HttpResponse.ok(.json([:]))
            } catch {
                print("Caught server error: \(error)")
                return .internalServerError
            }
        }
        do {
            try server.start(in_port_t(MockPort))
        } catch {
            XCTFail("Server start error")
        }
    }
    
    public class override func tearDown() {
        return // @TODO: Implement test
        PaylikeClient_Tokenize_Mock_Tests.server.stop()
    }
    
    func test_createPayment_withCardData() throws {
        return // @TODO: Implement test
        
        let expectation = expectation(description: "Should be able to get HTML")
        Task {
            let integrationKey = PaymentIntegration(merchantId: key)
            let paymentAmount = PaymentAmount(currency: .EUR, value: 1, exponent: 0)
            let card = try await getTestPaymentCard()
            
            var createPaymentRequest = CreatePaymentRequest(with: card, merchantID: integrationKey)
            createPaymentRequest.amount = paymentAmount
            createPaymentRequest.test = PaymentTest()
            
            do {
                let clientResponse = try await PaylikeClient_CreatePayment_Live_Tests.paylikeClient.createPayment(with: &createPaymentRequest)
                XCTAssertNotNil(clientResponse.createPaymentResponse)
                XCTAssertNotNil(clientResponse.HTMLBody)
                XCTAssertNotNil(clientResponse.createPaymentResponse.hints)
                XCTAssertEqual(clientResponse.createPaymentResponse.hints!.count, 3)
            } catch {
                XCTFail("Should not get error " + error.localizedDescription)
            }
            expectation.fulfill()
            
        }
        wait(for: [expectation], timeout: 2000000)
    }
    
    func test_createPayment_withApplePay() throws {} // @TODO: Implement test
    
    fileprivate func getTestPaymentCard() async throws -> PaymentCard {
        async let numberToken = try PaylikeClient_CreatePayment_Live_Tests.paylikeClient.tokenize(cardData: TokenizeCardDataRequest(type: .PCN, value: Self.cardNumber))
        async let cvcToken = try PaylikeClient_CreatePayment_Live_Tests.paylikeClient.tokenize(cardData: TokenizeCardDataRequest(type: .PCSC, value: Self.cardSecurityCode))
        let expiry = try CardExpiry(month: 12, year: 26)
        return try PaymentCard(number: await numberToken, code: await cvcToken, expiry: expiry)
    }
}
