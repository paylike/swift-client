/**
 * Three predefined payment challenges
 */
public enum ChallengeTypes: String, Decodable {
    case BACKGROUND_IFRAME = "background-iframe"
    case FETCH = "fetch"
    case IFRAME = "iframe"
}
