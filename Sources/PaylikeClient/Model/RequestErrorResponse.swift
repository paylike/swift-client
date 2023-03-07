import PaylikeRequest

/**
 * Defines the response of request errors
 */
public struct RequestErrorResponse : Decodable {
    public var message: String?
    public var errors: [String]?
    public var code: PaylikeErrorCodes?
    
    public init(
        message: String? = nil,
        errors: [String]? = nil,
        code: PaylikeErrorCodes? = nil
    ) {
        self.message = message
        self.errors = errors
        self.code = code
    }
}
