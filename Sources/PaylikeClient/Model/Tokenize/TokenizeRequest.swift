/**
 * Common protocol for both tokenize request types
 */
public protocol TokenizeRequest: Encodable {}

/**
 * To tokenize apple pay public key
 */
public struct TokenizeApplePayDataRequest: TokenizeRequest {
    public let token: String
}

/**
 * To tokenize card data
 */
public struct TokenizeCardDataRequest: TokenizeRequest {
    public let type: CardDataType
    public let value: String
}
