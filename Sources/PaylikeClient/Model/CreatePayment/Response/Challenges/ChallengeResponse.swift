/**
 * Received payment request challenge
 */
public struct ChallengeResponse : Decodable {
    /**
     * Challenge information
     */
    public var name: String
    /**
     * Defined in `ChallengeTypes`
     */
    public var type: ChallengeTypes
    /**
     * URL path
     */
    public var path: String
}
