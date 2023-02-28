import PaylikeRequest

/**
 * Handles high level requests toward the Paylike APIs
 */
public final class PaylikeClient {
    
    /**
     * Generates a new client ID to identify requests in the API
     */
    static func generateClientID() -> String {
        let chars = "AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890"
        let id = (0..<6).map { _ in
            String(chars.randomElement()!)
        }
        return "swift-1-\(id.joined())"
    }
    
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
    internal var httpClient: HTTPClient = PaylikeHTTPClient()
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
        self.clientID = PaylikeClient.generateClientID()
    }
    /**
     * Initialization with custom clientId
     */
    public init(
        clientId: String
    ) {
        self.clientID = "swift-1-\(clientId)"
    }
}
