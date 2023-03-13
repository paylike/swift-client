import Foundation

/**
 * Generates URL for Tokenize request
 */
internal func getTokenizeEndpointURL(
    from data: TokenizeRequest
) throws -> URL {
    switch data {
    case is TokenizeApplePayDataRequest:
        guard let url = URL(string: Hosts.APPLE_PAY_VAULT.rawValue) else {
            throw ClientError.URLParsingFailed
        }
        return url
    case is TokenizeCardDataRequest:
        guard let url = URL(string: Hosts.CARD_DATA_VAULT.rawValue) else {
            throw ClientError.URLParsingFailed
        }
        return url
    default:
        throw ClientError.InvalidTokenizeData(data)
    }
}

/**
 * Generates URL for CreatePayment request
 */
internal func getPaymentEndpointURL() throws -> URL {
    guard let url = URL(string: Hosts.CREATE_PAYMENT_API.rawValue) else {
        throw ClientError.URLParsingFailed
    }
    return url
}

/**
 * Describes URL-s
 */
internal enum Hosts: String {
    /**
     * URL for Apple Pay tokenization
     */
    case APPLE_PAY_VAULT = "https://applepay.paylike.io/token"
    /**
     * URL for card data tokenization
     */
    case CARD_DATA_VAULT = "https://vault.paylike.io"
    /**
     * Root URL for CreatePayment request
     */
    case CREATE_PAYMENT_API = "https://b.paylike.io"
}
