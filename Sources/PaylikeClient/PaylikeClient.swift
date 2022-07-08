import PaylikeRequest
import Combine
import Foundation

/**
 Handles hih level requests toward the Paylike APIs
 */
public struct PaylikeClient {
    /**
     Client ID sent to the API to identify the client connection interface
     */
    public var clientId = PaylikeClient.generateClientID()
    /**
     Timeout interval for requests in seconds
     */
    public var timeout = 20.0
    /**
     APIs used in the client
     */
    public var hosts = PaylikeHosts()
    /**
     Underlying requester implementation used
     */
    let requester: PaylikeRequester
    /**
     Used for logging, called when the request is constructed
     */
    public var loggingFn: (Encodable) -> Void = { obj in
        print(obj)
    }
    /**
     Overwrite logging function with your own
     */
    public init(log: @escaping (Encodable) -> Void) {
        self.loggingFn = log
        requester = PaylikeRequester(log: log)
    }
    /**
     Creates a new client with default values
     */
    public init() {
        requester = PaylikeRequester(log: loggingFn)
    }
    /**
     Generates a new client ID to identify requests in the API
     */
    static func generateClientID() -> String {
        let chars = "AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890"
        let id = (0..<6).map { _ in
            String(chars.randomElement()!)
        }
        return "swift-1-\(id.joined())"
    }
    
    /**
     Adds timeout and client ID to the request options by default
     */
    private func getRequestOptions() -> RequestOptions {
        var options = RequestOptions()
        options.clientId = clientId
        options.timeout = timeout
        return options
    }
    
    /**
     Used for creating and executing the payment flow
     */
    @available(iOS 13.0, macOS 10.15, *)
    public func paymentCreate(payment: [String: Any], hints: Set<String> = []) -> Future<String, Error> {
        
        return Future { promise in
            promise(.success("hey"))
        }
    }
    
    /**
     Used for recursive execution during the payment challenge flow
     */
    private func paymentCreate(payment: [String: Any], hints: Set<String> = [], challengePath: String?) {
        let subPath = challengePath ?? "/payments"
        let url = hosts.api + subPath
        var options = getRequestOptions()
        options.method = "POST"
        var payload: [String: Any] = ["hints": hints]
        payment.forEach { payload[$0] = $1 }
        options.data = payload
        PaymentReq
    }
    
    /**
     Used for Apple Pay tokenization
     */
    @available(iOS 13.0, macOS 10.15, *)
    public func tokenize(appleToken: String) -> Future<String, Error> {
        var options = getRequestOptions()
        options.method = "POST"
        options.data = ["token": appleToken]
        let requestPromise = requester.request(endpoint: hosts.applePayAPI, options: options)
        var bag: Set<AnyCancellable> = []
        return Future { promise in
            requestPromise.sink(receiveCompletion: { completion in
                switch completion {
                case .failure(let error):
                    promise(.failure(error))
                    bag.removeAll()
                default:
                    return
                }
            }, receiveValue: { response in
                defer {
                    bag.removeAll()
                }
                if response.data == nil {
                    promise(.failure(PaylikeClientErrors
                        .UnexpectedResponseBody(body: response.data)))
                    return
                }
                do {
                    let body = try response.getJSONBody()
                    let token = body["token"] as! String
                    promise(.success(token))
                } catch {
                    promise(.failure(PaylikeClientErrors
                        .UnexpectedResponseBody(body: response.data)))
                }
            }).store(in: &bag)
        }
    }
    
    /**
     Tokenizes a card number or card CVC code
     */
    @available(iOS 13.0, macOS 10.15, *)
    public func tokenize(type: PaylikeTokenizedTypes, value: String) -> Future<String, Error> {
        var options = getRequestOptions()
        options.method = "POST"
        options.data = ["type": type == .PCN ? "pcn" : "pcsc", "value": value]
        let requestPromise = requester.request(endpoint: hosts.vault, options: options)
        var bag: Set<AnyCancellable> = []
        return Future { promise in
            requestPromise.sink(
                receiveCompletion: { completion in
                    switch completion {
                    case .failure(let error):
                        promise(.failure(error))
                        bag.removeAll()
                    default:
                        return
                    }
                }, receiveValue: { response in
                    defer {
                        bag.removeAll()
                    }
                    if response.data == nil {
                        promise(.failure(PaylikeClientErrors
                            .UnexpectedResponseBody(body: response.data)))
                        return
                    }
                    do {
                        let body = try response.getJSONBody()
                        let token = body["token"] as! String
                        promise(.success(token))
                    } catch {
                        promise(.failure(PaylikeClientErrors
                            .UnexpectedResponseBody(body: response.data)))
                    }
                }).store(in: &bag)
        }
    }
}
