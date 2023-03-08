import Foundation
import PaylikeRequest

/**
 * Extension for payment creation functions
 */
extension PaylikeClient {
    
    /**
     * Used for creating and executing the payment flow
     */
    public func createPayment(
        with requestData: CreatePaymentRequest,
        withCompletion handler: @escaping (Result<PaylikeClientResponse, Error>) -> Void
    ) -> Void {
        _createPayment(
            with: requestData,
            withCompletion: handler
        )
    }
    
    /**
     * High level request implementation towards the Paylike API with `completionHandler` pattern
     */
    fileprivate func _createPayment(
        with requestData: CreatePaymentRequest,
        path: String? = "/payments",
        withCompletion handler: @escaping (Result<PaylikeClientResponse, Error>) -> Void
    ) -> Void {

        loggingFn(LoggingFormat(
            t: "createPayment request:",
            createPaymentRequest: requestData
        ))
        
        do {
            let (url, requestOptions) = try preparingData(path, requestData)
        
            /*
             * Execute request
             */
            httpClient.sendRequest(
                to: url,
                withOptions: requestOptions
            ) { result in
                do {
                    var createPaymentResponse = try self.checkResponse(result.get())
                    
                    let fallthroughHandler: (Result<PaylikeClientResponse, Error>) -> Void = { result in
                        do {
                            handler(.success(try result.get()))
                        } catch {
                            handler(.failure(error))
                        }
                    }
                    
                    /*
                     * Challenge process
                     */
                    if let challenges = createPaymentResponse.challenges,
                       !challenges.isEmpty {
                        let fetchChallenges = challenges.filter { challenge in
                            challenge.type == ChallengeTypes.FETCH
                        }
                        if !fetchChallenges.isEmpty {
                            self._createPayment(
                                with: requestData,
                                path: fetchChallenges.first!.path,
                                withCompletion: fallthroughHandler
                            )
                            return
                        }
                        let tdsChallenge = challenges.filter { challenge in
                            challenge.type == ChallengeTypes.BACKGROUND_IFRAME
                            && challenge.name == "tds-fingerprint"
                        }
                        if !tdsChallenge.isEmpty {
                            self._createPayment(
                                with: requestData,
                                path: tdsChallenge.first!.path,
                                withCompletion: fallthroughHandler
                            )
                            return
                        }
                        self._createPayment(
                            with: requestData,
                            path: challenges.first!.path,
                            withCompletion: fallthroughHandler
                        )
                        return
                    }
                    
                    /*
                     * IFrame process
                     */
                    if let action = createPaymentResponse.action,
                       let fields = createPaymentResponse.fields,
                       !(action.isEmpty || fields.isEmpty) {
                        self.httpClient.sendRequest(
                            to: URL(string: action)!,
                            withOptions: self.initRequestOptions(withFormFields: fields)
                        ) { result in
                            do {
                                let formResponse = try result.get()
                                guard let data = formResponse.data else {
                                    throw ClientError.NoResponseBody
                                }
                                guard let stringData = String(data: data, encoding: .utf8) else {
                                    throw ClientError.UnknownError // @TODO: create error for case
                                }
                                if !requestData.hints.isEmpty {
                                    if let responseHints = createPaymentResponse.hints,
                                       !responseHints.isEmpty {
                                        createPaymentResponse.hints = Array(Set(requestData.hints).union(Set(responseHints)))
                                    } else {
                                        createPaymentResponse.hints = requestData.hints
                                    }
                                }
                                handler(.success(PaylikeClientResponse(
                                    with: createPaymentResponse,
                                    HTMLBody: stringData
                                )))
                            } catch {
                                handler(.failure(error))
                            }
                        }
                        return
                    }
                    
                    /*
                     * Appends newly got hint to the `CreatePaymentRequest` then recursively start a new
                     * `CreatePayment` iteration.
                     */
                    if let responseHints = createPaymentResponse.hints,
                       !responseHints.isEmpty {
                        var requestData = requestData
                        if !requestData.hints.isEmpty {
                            requestData.hints = Array(Set(requestData.hints).union(Set(responseHints)))
                        } else {
                            requestData.hints = responseHints
                        }
                        self._createPayment(
                            with: requestData,
                            withCompletion: fallthroughHandler
                        )
                        return
                    }
                    
                    guard createPaymentResponse.authorizationId != nil
                            || createPaymentResponse.transactionId != nil
                    else {
                        throw ClientError.UnexpectedPaymentFlowError(payment: requestData, body: createPaymentResponse)
                    }
                    handler(.success(PaylikeClientResponse(with: createPaymentResponse)))
                } catch {
                    handler(.failure(error))
                }
            }
        } catch {
            handler(.failure(error))
        }
    }
    
    /**
     * Same functionality as `createPayment(..., withCompletion:)` but with async await syntax features
     */
    public func createPayment(
        with requestData: CreatePaymentRequest
    ) async throws -> PaylikeClientResponse {
        var requestData = requestData
        return try await _createPayment(with: &requestData)
    }
    
    /**
     * High level request implementation towards the Paylike API with `async` `await` syntax
     */
    @available(iOS 13.0, macOS 10.15, *)
    fileprivate func _createPayment(
        with requestData: inout CreatePaymentRequest,
        path: String? = "/payments"
    ) async throws -> PaylikeClientResponse {
        
        loggingFn(LoggingFormat(
            t: "createPayment request:",
            createPaymentRequest: requestData
        ))
        
        let (url, requestOptions) = try preparingData(path, requestData)

        let response = try await httpClient.sendRequest(
            to: url,
            withOptions: requestOptions
        )
        
        var createPaymentResponse = try self.checkResponse(response)
        
        /*
         * Challenge process
         */
        if let challenges = createPaymentResponse.challenges,
           !challenges.isEmpty {
            let fetchChallenges = challenges.filter { challenge in
                challenge.type == ChallengeTypes.FETCH
            }
            if !fetchChallenges.isEmpty {
                return try await _createPayment(with: &requestData, path: fetchChallenges.first!.path)
            }
            let tdsChallenge = challenges.filter { challenge in
                challenge.type == ChallengeTypes.BACKGROUND_IFRAME
                && challenge.name == "tds-fingerprint"
            }
            if !tdsChallenge.isEmpty {
                return try await _createPayment(with: &requestData, path: tdsChallenge.first!.path)
            }
            return try await _createPayment(with: &requestData, path: challenges.first!.path)
        }
        
        /*
         * IFrame process
         */
        if let action = createPaymentResponse.action,
           let fields = createPaymentResponse.fields,
           !(action.isEmpty || fields.isEmpty) {
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
            if !requestData.hints.isEmpty {
                if let responseHints = createPaymentResponse.hints,
                   !responseHints.isEmpty {
                    createPaymentResponse.hints = Array(Set(requestData.hints).union(Set(responseHints)))
                } else {
                    createPaymentResponse.hints = requestData.hints
                }
            }
            return PaylikeClientResponse(with: createPaymentResponse, HTMLBody: stringData)
        }
        
        /*
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
            return try await _createPayment(with: &requestData)
        }
        
        guard createPaymentResponse.authorizationId != nil
                || createPaymentResponse.transactionId != nil
        else {
            throw ClientError.UnexpectedPaymentFlowError(payment: requestData, body: createPaymentResponse)
        }
        return PaylikeClientResponse(
            with: createPaymentResponse
        )
    }
    
    
    /**
     * Preparring `url` and `requestOptions` for `sendRequest(to:withOptions)`
     * Can be function...
     * (path, requestData) -> (url, requestOptions)
     */
    fileprivate func preparingData( _ path: String?, _ requestData: CreatePaymentRequest) throws -> (URL, RequestOptions) {
        guard var urlComponent = try URLComponents(url: getPaymentEndpointURL(), resolvingAgainstBaseURL: false) else {
            throw ClientError.URLParsingFailed
        }
        urlComponent.path = path ?? ""
        guard let url = urlComponent.url else {
            throw ClientError.URLParsingFailed
        }
        let requestOptions = initRequestOptions(withData: try JSONEncoder().encode(requestData))
        return (url, requestOptions)
    }
    
    /**
     * Check on the response
     */
    fileprivate func checkResponse(_ response: PaylikeResponse) throws -> CreatePaymentResponse {
        guard let statusCode = (response.urlResponse as? HTTPURLResponse)?.statusCode else {
            throw ClientError.InvalidURLResponse
        }
        guard let data = response.data else {
            throw ClientError.UnexpectedResponseBody(nil)
        }
        return try {
            switch statusCode {
                case 200..<300:
                    return try JSONDecoder().decode(CreatePaymentResponse.self, from: data)
                default:
                    let requestErrorResponse = try JSONDecoder().decode(RequestErrorResponse.self, from: data)
                    throw ClientError.PaylikeServerError(
                        message: requestErrorResponse.message,
                        code: requestErrorResponse.code,
                        statusCode: statusCode,
                        errors: requestErrorResponse.errors)
            }
        }()
    }
}
