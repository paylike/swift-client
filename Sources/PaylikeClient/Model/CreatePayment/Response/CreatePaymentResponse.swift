/**
 * Describes a network request response of the `createPayment` request flow
 * we receive one of the following lot of fields:
 */
public struct CreatePaymentResponse : Decodable {
    
    /*
     * this
     */
    public var challenges: [ChallengeResponse]?
    
    /*
     * or
     */
    public var hints: [String]?
    
    /*
     * or
     */
    public var action: String?
    public var method: String?
    public var fields: [String: String]?
    public var timeout: Int?
    // (along hints)
    
    /*
     * or one of them
     */
    public var authorizationId: String?
    public var transactionId: String?
}
