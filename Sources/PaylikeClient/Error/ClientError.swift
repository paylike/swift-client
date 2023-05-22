import Foundation
import PaylikeRequest

/**
 * Describes errors regarding the Client and it's close components
 */
public enum ClientError: Error, LocalizedError {
    
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
    
    /**
     * Localized text of the error messages
     */
    // @TODO: Change text literals to `NSLocalizedString`s
    // @TODO: Generate localized string file in Xcode
    public var errorDescription: String? {
        switch self {
            case .UnknownError:
                return "UnknownError"
            case .PaylikeServerError(message: let message, code: let code, statusCode: let statusCode, errors: let errors):
                return "Paylike server error has occured. StatusCode: \(statusCode ?? -1), Code: \(code?.rawValue ?? "-") , Errors: \(errors?.joined(separator: " ") ?? "-"), Message: \(message ?? "-")."
            case .Timeout:
                return "Timeout"
            case .URLParsingFailed:
                return "URLParsingFailed"
            case .JSONParsingFailed:
                return "JSONParsingFailed"
            case .InvalidTokenizeData(data: let data):
                return "Invalid TokenizeData: \(data)"
            case .UnsafeNumber(number: let number):
                return "Unsafe number: \(number)"
            case .InvalidExpiry(month: let month, year: let year):
                return "Invalid expiry date: \(month)/\(year)"
            case .UnexpectedResponseBody(body: _):
                return "Unexpected response body"
            case .NoResponseBody:
                return "No response body"
            case .InvalidURLResponse:
                return "Invalid URL response"
            case .UnexpectedPaymentFlowError(payment: _, body: _):
                return "Unexpected payment flow"
        }
    }
}
