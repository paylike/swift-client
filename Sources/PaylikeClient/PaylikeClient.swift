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
        let options = RequestOptions()
        options.clientId = clientId
        options.timeout = timeout
        return options
    }
    /**
     Used for creating and executing the payment flow
     */
    @available(iOS 13.0, macOS 10.15, *)
    public func paymentCreate(payment: PaymentRequestDTO, hints: Set<String> = []) -> Future<PaylikeClientResponse, Error> {
        return _paymentCreate(payment: payment, hints: hints, challengePath: nil)
    }
    
    /**
     Used for creating and executing the payment flow in a synchronous manner
     */
    public func paymentCreateSync(payment: PaymentRequestDTO, hints: Set<String> = []) -> (response: PaylikeClientResponse?, error: Error?) {
        let semaphore = DispatchSemaphore(value: 0)
        var response: PaylikeClientResponse?
        var error: Error?
        DispatchQueue.global().async {
            var bag: Set<AnyCancellable> = []
            _paymentCreate(payment: payment, hints: hints, challengePath: nil).sink(receiveCompletion: { completion in
                switch completion {
                case .failure(let e):
                    error = e
                default:
                    return
                }
            }, receiveValue: { value in
                response = value
                semaphore.signal()
                bag.removeAll()
            }).store(in: &bag)
        }
        semaphore.wait()
        return (response, error)
    }

    /**
     Used for recursive execution during the payment challenge flow
     */
    private func _paymentCreate(payment: PaymentRequestDTO, hints: Set<String> = [], challengePath: String?) -> Future<PaylikeClientResponse, Error> {
        let subPath = challengePath ?? "/payments"
        let url = hosts.api + subPath
        let options = getRequestOptions()
        options.method = "POST"
        payment.hints = hints
        options.data = try! JSONEncoder().encode(payment)
        let requestPromise = requester.request(endpoint: url, options: options)
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
                let complitionHandler = { (completion: Subscribers.Completion<Error>) in
                    switch completion {
                    case .failure(let error):
                        promise(.failure(error))
                        bag.removeAll()
                    default:
                        return
                    }
                }
                do {
                    let body = try JSONDecoder().decode(PaymentFlowResponse.self, from: response.data!)
                    if body.challenges != nil {
                        let challenges = body.challenges!
                        var bag: Set<AnyCancellable> = []
                        let fetchChallenges = challenges.filter({ dto in
                            dto.type == "fetch"
                        })
                        if !fetchChallenges.isEmpty {
                            _paymentCreate(payment: payment, hints: hints, challengePath: fetchChallenges.first!.path)
                                .sink(receiveCompletion: complitionHandler, receiveValue: { value in
                                    promise(.success(value))
                                    bag.removeAll()
                                }).store(in: &bag)
                            return
                        }
                        let tdsChallenges = challenges.filter({ dto in
                            dto.type == "background-iframe" && dto.name == "tds-fingerprint"
                        })
                        if !tdsChallenges.isEmpty {
                            _paymentCreate(payment: payment, hints: hints, challengePath: tdsChallenges.first!.path)
                                .sink(receiveCompletion: complitionHandler, receiveValue: { value in
                                    promise(.success(value))
                                    bag.removeAll()
                                }).store(in: &bag)
                            return
                        }
                        _paymentCreate(payment: payment, hints: hints, challengePath: challenges.first!.path)
                            .sink(receiveCompletion: complitionHandler, receiveValue: { value in
                                promise(.success(value))
                                bag.removeAll()
                            }).store(in: &bag)
                        return
                    }
                    var refreshedHints = hints
                    if body.action != nil && body.fields != nil {
                        if body.hints != nil {
                            body.hints!.forEach({ hint in
                                print("added new hint: \(hint)")
                                refreshedHints.insert(hint)
                            })
                        }
                        let formOptions = RequestOptions()
                        formOptions.method = "POST"
                        formOptions.form = true
                        formOptions.formFields = body.fields!
                        let endpoint = body.action!
                        var bag: Set<AnyCancellable> = []
                        requester.request(endpoint: endpoint, options: formOptions)
                            .sink(receiveCompletion: complitionHandler, receiveValue: { response in
                                defer {
                                    bag.removeAll()
                                }
                                if response.data == nil {
                                    promise(.failure(PaylikeClientErrors
                                        .UnexpectedResponseBody(body: response.data)))
                                    return
                                }
                                do {
                                    let body = try response.getStringBody()
                                    var dto = PaylikeClientResponse(body)
                                    dto.hints = Array(refreshedHints)
                                    promise(.success(dto))
                                } catch {
                                    promise(.failure(PaylikeClientErrors.UnexpectedPaymentFlowError(
                                        payment: payment, hints: refreshedHints, body: body
                                    )))
                                }
                            }).store(in: &bag)
                        return
                    }
                    if body.hints != nil {
                        body.hints!.forEach({ hint in
                            print("added new hint: \(hint)")
                            refreshedHints.insert(hint)
                        })
                        var bag: Set<AnyCancellable> = []
                        _paymentCreate(payment: payment, hints: refreshedHints, challengePath: nil)
                            .sink(receiveCompletion: complitionHandler, receiveValue: { value in
                                promise(.success(value))
                                bag.removeAll()
                            }).store(in: &bag)
                        return
                    }
                    if body.authorizationId != nil {
                        let dto = PaymentResponseDTO(authorizationId: body.authorizationId!)
                        promise(.success(PaylikeClientResponse(dto)))
                        return
                    }
                    if body.transactionId != nil {
                        let dto = PaymentResponseDTO(authorizationId: body.transactionId!)
                        promise(.success(PaylikeClientResponse(dto)))
                        return
                    }
                    promise(.failure(PaylikeClientErrors.UnexpectedPaymentFlowError(
                        payment: payment, hints: refreshedHints, body: body
                    )))
                } catch {
                    promise(.failure(PaylikeClientErrors
                        .UnexpectedResponseBody(body: response.data)))
                }
            }).store(in: &bag)
        }
        
    }
    
    /**
     Synchronous method that waits for the resolution of the future
     */
    @available(iOS 13.0, macOS 10.15, *)
    public func tokenizeSync(type: PaylikeTokenizedTypes, value: String) -> (token: String, error: Error?) {
        let semaphore = DispatchSemaphore(value: 0)
        var token = ""
        var error: Error?
        DispatchQueue.global().async {
            var bag: Set<AnyCancellable> = []
            tokenize(type: type, value: value).sink(receiveCompletion: { completion in
                switch completion {
                case .failure(let e):
                    error = e
                default:
                    return
                }
            }, receiveValue: { value in
                token = value
                semaphore.signal()
                bag.removeAll()
            }).store(in: &bag)
        }
        semaphore.wait()
        return (token, error)
    }
    
    /**
     Used for Apple Pay tokenization
     */
    @available(iOS 13.0, macOS 10.15, *)
    public func tokenize(appleToken: String) -> Future<String, Error> {
        let options = getRequestOptions()
            .withData(try! JSONSerialization.data(withJSONObject: ["token": appleToken]))
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
        let options = getRequestOptions().withData(
            try! JSONSerialization.data(
                withJSONObject: ["type": type == .PCN ? "pcn" : "pcsc", "value": value]
            )
        )
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
