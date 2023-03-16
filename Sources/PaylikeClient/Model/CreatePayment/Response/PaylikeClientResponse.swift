/**
 * Describes a response recieved during the payment transaction process
 */
public struct PaylikeClientResponse {
    /**
     * Stores the exact response body
     */
    public var createPaymentResponse: CreatePaymentResponse

    /**
     * Stores the optionally received HTML description
     */
    public var HTMLBody: String?

    /**
     * Initializes a new client response with a finalized CreatePaymentResponse
     */
    public init(
        with response: CreatePaymentResponse
    ) {
        createPaymentResponse = response
    }

    /**
     * Initializes a new client response with
     * - CreatePaymentResponse
     * - HTML body
     */
    public init(
        with response: CreatePaymentResponse,
        HTMLBody: String
    ) {
        createPaymentResponse = response
        self.HTMLBody = HTMLBody
    }
}
