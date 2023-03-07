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
//    public var isHTML: Bool
    
    /**
     * Initializes a new client response with a finalized CreatePaymentResponse
     */
    public init(
        with response: CreatePaymentResponse
    ) {
        self.createPaymentResponse = response
//        self.isHTML = false
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
        self.createPaymentResponse = response
        self.HTMLBody = HTMLBody
//        self.isHTML = true
    }
}
