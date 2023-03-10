import AnyCodable
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
    
    static let serverHints = ["hint0", "hint1", "hint2"]
    static let threeDSMethodData = "threeDSMethodData"
    static let htmlBodyString = "htmlBodyString"

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
        server[MockEndpoints.CREATE_PAYMENT_API.rawValue + "/payments"] = { request in
            let bodyData = Data(request.body)
            do {
                guard let json = try JSONSerialization.jsonObject(with: bodyData, options: .mutableContainers) as? [String: Any] else {
                    print("Caught server error: Request body deserialization failed")
                    return .internalServerError
                }
                guard let requestHints: [String] = json["hints"] as? [String] else {
                    print("Caught server error: No hints field")
                    return .internalServerError
                }
                var createPaymentResponse = CreatePaymentResponse()
                switch requestHints.count {
                    case 0:
                        createPaymentResponse.challenges = [
                            ChallengeResponse(name: "authorize-integration", type: .FETCH, path: "/payments/challenges/authorize-integration"),
                            ChallengeResponse(name: "fingerprint", type: .BACKGROUND_IFRAME, path: "/payments/challenges/fingerprint")
                        ]
                    case 1:
                        createPaymentResponse.challenges = [
                            ChallengeResponse(name: "tds-enrolled", type: .FETCH, path: "/payments/challenges/tds-enrolled"),
                            ChallengeResponse(name: "fingerprint", type: .BACKGROUND_IFRAME, path: "/payments/challenges/fingerprint")
                        ]
                    case 2:
                        guard requestHints[0] == Self.serverHints[0],
                              requestHints[1] == Self.serverHints[1] else {
                            print("Caught server error: Wrong hints order")
                            return .internalServerError
                        }
                        createPaymentResponse.challenges = [
                            ChallengeResponse(name: "tds-fingerprint", type: .BACKGROUND_IFRAME, path: "/payments/challenges/tds-fingerprint"),
                            ChallengeResponse(name: "fingerprint", type: .BACKGROUND_IFRAME, path: "/payments/challenges/fingerprint")
                        ]
                    default:
                        print("Caught server error: No right amount of hints")
                        return .internalServerError
                }
                let responseEncoded = try JSONEncoder().encode(createPaymentResponse)
                return .ok(.data(responseEncoded ,contentType: nil))
            } catch {
                print("Caught server error: \(error)")
                return .internalServerError
            }
        }
        server[MockEndpoints.CREATE_PAYMENT_API.rawValue + "/payments/challenges/authorize-integration"] = { request in
            let bodyData = Data(request.body)
            do {
                guard let json = try JSONSerialization.jsonObject(with: bodyData, options: .mutableContainers) as? [String: Any] else {
                    print("Caught server error: Request body deserialization failed")
                    return .internalServerError
                }
                guard let requestHints: [String] = json["hints"] as? [String] else {
                    print("Caught server error: No hints field")
                    return .internalServerError
                }
                guard requestHints.count == 0 else {
                    print("Caught server error: Wrong amount of hints received")
                    return .internalServerError
                }
                var createPaymentResponse = CreatePaymentResponse()
                createPaymentResponse.hints = [String]()
                createPaymentResponse.hints?.append(serverHints[0])
                let responseEncoded = try JSONEncoder().encode(createPaymentResponse)
                return .ok(.data(responseEncoded ,contentType: nil))
            } catch {
                print("Caught server error: \(error)")
                return .internalServerError
            }
        }
        server[MockEndpoints.CREATE_PAYMENT_API.rawValue + "/payments/challenges/tds-enrolled"] = { request in
            let bodyData = Data(request.body)
            do {
                guard let json = try JSONSerialization.jsonObject(with: bodyData, options: .mutableContainers) as? [String: Any] else {
                    print("Caught server error: Request body deserialization failed")
                    return .internalServerError
                }
                guard let requestHints: [String] = json["hints"] as? [String] else {
                    print("Caught server error: No hints field")
                    return .internalServerError
                }
                guard requestHints.count == 1 else {
                    print("Caught server error: Wrong amount of hints received")
                    return .internalServerError
                }
                var createPaymentResponse = CreatePaymentResponse()
                createPaymentResponse.hints = [String]()
                createPaymentResponse.hints?.append(serverHints[1])
                let responseEncoded = try JSONEncoder().encode(createPaymentResponse)
                return .ok(.data(responseEncoded ,contentType: nil))
            } catch {
                print("Caught server error: \(error)")
                return .internalServerError
            }
        }
        server[MockEndpoints.CREATE_PAYMENT_API.rawValue + "/payments/challenges/tds-fingerprint"] = { request in
            let bodyData = Data(request.body)
            do {
                guard let json = try JSONSerialization.jsonObject(with: bodyData, options: .mutableContainers) as? [String: Any] else {
                    print("Caught server error: Request body deserialization failed")
                    return .internalServerError
                }
                guard let requestHints: [String] = json["hints"] as? [String] else {
                    print("Caught server error: No hints field")
                    return .internalServerError
                }
                guard requestHints.count == 2 else {
                    print("Caught server error: Wrong amount of hints received")
                    return .internalServerError
                }
                var createPaymentResponse = CreatePaymentResponse()
                createPaymentResponse.hints = {
                    var hints = [String]()
                    hints.append(serverHints[2])
                    return hints
                }()
                guard var urlComponents = URLComponents(url: try getPaymentEndpointURL(), resolvingAgainstBaseURL: false) else {
                    print("Caught server error: URL parsing error in tds-fingerprint endpoint")
                    return .internalServerError
                }
                urlComponents.path = "/3dsecure/v2/method"
                createPaymentResponse.action = urlComponents.string
                createPaymentResponse.method = "POST"
                createPaymentResponse.fields = [
                    threeDSMethodData: threeDSMethodData
                ]
                let responseEncoded = try JSONEncoder().encode(createPaymentResponse)
                return .ok(.data(responseEncoded ,contentType: nil))
            } catch {
                print("Caught server error: \(error)")
                return .internalServerError
            }
        }
        server[MockEndpoints.CREATE_PAYMENT_API.rawValue + "/3dsecure/v2/method"] = { request in
            let bodyData = Data(request.body)
            guard let stringBody = String(data: bodyData, encoding: .utf8) else {
                print("Caught server error: Request body invalid")
                return .internalServerError
            }
            guard stringBody == "\(Self.threeDSMethodData)=\(Self.threeDSMethodData)" else {
                print("Caught server error: Got request body string invalid")
                return .internalServerError
            }
            guard let responseEncoded = Self.htmlBodyString.data(using: .utf8) else {
                print("Caught server error: String to data parse failed")
                return .internalServerError
            }
            return .ok(.data(responseEncoded ,contentType: nil))
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
                PaylikeClient_CreatePayment_Mock_Tests.paylikeClient.createPayment(with: createPaymentRequest) { result in
                    do {
                        let clientResponse = try result.get()
                        XCTAssertNotNil(clientResponse.createPaymentResponse)
                        XCTAssertEqual(clientResponse.HTMLBody, Self.htmlBodyString)
                        XCTAssertNotNil(clientResponse.createPaymentResponse.hints)
                        XCTAssertEqual(clientResponse.createPaymentResponse.hints!.count, 3)
                        XCTAssertEqual(clientResponse.createPaymentResponse.hints![0], Self.serverHints[0])
                        XCTAssertEqual(clientResponse.createPaymentResponse.hints![1], Self.serverHints[1])
                        XCTAssertEqual(clientResponse.createPaymentResponse.hints![2], Self.serverHints[2])
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
                let clientResponse = try await PaylikeClient_CreatePayment_Mock_Tests.paylikeClient.createPayment(with: createPaymentRequest)
                XCTAssertNotNil(clientResponse.createPaymentResponse)
                XCTAssertEqual(clientResponse.HTMLBody, Self.htmlBodyString)
                XCTAssertNotNil(clientResponse.createPaymentResponse.hints)
                XCTAssertEqual(clientResponse.createPaymentResponse.hints!.count, 3)
                XCTAssertEqual(clientResponse.createPaymentResponse.hints![0], Self.serverHints[0])
                XCTAssertEqual(clientResponse.createPaymentResponse.hints![1], Self.serverHints[1])
                XCTAssertEqual(clientResponse.createPaymentResponse.hints![2], Self.serverHints[2])
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
                PaylikeClient_CreatePayment_Mock_Tests.paylikeClient.createPaymentSync(with: createPaymentRequest) { result in
                    do {
                        let clientResponse = try result.get()
                        XCTAssertNotNil(clientResponse.createPaymentResponse)
                        XCTAssertEqual(clientResponse.HTMLBody, Self.htmlBodyString)
                        XCTAssertNotNil(clientResponse.createPaymentResponse.hints)
                        XCTAssertEqual(clientResponse.createPaymentResponse.hints!.count, 3)
                        XCTAssertEqual(clientResponse.createPaymentResponse.hints![0], Self.serverHints[0])
                        XCTAssertEqual(clientResponse.createPaymentResponse.hints![1], Self.serverHints[1])
                        XCTAssertEqual(clientResponse.createPaymentResponse.hints![2], Self.serverHints[2])
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
        PaylikeClient_CreatePayment_Mock_Tests.paylikeClient.tokenize(
            cardData: TokenizeCardDataRequest(type: .PCN, value: Self.cardNumber)
        ) { result in
            do {
                let numberToken = try result.get()
                PaylikeClient_CreatePayment_Mock_Tests.paylikeClient.tokenize(
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
        async let numberToken = try PaylikeClient_CreatePayment_Mock_Tests.paylikeClient.tokenize(cardData: TokenizeCardDataRequest(type: .PCN, value: Self.cardNumber))
        async let cvcToken = try PaylikeClient_CreatePayment_Mock_Tests.paylikeClient.tokenize(cardData: TokenizeCardDataRequest(type: .PCSC, value: Self.cardSecurityCode))
        let expiry = try CardExpiry(month: 12, year: 26)
        return try PaymentCard(number: await numberToken, code: await cvcToken, expiry: expiry)
    }
    
    fileprivate func getTestPaymentCardSync(completion handler: @escaping (Result<PaymentCard, Error>) -> Void) {
        var numberToken = CardDataToken(token: "")
        PaylikeClient_CreatePayment_Mock_Tests.paylikeClient.tokenizeSync(
            cardData: TokenizeCardDataRequest(type: .PCN, value: Self.cardNumber)
        ) { result in
            do {
                numberToken = try result.get()
                
            } catch {
                handler(.failure(error))
            }
        }
        var cvcToken = CardDataToken(token: "")
        PaylikeClient_CreatePayment_Mock_Tests.paylikeClient.tokenizeSync(
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


extension CreatePaymentResponse : Encodable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: Keys.self)
        
        try container.encode(challenges, forKey: .challenges)
        try container.encode(hints, forKey: .hints)
        try container.encode(action, forKey: .action)
        try container.encode(method, forKey: .method)
        try container.encode(fields, forKey: .fields)
        try container.encode(timeout, forKey: .timeout)
        try container.encode(authorizationId, forKey: .authorizationId)
        try container.encode(transactionId, forKey: .transactionId)
    }
    
    private enum Keys : String, CodingKey {
        case challenges
        case hints
        case action
        case method
        case fields
        case timeout
        case authorizationId
        case transactionId
    }
}

extension ChallengeResponse : Encodable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: Keys.self)
        
        try container.encode(name, forKey: .name)
        try container.encode(type, forKey: .type)
        try container.encode(path, forKey: .path)
    }
    
    private enum Keys : String, CodingKey {
        case name
        case type
        case path
    }
}

extension ChallengeTypes : Encodable {}
