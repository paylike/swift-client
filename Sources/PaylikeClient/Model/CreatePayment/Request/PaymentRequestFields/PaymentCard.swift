/**
 * Describes card information for a payment request
 */
public struct PaymentCard : Encodable {
    /**
     * Tokenized card number
     */
    public var number: CardNumberToken
    /**
     * Tokenized CVC code
     */
    public var code: CardSecurityCodeToken
    /**
     * Expiry date, see at CardExpiry
     */
    public var expiry: CardExpiry
    
    public init(number: CardNumberToken, code: CardSecurityCodeToken, expiry: CardExpiry) {
        self.number = number
        self.code = code
        self.expiry = expiry
    }
}

/**
 * Aliased to exact token type
 */
public typealias CardNumberToken = CardDataToken

/**
 * Aliased to exact token type
 */
public typealias CardSecurityCodeToken = CardDataToken

/**
 * Describes the expiry date of the card, has input validation
 */
public struct CardExpiry : Encodable {
    public let month: Int
    public let year: Int
    
    public init(
        month: Int,
        year: Int
    ) throws {
        if (
            (month < 1 || month > 12)
            || ((year < 1 || year > 99) && (year < 2001 || year > 2099))
        ) {
            throw ClientError.InvalidExpiry(month: month, year: year)
        }
        self.month = month
        self.year = year <= 99
            ? year + 2000
            : year
    }
}
