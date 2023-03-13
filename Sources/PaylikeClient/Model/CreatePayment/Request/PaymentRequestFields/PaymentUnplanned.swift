/**
 * Flag the types of unplanned payments the card will be used for. The supported types are:
 * - costumer (initiated by the customer from your website/application)
 * - merchant (initiated by the merchant or an off-site customer)
 *
 * This is required for unplanned subsequent payments to ensure
 * compliance and high approval rates.
 */
public struct PaymentUnplanned: Encodable {
    public let constumer: Bool?
    public let merchant: Bool?

    public init(
        costumer: Bool
    ) {
        constumer = costumer
        merchant = nil
    }

    public init(
        merchant: Bool
    ) {
        constumer = nil
        self.merchant = merchant
    }
}
