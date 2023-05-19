import Foundation
import Swifter
@testable import PaylikeClient

internal class MockHTTPServer {
    
    /*
     * Tokenization mock data
     */
    internal let tokenization = "tokenized+"
    
    /*
     * createPayment mock data
     */
    internal let serverHints = ["hint0", "hint1", "hint2"]
    internal let threeDSMethodData = "threeDSMethodData"
    internal let htmlBodyString = "htmlBodyString"
    
    private let server: HttpServer

    internal init(server: HttpServer = HttpServer()) {
        
        self.server = server
        
        server[MockEndpoints.CARD_DATA_VAULT.rawValue] = { request in
            let bodyData = Data(request.body)
            do {
                let tokenizeRequest = try JSONDecoder().decode(TokenizeCardDataRequest.self, from: bodyData)
                let responseBody = TokenizeResponse(token: self.tokenization + tokenizeRequest.value)
                let responseEncoded = try JSONEncoder().encode(responseBody)
                return HttpResponse.ok(.data(responseEncoded, contentType: nil))
            } catch {
                print("Caught server error: \(error)")
                return .internalServerError
            }
        }
        server[MockEndpoints.APPLE_PAY_VAULT.rawValue] = { request in
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
                        guard requestHints[0] == self.serverHints[0],
                              requestHints[1] == self.serverHints[1] else {
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
                createPaymentResponse.hints?.append(self.serverHints[0])
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
                createPaymentResponse.hints?.append(self.serverHints[1])
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
                    hints.append(self.serverHints[2])
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
                    self.threeDSMethodData: self.threeDSMethodData
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
            guard stringBody == "\(self.threeDSMethodData)=\(self.threeDSMethodData)" else {
                print("Caught server error: Got request body string invalid")
                return .internalServerError
            }
            guard let responseEncoded = self.htmlBodyString.data(using: .utf8) else {
                print("Caught server error: String to data parse failed")
                return .internalServerError
            }
            return .ok(.data(responseEncoded ,contentType: nil))
        }
    }
    
    internal func start(_ port: Int) throws {
        try server.start(in_port_t(port))
    }
    
    internal func stop() {
        server.stop()
    }
}
