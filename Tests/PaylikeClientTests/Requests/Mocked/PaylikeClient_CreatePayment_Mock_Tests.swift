import XCTest

@testable import PaylikeClient

final class PaylikeClient_CreatePayment_Mock_Tests: XCTestCase {
    
    private static var mockedPaylikeClient = PaylikeClient(clientID: "mocked")
    private static var mockPaylikeServer = MockHTTPServer()

    private static let applePayToken = "applePayToken"
    private static let cardNumber = "4100000000000000"
    private static let cardSecurityCode = "111"

    public class override func setUp() {
        
        /*
         * Mock the internal HTTP client
         */
        mockedPaylikeClient.httpClient = MockHTTPClient(MockPort + 1)
        
        /*
         * Initializing client and HTTPclient without logging. We do not log in tests
         */
        mockedPaylikeClient.loggingFn = { _ in }
        mockedPaylikeClient.httpClient.loggingFn = { _ in }
        
        /*
         * Mock server start
         */
        do {
            try mockPaylikeServer.start(MockPort + 1)
        } catch {
            XCTFail("Server start error: \(error)")
        }
    }
    
    public class override func tearDown() {
        mockPaylikeServer.stop()
    }
    
    func test_createPayment_withCardData() throws {
        let expectation = expectation(description: "Should be able to get HTML")
        let integrationKey = PaymentIntegration(merchantId: key)
        let paymentAmount = PaymentAmount(currency: .EUR, value: 1, exponent: 0)
        getTestPaymentCard() { result in
            do {
                let card = try result.get()
                var createPaymentRequest = CreatePaymentRequest(with: card, merchantID: integrationKey)
                createPaymentRequest.amount = paymentAmount
                createPaymentRequest.test = PaymentTest()
                Self.mockedPaylikeClient.createPayment(with: createPaymentRequest) { result in
                    do {
                        let clientResponse = try result.get()
                        XCTAssertNotNil(clientResponse.createPaymentResponse)
                        XCTAssertEqual(clientResponse.HTMLBody, Self.mockPaylikeServer.htmlBodyString)
                        XCTAssertNotNil(clientResponse.createPaymentResponse.hints)
                        XCTAssertEqual(clientResponse.createPaymentResponse.hints!.count, 3)
                        XCTAssertEqual(clientResponse.createPaymentResponse.hints![0], Self.mockPaylikeServer.serverHints[0])
                        XCTAssertEqual(clientResponse.createPaymentResponse.hints![1], Self.mockPaylikeServer.serverHints[1])
                        XCTAssertEqual(clientResponse.createPaymentResponse.hints![2], Self.mockPaylikeServer.serverHints[2])
                    } catch {
                        XCTFail("Should not get error: \(error)")
                    }
                    expectation.fulfill()
                }
            } catch {
                XCTFail("Should not get error: \(error)")
            }
        }
        wait(for: [expectation], timeout: 10)
    }
    
    func test_createPayment_async_withCardData() throws {
        let expectation = expectation(description: "Should be able to get HTML")
        Task {
            let integrationKey = PaymentIntegration(merchantId: key)
            let paymentAmount = PaymentAmount(currency: .EUR, value: 1, exponent: 0)
            let card = try await getTestPaymentCard()
            
            var createPaymentRequest = CreatePaymentRequest(with: card, merchantID: integrationKey)
            createPaymentRequest.amount = paymentAmount
            createPaymentRequest.test = PaymentTest()
            
            do {
                let clientResponse = try await Self.mockedPaylikeClient.createPayment(with: createPaymentRequest)
                XCTAssertNotNil(clientResponse.createPaymentResponse)
                XCTAssertEqual(clientResponse.HTMLBody, Self.mockPaylikeServer.htmlBodyString)
                XCTAssertNotNil(clientResponse.createPaymentResponse.hints)
                XCTAssertEqual(clientResponse.createPaymentResponse.hints!.count, 3)
                XCTAssertEqual(clientResponse.createPaymentResponse.hints![0], Self.mockPaylikeServer.serverHints[0])
                XCTAssertEqual(clientResponse.createPaymentResponse.hints![1], Self.mockPaylikeServer.serverHints[1])
                XCTAssertEqual(clientResponse.createPaymentResponse.hints![2], Self.mockPaylikeServer.serverHints[2])
            } catch {
                XCTFail("Should not get error " + error.localizedDescription)
            }
            expectation.fulfill()
            
        }
        wait(for: [expectation], timeout: 10)
    }
    
    func test_createPaymentSync_withCardData() {
        let integrationKey = PaymentIntegration(merchantId: key)
        let paymentAmount = PaymentAmount(currency: .EUR, value: 1, exponent: 0)
        getTestPaymentCardSync() { result in
            do {
                let card = try result.get()
                var createPaymentRequest = CreatePaymentRequest(with: card, merchantID: integrationKey)
                createPaymentRequest.amount = paymentAmount
                createPaymentRequest.test = PaymentTest()
                Self.mockedPaylikeClient.createPaymentSync(with: createPaymentRequest) { result in
                    do {
                        let clientResponse = try result.get()
                        XCTAssertNotNil(clientResponse.createPaymentResponse)
                        XCTAssertEqual(clientResponse.HTMLBody, Self.mockPaylikeServer.htmlBodyString)
                        XCTAssertNotNil(clientResponse.createPaymentResponse.hints)
                        XCTAssertEqual(clientResponse.createPaymentResponse.hints!.count, 3)
                        XCTAssertEqual(clientResponse.createPaymentResponse.hints![0], Self.mockPaylikeServer.serverHints[0])
                        XCTAssertEqual(clientResponse.createPaymentResponse.hints![1], Self.mockPaylikeServer.serverHints[1])
                        XCTAssertEqual(clientResponse.createPaymentResponse.hints![2], Self.mockPaylikeServer.serverHints[2])
                    } catch {
                        XCTFail("Should not get error: \(error)")
                    }
                }
            } catch {
                XCTFail("Should not get error: \(error)")
            }
        }
    }
    
    func test_createPayment_withApplePay() throws {} // @TODO: Implement test
    func test_createPayment_async_withApplePay() throws {} // @TODO: Implement test
    func test_createPaymentSync_withApplePay() throws {} // @TODO: Implement test
    
    fileprivate func getTestPaymentCard(completion handler: @escaping (Result<PaymentCard, Error>) -> Void) {
        Self.mockedPaylikeClient.tokenize(
            cardData: TokenizeCardDataRequest(type: .PCN, value: Self.cardNumber)
        ) { result in
            do {
                let numberToken = try result.get()
                Self.mockedPaylikeClient.tokenize(
                    cardData: TokenizeCardDataRequest(type: .PCSC, value: Self.cardSecurityCode)
                ) { result in
                    do {
                        let cvcToken = try result.get()
                        let expiry = try CardExpiry(month: 12, year: 26)
                        handler(.success(PaymentCard(number: numberToken, code: cvcToken, expiry: expiry)))
                    } catch {
                        handler(.failure(error))
                    }
                }
            } catch {
                handler(.failure(error))
            }
        }
    }
    
    fileprivate func getTestPaymentCard() async throws -> PaymentCard {
        async let numberToken = try Self.mockedPaylikeClient.tokenize(cardData: TokenizeCardDataRequest(type: .PCN, value: Self.cardNumber))
        async let cvcToken = try Self.mockedPaylikeClient.tokenize(cardData: TokenizeCardDataRequest(type: .PCSC, value: Self.cardSecurityCode))
        let expiry = try CardExpiry(month: 12, year: 26)
        return try PaymentCard(number: await numberToken, code: await cvcToken, expiry: expiry)
    }
    
    fileprivate func getTestPaymentCardSync(completion handler: @escaping (Result<PaymentCard, Error>) -> Void) {
        var numberToken = CardDataToken(token: "")
        Self.mockedPaylikeClient.tokenizeSync(
            cardData: TokenizeCardDataRequest(type: .PCN, value: Self.cardNumber)
        ) { result in
            do {
                numberToken = try result.get()
                
            } catch {
                handler(.failure(error))
            }
        }
        var cvcToken = CardDataToken(token: "")
        Self.mockedPaylikeClient.tokenizeSync(
            cardData: TokenizeCardDataRequest(type: .PCSC, value: Self.cardSecurityCode)
        ) { result in
            do {
                cvcToken = try result.get()
            } catch {
                handler(.failure(error))
            }
        }
        do {
            let expiry = try CardExpiry(month: 12, year: 26)
            handler(.success(PaymentCard(number: numberToken, code: cvcToken, expiry: expiry)))
        } catch {
            handler(.failure(error))
        }
    }
}
