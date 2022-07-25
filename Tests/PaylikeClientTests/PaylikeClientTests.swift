import XCTest
@testable import PaylikeClient
import PaylikeMoney
import Combine



final class PaylikeClientTests: XCTestCase {
    func testClientIDGeneration() throws {
        XCTAssertNotNil(PaylikeClient.generateClientID())
        XCTAssertEqual(PaylikeClient.generateClientID().count, "swift-1-123456".count)
    }
    
    func testTokenization() throws {
        let client = PaylikeClient()
        let promise = client.tokenize(type: PaylikeTokenizedTypes.PCN, value: "4100000000000000")
        let expectation = expectation(description: "Value should be received")
        var bag: Set<AnyCancellable> = []
        promise.sink(receiveCompletion: { completion in
            switch completion {
            case .failure(let error):
                print(error)
                XCTFail("Unexpected error")
            default:
                return
            }
        }, receiveValue: { tokenized in
            XCTAssertNotNil(tokenized)
            expectation.fulfill()
        }).store(in: &bag)
        wait(for: [expectation], timeout: 50)
    }
    
    func testTokenizationSync() throws {
        let client = PaylikeClient()
        var (token, error) = client.tokenizeSync(type: PaylikeTokenizedTypes.PCN, value: "4100000000000000")
        XCTAssertNotNil(token)
        XCTAssertNil(error)
        (token, error) = client.tokenizeSync(type: PaylikeTokenizedTypes.PCSC, value: "123")
        XCTAssertNotNil(token)
        XCTAssertNil(error)
    }
    
    func getTestCardTokenized() -> (number: String, cvc: String) {
        let client = PaylikeClient()
        let (number, _) = client.tokenizeSync(type: PaylikeTokenizedTypes.PCN, value: "4100000000000000")
        let (cvc, _) = client.tokenizeSync(type: PaylikeTokenizedTypes.PCSC, value: "123")
        return (number, cvc)
    }
    
    func testPaymentCreation() throws {
        let client = PaylikeClient()
        let dto = PaymentRequestDTO(key: "e393f9ec-b2f7-4f81-b455-ce45b02d355d")
        dto.amount = try PaylikeMoney.fromDouble(currency: "EUR", n: 5.0)
        let (number, cvc) = getTestCardTokenized()
        dto.card = PaymentRequestCardDTO(number: number, month: 12, year: 26, code: cvc)
        var bag: Set<AnyCancellable> = []
        let expectation = expectation(description: "Should be able to get HTML")
        client.paymentCreate(payment: dto).sink(receiveCompletion: { completion in
            switch completion {
            case .failure(let error):
                XCTFail("Should not get error " + error.localizedDescription)
                expectation.fulfill()
            default:
                return
            }
        }, receiveValue: { response in
            defer {
                expectation.fulfill()
                bag.removeAll()
            }
            XCTAssertTrue(response.isHTML)
            XCTAssertNil(response.paymentResponse)
            XCTAssertNotNil(response.HTMLBody)
            XCTAssertEqual(response.hints!.count, 3)
        }).store(in: &bag)
        wait(for: [expectation], timeout: 50)
    }
}
