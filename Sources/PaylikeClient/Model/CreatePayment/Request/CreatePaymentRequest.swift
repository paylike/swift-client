import AnyCodable

/**
 * All possible options for creating a payment request.
 *
 * More information: https://github.com/paylike/api-reference/blob/main/payments/index.md
 */
public struct CreatePaymentRequest : Encodable {
    /**
     * This is the public key for the merchant
     */
    public var integration: PaymentIntegration
    /**
     * Optional,
     * Card information for the payment. Either card or apple pay token should be provided
     */
    public var card: PaymentCard?
    /**
     * Optional,
     * This field should be an Apple Pay token obtained from
     */
    public var applepay: ApplePayToken?
    /**
     * Optional,
     * This is the (positive) amount immediately due for reservation on the customer's payment instrument.
     */
    public var amount: PaymentAmount?
    /**
     * Optional,
     * Used for testing scenarios in the sandbox environment
     */
    public var test: PaymentTest?
    /**
     * Optional,
     * If none is provided the merchant's default is used
     */
    public var text: String?
    
    /**
     * Optional,
     * Custom encodable object, completely arbitrary.
     * Depends on the 3rd party library AnyCodable
     */
    public var custom: AnyEncodable?
    /**
     * Optional,
     * This is required for unplanned subsequent payments to ensure compliance and high approval rates.
     */
    public var unplanned: PaymentUnplanned?
    /**
     * Optional,
     * A set of plans to execute (used for subscription)
     */
    public var plan: [PaymentPlan]?
    /**
     * Optional,
     * Collected hints to attach the request. It is required to execute the payment and TDS flow
     */
    public var hints = [String]()
    
    /**
     * Initialization with only merchantID
     */
    public init(
        merchantID integration: PaymentIntegration
    ) {
        self.applepay = nil
        self.card = nil
        self.integration = integration
    }
    
    /**
     * Initialization with
     * - merchantID
     * - apple pay token
     */
    public init(
        with applePayToken: ApplePayToken,
        merchantID integration: PaymentIntegration
    ) {
        self.applepay = applePayToken
        self.card = nil
        self.integration = integration
    }

    /**
     * Initialization with
     * - merchantID
     * - card data
     */
    public init(
        with cardData: PaymentCard,
        merchantID integration: PaymentIntegration
    ) {
        self.applepay = nil
        self.card = cardData
        self.integration = integration
    }
}
