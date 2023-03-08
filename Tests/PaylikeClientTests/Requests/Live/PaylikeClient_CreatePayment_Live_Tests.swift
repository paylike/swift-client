import XCTest

@testable import PaylikeClient

final class PaylikeClient_CreatePayment_Live_Tests: XCTestCase {
    
    static var paylikeClient = PaylikeClient()
    
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
    
    func test_createPayment() {
        if E2E_DISABLED {
            return
        }
        let expectation = expectation(description: "Should be able to get HTML")
        let integrationKey = PaymentIntegration(merchantId: key)
        let paymentAmount = PaymentAmount(currency: .EUR, value: 1, exponent: 0)
        getTestPaymentCard() { result in
            do {
                let card = try result.get()
                var createPaymentRequest = CreatePaymentRequest(with: card, merchantID: integrationKey)
                createPaymentRequest.amount = paymentAmount
                createPaymentRequest.test = PaymentTest()
                PaylikeClient_CreatePayment_Live_Tests.paylikeClient.createPayment(with: createPaymentRequest) { result in
                    do {
                        let clientResponse = try result.get()
                        XCTAssertNotNil(clientResponse.createPaymentResponse)
                        XCTAssertNotNil(clientResponse.HTMLBody)
                        XCTAssertNotNil(clientResponse.createPaymentResponse.hints)
                        XCTAssertEqual(clientResponse.createPaymentResponse.hints!.count, 3)
                    } catch {
                        XCTFail("Should not get error: \(error)")
                    }
                    expectation.fulfill()
                }
            } catch {
                XCTFail("Should not get error: \(error)")
            }
        }
        wait(for: [expectation], timeout: 20)
    }
    
    func test_createPayment_async() {
        if E2E_DISABLED {
            return
        }
        let expectation = expectation(description: "Should be able to get HTML")
        Task {
            let integrationKey = PaymentIntegration(merchantId: key)
            let paymentAmount = PaymentAmount(currency: .EUR, value: 1, exponent: 0)
            let card = try await getTestPaymentCard()
            
            var createPaymentRequest = CreatePaymentRequest(with: card, merchantID: integrationKey)
            createPaymentRequest.amount = paymentAmount
            createPaymentRequest.test = PaymentTest()
            
            do {
                let clientResponse = try await PaylikeClient_CreatePayment_Live_Tests.paylikeClient.createPayment(with: createPaymentRequest)
                XCTAssertNotNil(clientResponse.createPaymentResponse)
                XCTAssertNotNil(clientResponse.HTMLBody)
                XCTAssertNotNil(clientResponse.createPaymentResponse.hints)
                XCTAssertEqual(clientResponse.createPaymentResponse.hints!.count, 3)
            } catch {
                XCTFail("Should not get error " + error.localizedDescription)
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 20)
    }
    
    fileprivate func getTestPaymentCard(completion handler: @escaping (Result<PaymentCard, Error>) -> Void) {
        PaylikeClient_CreatePayment_Live_Tests.paylikeClient.tokenize(
            cardData: TokenizeCardDataRequest(type: .PCN, value: "4100000000000000")
        ) { result in
            do {
                let numberToken = try result.get()
                PaylikeClient_CreatePayment_Live_Tests.paylikeClient.tokenize(
                    cardData: TokenizeCardDataRequest(type: .PCSC, value: "123")
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
        async let numberToken = try PaylikeClient_CreatePayment_Live_Tests.paylikeClient.tokenize(cardData: TokenizeCardDataRequest(type: .PCN, value: "4100000000000000"))
        async let cvcToken = try PaylikeClient_CreatePayment_Live_Tests.paylikeClient.tokenize(cardData: TokenizeCardDataRequest(type: .PCSC, value: "123"))
        let expiry = try CardExpiry(month: 12, year: 26)
        return try PaymentCard(number: await numberToken, code: await cvcToken, expiry: expiry)
    }
}
