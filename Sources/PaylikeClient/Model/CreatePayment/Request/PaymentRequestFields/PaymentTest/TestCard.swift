/**
 * Describes test scenarios for the card
 */
public struct TestCard : Encodable {
    
    var balance: PaymentAmount?
    
    var code: CardCodeOptions?
    
    var limit: PaymentAmount?
    
    var scheme: CardSchemeOptions?
    
    var status: CardStatusOptions?
}

public enum CardCodeOptions : String, Encodable {
    
    case INVALID = "invalid"
    
    case VALID = "valid"
}

public enum CardSchemeOptions : String, Encodable {
    
    case SUPPORTED = "supported"
    
    case UNKNOWN = "unknown"
    
    case UNSUPPORTED = "unsuppported"
}

public enum CardStatusOptions : String, Encodable {
    
    case DISABLED = "disabled"
    
    case EXPIRED = "expired"
    
    case INVALID = "invalid"
    
    case LOST = "lost"
    
    case VALID = "valid"
}
