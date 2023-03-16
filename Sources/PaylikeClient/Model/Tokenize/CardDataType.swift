/**
 * Type to decide which card data to tokenize
 */
public enum CardDataType: String, Encodable {
    /**
     * PCN as in Payment Card Number
     */
    case PCN = "pcn"
    /**
     * PCSC as in Payment Card Security Code
     */
    case PCSC = "pcsc"
}
