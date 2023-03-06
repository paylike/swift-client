/**
 * Describes the necessary merchantID to successfully make request to the backend
 */
public struct PaymentIntegration : Encodable {
    public var key: String
    
    /**
     * Initialization with named parameter to clarify usage
     */
    public init(merchantId key: String) {
        self.key = key
    }
}
