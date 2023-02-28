/**
 * Received payment request challenge
 */
public struct ChallengeResponse : Decodable {
    /**
     * Challenge information
     */
    var name: String
    /**
     * Defined in `ChallengeTypes`
     */
    var type: ChallengeTypes
    /**
     * URL path
     */
    var path: String
}
