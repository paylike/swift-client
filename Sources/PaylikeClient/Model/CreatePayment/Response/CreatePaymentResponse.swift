/**
 * Describes a network request response of the `createPayment` request flow. We receive one of the following lot of fields:
 */
public struct CreatePaymentResponse: Decodable {
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
    
    public init(
        challenges: [ChallengeResponse]? = nil,
        hints: [String]? = nil,
        action: String? = nil,
        method: String? = nil,
        fields: [String : String]? = nil,
        timeout: Int? = nil,
        authorizationId: String? = nil,
        transactionId: String? = nil
    ) {
        self.challenges = challenges
        self.hints = hints
        self.action = action
        self.method = method
        self.fields = fields
        self.timeout = timeout
        self.authorizationId = authorizationId
        self.transactionId = transactionId
    }
}
