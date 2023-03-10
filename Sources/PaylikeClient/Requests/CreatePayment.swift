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
        
        loggingFn(LoggingFormat(
            t: "createPayment request:",
            createPaymentRequest: requestData
        ))
        
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
                    var createPaymentResponse = try self.checkCreatePaymentResponse(result.get())
                    
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
                                let stringData = try self.checkFormResponse(formResponse)
                                if !requestData.hints.isEmpty {
                                    var requestHints = requestData.hints
                                    if let responseHints = createPaymentResponse.hints,
                                       !responseHints.isEmpty {
                                        responseHints.forEach { responseHint in
                                            if !requestHints.contains(responseHint) {
                                                requestHints.append(responseHint)
                                            }
                                        }
                                    }
                                    createPaymentResponse.hints = requestHints
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
                        responseHints.forEach { responseHint in
                            if !requestData.hints.contains(responseHint) {
                                requestData.hints.append(responseHint)
                            }
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
        
        loggingFn(LoggingFormat(
            t: "createPayment request:",
            createPaymentRequest: requestData
        ))
        
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
        let (url, requestOptions) = try preparingData(path, requestData)

        let response = try await httpClient.sendRequest(
            to: url,
            withOptions: requestOptions
        )
        
        var createPaymentResponse = try self.checkCreatePaymentResponse(response)
        
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
            let stringData = try self.checkFormResponse(formResponse)
            if !requestData.hints.isEmpty {
                var requestHints = requestData.hints
                if let responseHints = createPaymentResponse.hints,
                   !responseHints.isEmpty {
                    responseHints.forEach { responseHint in
                        if !requestHints.contains(responseHint) {
                            requestHints.append(responseHint)
                        }
                    }
                }
                createPaymentResponse.hints = requestHints
            }
            return PaylikeClientResponse(with: createPaymentResponse, HTMLBody: stringData)
        }
        
        /*
         * Appends newly got hint to the `CreatePaymentRequest` then recursively start a new
         * `CreatePayment` iteration.
         */
        if let responseHints = createPaymentResponse.hints,
           !responseHints.isEmpty {
            var requestData = requestData
            responseHints.forEach { responseHint in
                if !requestData.hints.contains(responseHint) {
                    requestData.hints.append(responseHint)
                }
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
     * Used for creating and executing the payment flow but in a syncronous manner
     */
    @available(*, deprecated, message: "Highly not recommended, blocks the thread.")
    public func createPaymentSync(
        with requestData: CreatePaymentRequest,
        withCompletion handler: @escaping (Result<PaylikeClientResponse, Error>) -> Void
    ) -> Void {
        let semaphore = DispatchSemaphore(value: 0)
        createPayment(
            with: requestData
        ) { result in
            handler(result)
            semaphore.signal()
        }
        guard semaphore.wait(timeout: .now() + (self.timeoutInterval + 1)).self == .success else {
            handler(.failure(ClientError.Timeout))
            return
        }
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
    fileprivate func checkCreatePaymentResponse(_ response: PaylikeResponse) throws -> CreatePaymentResponse {
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
    
    fileprivate func checkFormResponse(_ response: PaylikeResponse) throws -> String {
        guard let statusCode = (response.urlResponse as? HTTPURLResponse)?.statusCode else {
            throw ClientError.InvalidURLResponse
        }
        guard let data = response.data else {
            throw ClientError.UnexpectedResponseBody(nil)
        }
        return try {
            switch statusCode {
                case 200..<300:
                    guard let data = response.data else {
                        throw ClientError.NoResponseBody
                    }
                    guard let stringData = String(data: data, encoding: .utf8) else {
                        throw ClientError.UnknownError // @TODO: create error for case
                    }
                    return stringData
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
