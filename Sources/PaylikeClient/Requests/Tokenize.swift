import Foundation
import PaylikeRequest

/**
 * Extension for tokenization functions
 */
public extension PaylikeClient {
    /**
     * Calling the tokenization API
     */
    func tokenize(
        applePayData data: TokenizeApplePayDataRequest,
        withCompletion handler: @escaping (Result<ApplePayToken, Error>) -> Void
    ) {
        tokenize(from: data, withCompletion: handler)
    }

    /**
     * Calling the tokenization API
     */
    func tokenize(
        cardData data: TokenizeCardDataRequest,
        withCompletion handler: @escaping (Result<CardDataToken, Error>) -> Void
    ) {
        tokenize(from: data, withCompletion: handler)
    }

    /**
     * Tokenization function for both
     * - tokenize(applePayData data: TokenizeApplePayDataRequest)
     * - tokenize(cardData data: TokenizeCardDataRequest)
     * APIs
     */
    private func tokenize(
        from data: TokenizeRequest,
        withCompletion handler: @escaping (Result<TokenizeResponse, Error>) -> Void
    ) {
        do {
            /*
             * Get URL and Request options
             */
            let endpointURL = try getTokenizeEndpointURL(from: data)
            let requestOptions = try initRequestOptions(withData: JSONEncoder().encode(data))
            /*
             * Logging
             */
            var loggingFormat = LoggingFormat(t: "tokenize request:")
            switch Mirror(reflecting: data).subjectType {
            case is TokenizeApplePayDataRequest.Type:
                if let loggerData = data as! TokenizeApplePayDataRequest? {
                    loggingFormat.tokenizeApplePayDataRequest = loggerData
                }
            case is TokenizeCardDataRequest.Type:
                if let loggerData = data as! TokenizeCardDataRequest? {
                    loggingFormat.tokenizeCardDataRequest = loggerData
                }
            default:
                break
            }
            loggingFn(loggingFormat)
            /*
             * Execute request
             */
            httpClient.sendRequest(
                to: endpointURL,
                withOptions: requestOptions
            ) { result in
                do {
                    let response = try result.get()
                    let tokenizeResponse = try self.checkTokenizeResponse(response)
                    handler(.success(tokenizeResponse))
                } catch {
                    handler(.failure(error))
                }
            }
        } catch {
            handler(.failure(error))
        }
    }

    /**
     * Calling the tokenization API with async syntax
     */
    func tokenize(applePayData data: TokenizeApplePayDataRequest) async throws -> ApplePayToken {
        try await tokenize(from: data)
    }

    /**
     * Calling the tokenization API with async syntax
     */
    func tokenize(cardData data: TokenizeCardDataRequest) async throws -> CardDataToken {
        try await tokenize(from: data)
    }

    /**
     * Tokenization function for both
     * - tokenize(applePayData data: TokenizeApplePayDataRequest)
     * - tokenize(cardData data: TokenizeCardDataRequest)
     * APIs
     */
    @available(iOS 13.0, macOS 10.15, *)
    private func tokenize(
        from data: TokenizeRequest
    ) async throws -> TokenizeResponse {
        try await withCheckedThrowingContinuation { continuation in
            self.tokenize(from: data) { response in
                continuation.resume(with: response)
            }
        }
    }

    /**
     * Sync calling the tokenization API
     */
    @available(*, deprecated, message: "Highly not recommended, blocks the thread.")
    func tokenizeSync(
        applePayData data: TokenizeApplePayDataRequest,
        withCompletion handler: @escaping (Result<ApplePayToken, Error>) -> Void
    ) {
        tokenizeSync(from: data, withCompletion: handler)
    }

    /**
     * Sync calling the tokenization API
     */
    @available(*, deprecated, message: "Highly not recommended, blocks the thread.")
    func tokenizeSync(
        cardData data: TokenizeCardDataRequest,
        withCompletion handler: @escaping (Result<CardDataToken, Error>) -> Void
    ) {
        tokenizeSync(from: data, withCompletion: handler)
    }

    /**
     * Tokenization function for both
     * - tokenize(applePayData data: TokenizeApplePayDataRequest)
     * - tokenize(cardData data: TokenizeCardDataRequest)
     * APIs     */
    @available(*, deprecated, message: "Highly not recommended, blocks the thread.")
    private func tokenizeSync(
        from data: TokenizeRequest,
        withCompletion handler: @escaping (Result<TokenizeResponse, Error>) -> Void
    ) {
        let semaphore = DispatchSemaphore(value: 0)
        tokenize(
            from: data
        ) { result in
            handler(result)
            semaphore.signal()
        }
        guard semaphore.wait(timeout: .now() + (timeoutInterval + 1)).self == .success else {
            handler(.failure(ClientError.Timeout))
            return
        }
    }

    private func checkTokenizeResponse(_ response: PaylikeResponse) throws -> TokenizeResponse {
        guard let statusCode = (response.urlResponse as? HTTPURLResponse)?.statusCode else {
            throw ClientError.InvalidURLResponse
        }
        guard let data = response.data else {
            throw ClientError.UnexpectedResponseBody(nil)
        }
        return try {
            switch statusCode {
            case 200 ..< 300:
                return try JSONDecoder().decode(TokenizeResponse.self, from: data)
            default:
                let requestErrorResponse = try JSONDecoder().decode(RequestErrorResponse.self, from: data)
                throw ClientError.PaylikeServerError(
                    message: requestErrorResponse.message,
                    code: requestErrorResponse.code,
                    statusCode: statusCode,
                    errors: requestErrorResponse.errors
                )
            }
        }()
    }
}
