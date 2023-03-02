import Foundation
import PaylikeRequest

/**
 * Extension for tokenization functions with completion handler patter
 */
extension PaylikeClient {
    
    /**
     * Tokenization API with
     * - Apple Pay data
     */
    public func tokenize(
        applePayData data: TokenizeApplePayDataRequest,
        withCompletion handler: @escaping (Result<ApplePayToken, Error>) -> Void
    ) -> Void {
        self.tokenize(from: data, withCompletion: handler)
    }
    /**
     * Tokenization API with
     * - card data
     */
    public func tokenize(
        cardData data: TokenizeCardDataRequest,
        withCompletion handler: @escaping (Result<CardDataToken, Error>) -> Void
    ) -> Void {
        self.tokenize(from: data, withCompletion: handler)
    }
    /**
     * Tokenization function for both
     * - tokenize(applePayData data: TokenizeApplePayDataRequest)
     * - tokenize(cardData data: TokenizeCardDataRequest)
     * APIs
     */
    fileprivate func tokenize(
        from data: TokenizeRequest,
        withCompletion handler: @escaping (Result<TokenizeResponse, Error>) -> Void
    ) -> Void {
        do {
            /*
             * Get URL and Request options
             */
            let endpointURL = try getTokenizeEndpointURL(from: data)
            let requestOptions = initRequestOptions(withData: try JSONEncoder().encode(data))
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
            self.loggingFn(loggingFormat)
            /*
             * Execute request
             */
            httpClient.sendRequest(
                to: endpointURL,
                withOptions: requestOptions
            ) { result in
                do {
                    let response = try result.get()
                    guard let data = response.data else {
                        handler(.failure(ClientError.NoResponseBody))
                        return
                    }
                    let tokenizeResponse = try JSONDecoder().decode(
                        TokenizeResponse.self,
                        from: data
                    )
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
     * Sync tokenization API with
     * - Apple Pay data
     */
    public func tokenizeSync(
        applePayData data: TokenizeApplePayDataRequest,
        withCompletion handler: @escaping (Result<ApplePayToken, Error>) -> Void
    ) -> Void {
        self.tokenizeSync(from: data, withCompletion: handler)
    }
    /**
     * Sync tokenization API with
     * - card data
     */
    public func tokenizeSync(
        cardData data: TokenizeCardDataRequest,
        withCompletion handler: @escaping (Result<CardDataToken, Error>) -> Void
    ) -> Void {
        self.tokenizeSync(from: data, withCompletion: handler)
    }
    /**
     * Tokenization function for both
     * - tokenize(applePayData data: TokenizeApplePayDataRequest)
     * - tokenize(cardData data: TokenizeCardDataRequest)
     * APIs     */
#warning("Highly not recommended, blocks the thread.")
    fileprivate func tokenizeSync(
        from data: TokenizeRequest,
        withCompletion handler: @escaping (Result<TokenizeResponse , Error>) -> Void
    )  -> Void {
        let semaphore = DispatchSemaphore(value: 0)
        self.tokenize(
            from: data
        ) { result in
            handler(result)
            semaphore.signal()
        }
        semaphore.wait()
    }
    
    /**
     * Async tokenization API with
     * - Apple Pay data
     */
    public func tokenize(applePayData data: TokenizeApplePayDataRequest) async throws -> ApplePayToken {
        return try await self.tokenize(from: data)
    }
    /**
     * Async tokenization API with
     * - card data
     */
    public func tokenize(cardData data: TokenizeCardDataRequest) async throws -> CardDataToken {
        return try await self.tokenize(from: data)
    }
    /**
     * Tokenization function for both
     * - tokenize(applePayData data: TokenizeApplePayDataRequest)
     * - tokenize(cardData data: TokenizeCardDataRequest)
     * APIs
     */
    @available(iOS 13.0, macOS 10.15, *)
    fileprivate func tokenize(
        from data: TokenizeRequest
    ) async throws -> TokenizeResponse {
        return try await withCheckedThrowingContinuation { continuation in
            self.tokenize(from: data) { response in
                continuation.resume(with: response)
            }
        }
    }
    
    /**
     * Sync tokenization API with
     * - Apple Pay data
     */
    public func tokenizeSync(applePayData data: TokenizeApplePayDataRequest) async throws -> ApplePayToken {
        return try await self.tokenizeSync(from: data)
    }
    /**
     * Sync tokenization API with
     * - card data
     */
    public func tokenizeSync(cardData data: TokenizeCardDataRequest) async throws -> CardDataToken {
        return try await self.tokenizeSync(from: data)
    }
    /**
     * Sync Tokenization function for both
     * - tokenize(applePayData data: TokenizeApplePayDataRequest)
     * - tokenize(cardData data: TokenizeCardDataRequest)
     * APIs
     */
    @available(iOS 13.0, macOS 10.15, *)
    fileprivate func tokenizeSync(
        from data: TokenizeRequest
    ) async throws -> TokenizeResponse {
        return try await withCheckedThrowingContinuation { continuation in
            self.tokenizeSync(from: data) { response in
                continuation.resume(with: response)
            }
        }
    }
}
