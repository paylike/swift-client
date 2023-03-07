/**
 * Describes a network request response of the `createPayment` request flow
 * we receive one of the following lot of fields:
 */
public struct CreatePaymentResponse : Decodable {
    /**
     * this
     */
    var challenges: [ChallengeResponse]?
    
    /**
     * or
     */
    var hints: [String]?
    
    /**
     * or
     */
    var action: String?
    var method: String?
    var fields: [String: String]?
    var timeout: Int?
    // (along hints)
    
    /**
     * or one of them
     */
    var authorizationId: String?
    var transactionId: String?
}
