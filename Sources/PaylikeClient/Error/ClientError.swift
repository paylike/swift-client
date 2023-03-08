import Foundation
import PaylikeRequest

/**
 * Describes errors that can happen in the client
 */
public enum ClientError : Error {
    
    case NotImplementedError
    
    case UnknownError

    /**
     * Thrown when Paylike server responds with some error
     */
    case PaylikeServerError(
        message: String?,
        code: PaylikeErrorCodes?,
        statusCode: Int?,
        errors: [String]?
    )
    
    /**
     * Thrown when `tokenizeSync(...)` reaches timeout threshold
     */
    case Timeout
    
    /**
     * Thrown when URL or URLComponent initialization fails
     */
    case URLParsingFailed
    
    case JSONParsingFailed
    
    case InvalidTokenizeData(_ data: TokenizeRequest)
    
    /**
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

    case InvalidURLResponse
    /**
     * Describes an unexpected development during the payment challenge execution
     */
    case UnexpectedPaymentFlowError(payment: CreatePaymentRequest, body: CreatePaymentResponse?)
}
