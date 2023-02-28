import Combine
import Foundation
import PaylikeRequest

/**
 *
 */
extension PaylikeClient {
    
    @available(swift 5.5)
    public func createPayment(
        with requestData: inout CreatePaymentRequest,
        path: String? = "/payments"
    ) async throws -> PaylikeClientResponse {
        loggingFn(LoggingFormat(
            t: "createPayment request:",
            createPaymentRequest: requestData
        ))
        guard var urlComponent = try URLComponents(url: getPaymentEndpointURL(), resolvingAgainstBaseURL: false) else {
            throw ClientError.URLParsingFailed("") // @TODO: what error here?
        }
        urlComponent.path = path ?? ""
        guard let url = urlComponent.url else {
            throw ClientError.URLParsingFailed(urlComponent.host!)
        }
        let response = try await httpClient.sendRequest(
            to: url,
            withOptions: initRequestOptions(withData: try JSONEncoder().encode(requestData))
        )
        var createPaymentResponse: CreatePaymentResponse
        guard let statusCode = (response.urlResponse as? HTTPURLResponse)?.statusCode else {
            throw ClientError.UnknownError // @TODO: what error here?
        }
        guard let data = response.data else {
            throw ClientError.NoResponseBody
        }
        switch statusCode {
            case 200..<300:
                createPaymentResponse = try JSONDecoder().decode(CreatePaymentResponse.self, from: data)
            default:
                let requestErrorResponse = try JSONDecoder().decode(RequestErrorResponse.self, from: data)
                throw ClientError.PaylikeServerError(
                    message: requestErrorResponse.message,
                    code: requestErrorResponse.code,
                    statusCode: statusCode,
                    errors: requestErrorResponse.errors)
        }
        /**
         * ChallengeDto process
         */
        if let challenges = createPaymentResponse.challenges,
           !challenges.isEmpty {
            let fetchChallenges = challenges.filter { challenge in
                challenge.type == ChallengeTypes.FETCH
            }
            if !fetchChallenges.isEmpty {
                return try await createPayment(with: &requestData, path: fetchChallenges.first!.path)
            }
            let tdsChallenge = challenges.filter { challenge in
                challenge.type == ChallengeTypes.BACKGROUND_IFRAME
                && challenge.name == "tds-fingerprint"
            }
            if !tdsChallenge.isEmpty {
                return try await createPayment(with: &requestData, path: tdsChallenge.first!.path)
            }
            return try await createPayment(with: &requestData, path: challenges.first!.path)
        }
        /**
         * IFrame
         */
        if let action = createPaymentResponse.action,
           let fields = createPaymentResponse.fields,
           !(action.isEmpty || fields.isEmpty) {
            if !requestData.hints.isEmpty {
                if let responseHints = createPaymentResponse.hints,
                   !responseHints.isEmpty {
                    createPaymentResponse.hints = Array(Set(requestData.hints).union(Set(responseHints)))
                } else {
                    createPaymentResponse.hints = requestData.hints
                }
            }
            let formResponse = try await httpClient.sendRequest(
                to: URL(string: action)!,
                withOptions: initRequestOptions(withFormFields: fields)
            )
            guard let data = formResponse.data else {
                throw ClientError.NoResponseBody
            }
            guard let stringData = String(data: data, encoding: .utf8) else {
                throw ClientError.UnknownError // @TODO: create error for case
            }
            return PaylikeClientResponse(with: createPaymentResponse, HTMLBody: stringData)
        }
        /**
         * Appends newly got hint to the `CreatePaymentRequest` then recursively start a new
         * `CreatePayment` iteration.
         */
        if let responseHints = createPaymentResponse.hints,
           !responseHints.isEmpty {
            if !requestData.hints.isEmpty {
                requestData.hints = Array(Set(requestData.hints).union(Set(responseHints)))
            } else {
                requestData.hints = responseHints
            }
            return try await createPayment(with: &requestData)
        }
        return PaylikeClientResponse(
            with: createPaymentResponse
        )
    }
    
    /**
     * Used for creating and executing the payment flow
     */
//    @available(iOS 13.0, macOS 10.15, *)
//    public func asdfPaymentCreate(
//        payment: CreatePaymentRequest,
//        hints: Set<String> = []
//    ) -> Future<PaylikeClientResponse, Error> {
//        return asdf_paymentCreate(
//            payment: payment,
//            hints: hints,
//            challengePath: nil
//        )
//    }
    
    /**
     Used for creating and executing the payment flow in a synchronous manner
     */
//    public func asdfPaymentCreateSync(
//        payment: CreatePaymentRequest,
//        hints: Set<String> = []
//    ) -> (response: PaylikeClientResponse?, error: Error?) {
//        let semaphore = DispatchSemaphore(value: 0)
//        var response: PaylikeClientResponse?
//        var error: Error?
//        DispatchQueue.global().async {
//            var bag: Set<AnyCancellable> = []
//            _paymentCreate(payment: payment, hints: hints, challengePath: nil).sink(receiveCompletion: { completion in
//                switch completion {
//                    case .failure(let e):
//                        error = e
//                    default:
//                        return
//                }
//            }, receiveValue: { value in
//                response = value
//                semaphore.signal()
//                bag.removeAll()
//            }).store(in: &bag)
//        }
//        semaphore.wait()
//        return (response, error)
//    }
    
    /**
     Used for recursive execution during the payment challenge flow
     */
//    private func asdf_paymentCreate(
//        payment: CreatePaymentRequest,
//        hints: Set<String> = [],
//        challengePath: String?
//    ) -> Future<PaylikeClientResponse, Error> {
//        let subPath = challengePath ?? "/payments"
//        let url = .api + subPath
//        let options = getRequestOptions()
//        options.method = "POST"
//
//        payment.hints = hints
//        options.data = try! JSONEncoder().encode(payment)
//
//        let requestPromise = httpClient.request(endpoint: url, options: options)
//
//        var bag: Set<AnyCancellable> = []
//        return Future { promise in
//            requestPromise.sink(receiveCompletion: { completion in
//                switch completion {
//                    case .failure(let error):
//                        promise(.failure(error))
//                        bag.removeAll()
//                    default:
//                        return
//                }
//            }, receiveValue: { response in
//                defer {
//                    bag.removeAll()
//                }
//                if response.data == nil {
//                    promise(.failure(PaylikeClientErrors
//                        .UnexpectedResponseBody(response.data)))
//                    return
//                }
//                let complitionHandler = { (completion: Subscribers.Completion<Error>) in
//                    switch completion {
//                        case .failure(let error):
//                            promise(.failure(error))
//                            bag.removeAll()
//                        default:
//                            return
//                    }
//                }
//                do {
//                    let body = try JSONDecoder().decode(PaymentFlowResponse.self, from: response.data!)
//                    if body.challenges != nil {
//                        let challenges = body.challenges!
//                        var bag: Set<AnyCancellable> = []
//                        let fetchChallenges = challenges.filter({ dto in
//                            dto.type == "fetch"
//                        })
//                        if !fetchChallenges.isEmpty {
//                            _paymentCreate(payment: payment, hints: hints, challengePath: fetchChallenges.first!.path)
//                                .sink(receiveCompletion: complitionHandler, receiveValue: { value in
//                                    promise(.success(value))
//                                    bag.removeAll()
//                                }).store(in: &bag)
//                            return
//                        }
//                        let tdsChallenges = challenges.filter({ dto in
//                            dto.type == "background-iframe" && dto.name == "tds-fingerprint"
//                        })
//                        if !tdsChallenges.isEmpty {
//                            _paymentCreate(payment: payment, hints: hints, challengePath: tdsChallenges.first!.path)
//                                .sink(receiveCompletion: complitionHandler, receiveValue: { value in
//                                    promise(.success(value))
//                                    bag.removeAll()
//                                }).store(in: &bag)
//                            return
//                        }
//                        _paymentCreate(payment: payment, hints: hints, challengePath: challenges.first!.path)
//                            .sink(receiveCompletion: complitionHandler, receiveValue: { value in
//                                promise(.success(value))
//                                bag.removeAll()
//                            }).store(in: &bag)
//                        return
//                    }
//                    var refreshedHints = hints
//                    if body.action != nil && body.fields != nil {
//                        if body.hints != nil {
//                            body.hints!.forEach({ hint in
//                                print("added new hint: \(hint)")
//                                refreshedHints.insert(hint)
//                            })
//                        }
//                        let formOptions = RequestOptions()
//                        formOptions.method = "POST"
//                        formOptions.form = true
//                        formOptions.formFields = body.fields!
//                        let endpoint = body.action!
//                        var bag: Set<AnyCancellable> = []
//                        requester.request(endpoint: endpoint, options: formOptions)
//                            .sink(receiveCompletion: complitionHandler, receiveValue: { response in
//                                defer {
//                                    bag.removeAll()
//                                }
//                                if response.data == nil {
//                                    promise(.failure(PaylikeClientErrors
//                                        .UnexpectedResponseBody(response.data)))
//                                    return
//                                }
//                                do {
//                                    let body = try response.getStringBody()
//                                    var dto = PaylikeClientResponse(body)
//                                    dto.hints = Array(refreshedHints)
//                                    promise(.success(dto))
//                                } catch {
//                                    promise(.failure(PaylikeClientErrors.UnexpectedPaymentFlowError(
//                                        payment: payment, hints: refreshedHints, body: body
//                                    )))
//                                }
//                            }).store(in: &bag)
//                        return
//                    }
//                    if body.hints != nil {
//                        body.hints!.forEach({ hint in
//                            print("added new hint: \(hint)")
//                            refreshedHints.insert(hint)
//                        })
//                        var bag: Set<AnyCancellable> = []
//                        _paymentCreate(payment: payment, hints: refreshedHints, challengePath: nil)
//                            .sink(receiveCompletion: complitionHandler, receiveValue: { value in
//                                promise(.success(value))
//                                bag.removeAll()
//                            }).store(in: &bag)
//                        return
//                    }
//                    if body.authorizationId != nil {
//                        let dto = PaymentResponseDTO(authorizationId: body.authorizationId!)
//                        promise(.success(PaylikeClientResponse(dto)))
//                        return
//                    }
//                    if body.transactionId != nil {
//                        let dto = PaymentResponseDTO(authorizationId: body.transactionId!)
//                        promise(.success(PaylikeClientResponse(dto)))
//                        return
//                    }
//                    promise(.failure(PaylikeClientErrors.UnexpectedPaymentFlowError(
//                        payment: payment, hints: refreshedHints, body: body
//                    )))
//                } catch {
//                    promise(.failure(PaylikeClientErrors
//                        .UnexpectedResponseBody(body: response.data)))
//                }
//            }).store(in: &bag)
//        }
//    }
}
