import XCTest

@testable import PaylikeClient

final class ClientModelTests: XCTestCase {
    
    func testPaymentAmountCurrency() {
        let integrationKey = PaymentIntegration(merchantId: key)
        var dto = CreatePaymentRequest(merchantID: integrationKey)
        dto.amount = PaymentAmount(currency: .AED, value: 1, exponent: 0)
        XCTAssertEqual(dto.amount!.currency.rawValue, "AED")
    }
    
    func testPaymentAmountFromDouble() {
        do {
            let amount = try PaymentAmount(currency: .EUR, double: 20.01)
            XCTAssertEqual(amount.value, 2001)
            XCTAssertEqual(amount.exponent, 2)
        } catch {
            print(error)
            XCTFail("Unexpected error")
        }
    }
    
    func testPaymentAmountEquatable() throws {
        var amount = PaymentAmount(currency: .EUR, value: 2001, exponent: 0)
        var otherAmount = PaymentAmount(currency: .EUR, value: 200100, exponent: 2)
        XCTAssertTrue(amount == otherAmount)
        amount = try PaymentAmount(currency: .EUR, double: 20.01)
        otherAmount = PaymentAmount(currency: .EUR, value: 2001, exponent: 2)
        XCTAssertTrue(amount == otherAmount)
        amount = try PaymentAmount(currency: .AED, double: 20.01)
        otherAmount = PaymentAmount(currency: .EUR, value: 2001, exponent: 2)
        XCTAssertTrue(amount != otherAmount)
        amount = try PaymentAmount(currency: .EUR, double: 20.00)
        otherAmount = PaymentAmount(currency: .EUR, value: 2001, exponent: 2)
        XCTAssertTrue(amount != otherAmount)
    }
    
    func testCardExpiry() {
        XCTAssertNoThrow(try CardExpiry(month: 11, year: 23))
        
        XCTAssertThrowsError(try CardExpiry(month: 13, year: 23))
        XCTAssertThrowsError(try CardExpiry(month: 0, year: 23))
        XCTAssertThrowsError(try CardExpiry(month: 12, year: 100))
        XCTAssertThrowsError(try CardExpiry(month: 12, year: 0))
        XCTAssertThrowsError(try CardExpiry(month: 12, year: 2100))
        XCTAssertThrowsError(try CardExpiry(month: 12, year: 2000))
    }
    
    
}
