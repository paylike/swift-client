/**
 * Describes test scenarios for the card
 */
public struct TestCard: Encodable {
    var balance: PaymentAmount?

    var code: CardCodeOptions?

    var limit: PaymentAmount?

    var scheme: CardSchemeOptions?

    var status: CardStatusOptions?

    public init(
        balance: PaymentAmount? = nil,
        code: CardCodeOptions? = nil,
        limit: PaymentAmount? = nil,
        scheme: CardSchemeOptions? = nil,
        status: CardStatusOptions? = nil
    ) {
        self.balance = balance
        self.code = code
        self.limit = limit
        self.scheme = scheme
        self.status = status
    }
}

public enum CardCodeOptions: String, Encodable {
    case INVALID = "invalid"

    case VALID = "valid"
}

public enum CardSchemeOptions: String, Encodable {
    case SUPPORTED = "supported"

    case UNKNOWN = "unknown"

    case UNSUPPORTED = "unsuppported"
}

public enum CardStatusOptions: String, Encodable {
    case DISABLED = "disabled"

    case EXPIRED = "expired"

    case INVALID = "invalid"

    case LOST = "lost"

    case VALID = "valid"
}
