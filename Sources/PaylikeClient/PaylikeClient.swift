import PaylikeRequest


/**
 * Describing the necessary function for the client
 */
public protocol Client {
    /**
     * Client ID sent to the API to identify the client connection interface
     */
    var clientID: String { get set }
    /**
     * Underlying httpClient implementation used
     */
    var httpClient: HTTPClient { get set }
    /**
     * Used for logging, called when the request is constructed
     */
    var loggingFn: (Encodable) -> Void { get set }
    /**
     * Calling the tokenization API
     */
    func tokenize(
        applePayData data: TokenizeApplePayDataRequest,
        withCompletion handler: @escaping (Result<ApplePayToken, Error>) -> Void
    ) -> Void
    /**
     * Calling the tokenization API
     */
    func tokenize(
        cardData data: TokenizeCardDataRequest,
        withCompletion handler: @escaping (Result<CardDataToken, Error>) -> Void
    ) -> Void
    /**
     * Calling the tokenization API
     */
    func tokenize(applePayData data: TokenizeApplePayDataRequest) async throws -> ApplePayToken
    /**
     * Calling the tokenization API
     */
    func tokenize(cardData data: TokenizeCardDataRequest) async throws -> CardDataToken
    /**
     * Used for creating and executing the payment flow
     */
    func createPayment(
        with requestData: CreatePaymentRequest,
        withCompletion handler: @escaping (Result<PaylikeClientResponse, Error>) -> Void
    ) -> Void
    /**
     * Same functionality as `createPayment(..., withCompletion:)` but with async await syntax features
     */
    func createPayment(with requestData: CreatePaymentRequest) async throws -> PaylikeClientResponse
}

/**
 * Handles high level requests toward the Paylike APIs
 */
public final class PaylikeClient: Client {
    /**
     * Client ID sent to the API to identify the client connection interface
     */
    public var clientID: String
    /**
     * Timeout interval for requests in seconds
     */
    public var timeoutInterval = 20.0
    /**
     * Underlying httpClient implementation used
     */
    public var httpClient: HTTPClient = PaylikeHTTPClient()
    /**
     * Used for logging, called when the request is constructed
     */
    public var loggingFn: (Encodable) -> Void = { obj in
        print("Client logger:", terminator: " ")
        debugPrint(obj)
    }

    /**
     * Initialization with generated clientId
     */
    public init() {
        clientID = PaylikeClient.generateClientID()
    }

    /**
     * Initialization with custom clientId
     */
    public init(
        clientID: String
    ) {
        self.clientID = "swift-1-\(clientID)"
    }

    /**
     * Generates a new client ID to identify requests in the API
     */
    static func generateClientID() -> String {
        let chars = "AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890"
        let id = (0 ..< 6).map { _ in
            String(chars.randomElement()!)
        }.joined()
        return "swift-1-\(id)"
    }
}
