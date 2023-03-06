/**
 * For mock purposes
 */

internal let MockScheme = "http"

internal let MockHost = "localhost"

internal let MockPort = 8080

internal enum MockEndpoints : String {
    case APPLE_PAY_VAULT = "/tokenizeApplePay"
    case CARD_DATA_VAULT = "/tokenizeCardData"
    case CREATE_PAYMENT_API = "/createPayment"
}
