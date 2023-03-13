/**
 * Tokenized response for both card and apple pay data
 */
public struct TokenizeResponse: Codable {
    public let token: String

    public init(token: String) {
        self.token = token
    }
}

/**
 * To distinguis from `ApplePayToken`
 */
public typealias CardDataToken = TokenizeResponse

/**
 * To distinguis from `CardDataToken`
 */
public typealias ApplePayToken = TokenizeResponse
