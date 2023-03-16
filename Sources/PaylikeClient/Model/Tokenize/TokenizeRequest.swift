/**
 * Common protocol for both tokenize request types
 */
public protocol TokenizeRequest: Encodable {}

/**
 * To tokenize apple pay public key
 */
public struct TokenizeApplePayDataRequest: TokenizeRequest {
    public let token: String

    public init(token: String) {
        self.token = token
    }
}

/**
 * To tokenize card data
 */
public struct TokenizeCardDataRequest: TokenizeRequest {
    public let type: CardDataType
    public let value: String

    public init(type: CardDataType, value: String) {
        self.type = type
        self.value = value
    }
}
