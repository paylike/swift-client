import Foundation
import PaylikeRequest

/**
 * Extension for tokenization functions with async await pattern
 */
@available(swift 5.5)
extension PaylikeClient {
    
    /**
     * Async tokenization API with
     * - Apple Pay data
     */
    public func tokenize(applePayData data: TokenizeApplePayDataRequest) async throws -> ApplePayToken {
        return try await tokenize(from: data)
    }
    
    /**
     * Async tokenization API with
     * - card data
     */
    public func tokenize(cardData data: TokenizeCardDataRequest) async throws -> CardDataToken {
        return try await tokenize(from: data)
    }
    
    /**
     * Tokenization function for both
     * - tokenize(applePayData data: TokenizeApplePayDataRequest)
     * - tokenize(cardData data: TokenizeCardDataRequest)
     * APIs
     */
    fileprivate func tokenize(
        from data: TokenizeRequest
    ) async throws -> TokenizeResponse {
        
        let (endpointURL, requestOptions) = try requestInitialization(data)
        
        log(data)
        
        /**
         * Try and execute request
         */
        let response = try await httpClient.sendRequest(
            to: endpointURL,
            withOptions: requestOptions
        )
        
        guard let statusCode = (response.urlResponse as? HTTPURLResponse)?.statusCode else {
            throw ClientError.UnknownError // @TODO: what error here?
        }
        guard let data = response.data else {
            throw ClientError.NoResponseBody
        }
        switch statusCode {
            case 200..<300:
                return try JSONDecoder().decode(
                    TokenizeResponse.self,
                    from: data
                )
            default:
                let requestErrorResponse = try JSONDecoder().decode(RequestErrorResponse.self, from: data)
                throw ClientError.PaylikeServerError(
                    message: requestErrorResponse.message,
                    code: requestErrorResponse.code,
                    statusCode: statusCode,
                    errors: requestErrorResponse.errors)
        }
    }
    
    /**
     * Sync tokenization API with
     * - Apple Pay data
     */
    public func tokenizeSync(applePayData data: TokenizeApplePayDataRequest) throws -> ApplePayToken {
        return try tokenizeSync(from: data)
    }
    
    /**
     * Sync tokenization API with
     * - card data
     */
    public func tokenizeSync(cardData data: TokenizeCardDataRequest) throws -> CardDataToken {
        return try tokenizeSync(from: data)
    }
    
    /**
     * Tokenization function for both
     * - tokenize(applePayData data: TokenizeApplePayDataRequest)
     * - tokenize(cardData data: TokenizeCardDataRequest)
     * APIs     */
    fileprivate func tokenizeSync(
        from data: TokenizeRequest
    ) throws -> TokenizeResponse {
        let semaphore = DispatchSemaphore(value: 0)
        let mainQueue = DispatchQueue.main
        let key = DispatchSpecificKey<TokenizeResponse>()
        Task {
            mainQueue.setSpecific(key: key, value: try await tokenize(from: data))
            semaphore.signal()
        }
        semaphore.wait()
        guard let response = mainQueue.getSpecific(key: key) else {
            throw ClientError.UnknownError // @TODO: adequate error
        }
        return response
    }
    
    /**
     * URL and request initialization
     */
    fileprivate func requestInitialization(_ data: TokenizeRequest) throws -> (endpointURL: URL, requestOptions: RequestOptions) {
        let endpointURL = try getTokenizeEndpointURL(from: data)
        let requestOptions = initRequestOptions(withData: try JSONEncoder().encode(data))
        return (endpointURL, requestOptions)
    }
    
    /**
     * Logging based on actual type
     */
    fileprivate func log(_ data: TokenizeRequest) {
        switch Mirror(reflecting: data).subjectType {
            case is TokenizeApplePayDataRequest.Type:
                if let loggerData = data as! TokenizeApplePayDataRequest? {
                    loggingFn(LoggingFormat(
                        t: "tokenize request:",
                        tokenizeApplePayDataRequest: loggerData
                    ))
                }
            case is TokenizeCardDataRequest.Type:
                if let loggerData = data as! TokenizeCardDataRequest? {
                    loggingFn(LoggingFormat(
                        t: "tokenize request:",
                        tokenizeCardDataRequest: loggerData
                    ))
                }
            default:
                break // no logging
        }
    }
}

/**
 * Extension for tokenization functions with completion handler patter
 */
@available(swift, deprecated: 5.5, message: "Use async version if possible")
extension PaylikeClient {
    
    /**
     * Tokenization API with
     * - Apple Pay data
     */
    public func tokenize(
        applePayData data: TokenizeApplePayDataRequest,
        withCompletion handler: @escaping (Result<ApplePayToken, Error>) -> Void
    ) -> Void {
        self.tokenize(
            from: data,
            withCompletion: handler
        )
    }
    
    /**
     * Tokenization API with
     * - card data
     */
    public func tokenize(
        cardData data: TokenizeCardDataRequest,
        withCompletion handler: @escaping (Result<CardDataToken, Error>) -> Void
    ) -> Void {
        self.tokenize(
            from: data,
            withCompletion: handler
        )
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
            
            let (endpointURL, requestOptions) = try requestInitialization(data)
            
            log(data)
            
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
        tokenizeSync(
            from: data,
            withCompletion: handler
        )
    }
    
    /**
     * Sync tokenization API with
     * - card data
     */
    public func tokenizeSync(
        cardData data: TokenizeCardDataRequest,
        withCompletion handler: @escaping (Result<CardDataToken, Error>) -> Void
    ) -> Void {
        tokenizeSync(
            from: data,
            withCompletion: handler
        )
    }
    
    /**
     * Tokenization function for both
     * - tokenize(applePayData data: TokenizeApplePayDataRequest)
     * - tokenize(cardData data: TokenizeCardDataRequest)
     * APIs     */
    fileprivate func tokenizeSync(
        from data: TokenizeRequest,
        withCompletion handler: @escaping (Result<TokenizeResponse , Error>) -> Void
    )  -> Void {
        let semaphore = DispatchSemaphore(value: 0)
        tokenize(
            from: data
        ) { result in
            handler(result)
            semaphore.signal()
        }
        semaphore.wait()
    }
}
