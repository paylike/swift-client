/**
 * @TODO: Docs
 */
internal struct LoggingFormat : Encodable {
    public var t: String
    public var tokenizeCardDataRequest: TokenizeCardDataRequest?
    public var tokenizeApplePayDataRequest: TokenizeApplePayDataRequest?
    public var createPaymentRequest: CreatePaymentRequest?
}

