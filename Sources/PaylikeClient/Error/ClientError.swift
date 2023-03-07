import Foundation
import PaylikeRequest

/**
 * Describes errors that can happen in the client
 */
public enum ClientError : Error {
    case NotImplemented
    case UnknownError

    case PaylikeServerError(
        message: String?,
        code: PaylikeErrorCodes?,
        statusCode: Int?,
        errors: [String]?
    )
    /**
     * @TODO: endpoint url errors
     */
    case URLParsingFailed(_ host: String)
    case InvalidTokenizeData(_ data: TokenizeRequest)
    /**
     * @TODO: model errors
     * Invalid money number error
     */
    case UnsafeNumber(number: Double)
    /**
     * Invalid expiry date error
     */
    case InvalidExpiry(month: Int, year: Int)
    
    /**
     * Happens when a response has an unexpected body
     */
    case UnexpectedResponseBody(_ body: Data?)
    case NoResponseBody
    /**
     * Describes an unexpected development during the payment challenge execution
     */
    case UnexpectedPaymentFlowError(payment: CreatePaymentRequest, hints: Set<String>, body: CreatePaymentResponse?)
}
