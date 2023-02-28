import XCTest

@testable import PaylikeClient

final class PaylikeClient_CreatePayment_Live_Tests: XCTestCase {
    
    static var paylikeClient = PaylikeClient()
    
    override class func setUp() {
        /**
         * Initializing client and HTTPclient without logging. We do not log in tests
         */
//        paylikeClient.loggingFn = { _ in
//            // do nothing
//        }
        paylikeClient.httpClient.loggingFn = { _ in
            // do nothing
        }
    }
    
    func test_createPayment() throws {
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
    
    fileprivate func getTestPaymentCard() async throws  -> PaymentCard {
        let numberToken = try await PaylikeClient_CreatePayment_Live_Tests.paylikeClient.tokenize(cardData: TokenizeCardDataRequest(type: .PCN, value: "4100000000000000"))
        let cvcToken = try await PaylikeClient_CreatePayment_Live_Tests.paylikeClient.tokenize(cardData: TokenizeCardDataRequest(type: .PCSC, value: "123"))
        let expiry = try CardExpiry(month: 12, year: 26)
        return PaymentCard(number: numberToken, code: cvcToken, expiry: expiry)
    }
}
