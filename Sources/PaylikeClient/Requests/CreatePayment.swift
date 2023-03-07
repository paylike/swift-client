import Foundation
import PaylikeRequest

/**
 * Extension for payment creation functions
 */
extension PaylikeClient {
    
    /**
     * Used for creating and executing the payment flow
     */
    @available(iOS 13.0, macOS 10.15, *)
    public func createPayment(
        with requestData: inout CreatePaymentRequest,
        path: String? = "/payments"
    ) async throws -> PaylikeClientResponse {
        
        /*
         * Logging request
         */
        loggingFn(LoggingFormat(
            t: "createPayment request:",
            createPaymentRequest: requestData
        ))
        
        /*
         * Preparring `url` and `requestOptions` for `sendRequest(to:withOptions)`
         * Can be function...
         * (path, requestData) -> (url, requestOptions)
         */
        guard var urlComponent = try URLComponents(url: getPaymentEndpointURL(), resolvingAgainstBaseURL: false) else {
            throw ClientError.URLParsingFailed
        }
        urlComponent.path = path ?? ""
        guard let url = urlComponent.url else {
            throw ClientError.URLParsingFailed
        }
        let encodedData = try JSONEncoder().encode(requestData)
        let requestOptions = initRequestOptions(withData: encodedData)
        
        
        /*
         * Execute request
         */
        let response = try await httpClient.sendRequest(
            to: url,
            withOptions: requestOptions
        )
        
        /*
         * Check on the response
         */
        guard let statusCode = (response.urlResponse as? HTTPURLResponse)?.statusCode else {
            throw ClientError.InvalidURLResponse
        }
        guard let data = response.data else {
            throw ClientError.UnexpectedResponseBody(nil)
        }
        
        var createPaymentResponse = try {
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
        
        /*
         * Challenge process
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
        
        /*
         * IFrame process
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
            return try await createPayment(with: &requestData)
        }
        
        /*
         * Returns final `PaylikeClientResponse`
         */
        return PaylikeClientResponse(
            with: createPaymentResponse
        )
    }
    
    
    /**
     * Used for creating and executing the payment flow
     */
    public func createPayment(
        with requestData: inout CreatePaymentRequest,
        path: String? = "/payment",
        withCompletion handler: @escaping (Result<PaylikeClientResponse, Error>) -> Void
    ) -> Void {
        handler(.failure(ClientError.NotImplementedError))
    }
}
