import Foundation

/**
 Describes errors that can happen in the client library
 */
public enum PaylikeClientErrors : Error {
    /**
     Happens when a response has an unexpected body
     */
    case UnexpectedResponseBody(body: Data?)
    /**
     Describes an unexpected development during the payment challenge execution
     */
    case UnexpectedPaymentFlowError(payment: PaymentRequestDTO, hints: Set<String>, body: PaymentFlowResponse?)
}
