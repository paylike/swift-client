/**
 Handles hih level requests toward the Paylike APIs
 */
public struct PaylikeClient {
    public init() {
    }
    static func generateClientID() -> String {
        let chars = "AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890"
        let id = (0..<6).map { _ in
            String(chars.randomElement()!)
        }
        return "swift-1-\(id.joined())"
    }
}
