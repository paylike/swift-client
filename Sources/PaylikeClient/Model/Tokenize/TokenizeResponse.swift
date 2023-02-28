/**
 * Tokenized response for both card and apple pay data
 */
public struct TokenizeResponse: Codable {
    public let token: String
}

/**
 *
 */
public typealias CardDataToken = TokenizeResponse

/**
 * 
 */
public typealias ApplePayToken = TokenizeResponse
