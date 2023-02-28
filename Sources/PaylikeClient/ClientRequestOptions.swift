import Foundation
import PaylikeRequest


#warning("delete this later. epic overengineering...")
/**
 * Extension for RequestOptions initialization
 */
internal extension PaylikeClient {
    /**
     * Initializes requestOptions with
     * - requestOptions with "GET" method
     * - self.timeoutInterval
     * - self.clientId
     */
    func initRequestOptions() -> RequestOptions {
        var options = RequestOptions()
        options.timeoutInterval = timeoutInterval
        options.clientId = clientID
        return options
    }
    /**
     * Initializes requestOptions with
     * - requestOptions with "POST" method and data
     * - self.timeoutInterval
     * - self.clientId
     */
    func initRequestOptions(
        withData data: Data
    ) -> RequestOptions {
        var options = RequestOptions(
            withData: data
        )
        options.timeoutInterval = timeoutInterval
        options.clientId = clientID
        return options
    }
    /**
     * Initializes requestOptions with
     * - requestOptions with "POST" method and formFields
     * - self.timeoutInterval
     * - self.clientId
     */
    func initRequestOptions(
        withFormFields formFields: [String: String]
    ) -> RequestOptions {
        var options = RequestOptions(
            withFormFields: formFields
        )
        options.timeoutInterval = timeoutInterval
        options.clientId = clientID
        return options
    }
}
