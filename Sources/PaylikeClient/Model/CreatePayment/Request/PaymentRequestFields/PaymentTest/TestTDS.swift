/**
 * Describes test scenarios for 3-D secure
 */
public struct TestTDS : Encodable {
    
    var challenge: Bool?
    
    var fingerprint: TDSFingerPrintOptions?
    
    var status: TDSStatusOptions?
    
    public init(
        challenge: Bool? = nil,
        fingerprint: TDSFingerPrintOptions? = nil,
        status: TDSStatusOptions? = nil
    ) {
        self.challenge = challenge
        self.fingerprint = fingerprint
        self.status = status
    }
}

public enum TDSFingerPrintOptions : String, Encodable {
    
    case SUCCESS = "success"
    
    case TIMEOUT = "timeout"
    
    case UNAVAILABLE = "unavailable"
}

public enum TDSStatusOptions : String, Encodable {
    
    case AUTHENTICATED = "authenticated"
    
    case ATTEMPTED = "attempted"
    
    case REJECTED = "rejected"
    
    case UNAVAILABLE = "unavailable"
}
