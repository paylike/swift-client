import PaylikeRequest

/**
 * Defines the response of request errors
 */
public struct RequestErrorResponse : Decodable {
    var message: String?
    var errors: [String]?
    var code: PaylikeErrorCodes?
}
