/**
 * Necessary object for testing on the Paylike ecosystem
 *
 * Can define empty object for solely test without any preset scenario
 */
public struct PaymentTest : Encodable {
    
    var card: TestCard?
    
    var fingerPrint: FingerPrintOptions?
    
    var tds: TestTDS?
}

public enum FingerPrintOptions : String, Encodable {
    
    case SUCCESS = "success"

    case TIMEOUT = "timeout"
}
