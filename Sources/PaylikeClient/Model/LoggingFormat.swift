/**
 * Describes information for a log line
 */
struct LoggingFormat: Encodable {
    var t: String
    var tokenizeCardDataRequest: TokenizeCardDataRequest?
    var tokenizeApplePayDataRequest: TokenizeApplePayDataRequest?
    var createPaymentRequest: CreatePaymentRequest?
}
