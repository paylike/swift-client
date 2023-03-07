import Foundation
import PaylikeRequest

/**
 * Mock implenetation for `PaylikeHTTPClient` based on URL mocking
 */
internal class MockHTTPClient : HTTPClient {
    /**
     * HTTP Client implemetation
     */
    private let httpClient = PaylikeHTTPClient()
    
    /**
     * Overriding logging function to distinguish from the original one
     */
    internal var loggingFn: (Encodable) -> Void = { obj in
        print("Mock HTTP Client logger:", terminator: " ")
        debugPrint(obj)
    }
    
    init() {
        httpClient.loggingFn = loggingFn
    }
    
    /**
     * Mocked function for async `sendRequest`
     */
    func sendRequest(to endpoint: URL, withOptions options: RequestOptions) async throws -> PaylikeResponse {
        return try await httpClient.sendRequest(
            to: getMockURL(for: endpoint),
            withOptions: options
        )
    }
    
    /**
     * Mocked function for completion handler `sendRequest`
     */
    @available(swift, deprecated: 5.5)
    func sendRequest(to endpoint: URL, withOptions options: RequestOptions, completion handler: @escaping (Result<PaylikeResponse, Error>) -> Void) {
        do {
            httpClient.sendRequest(
                to: try getMockURL(for: endpoint),
                withOptions: options
            ) { result in
                handler(result)
            }
        } catch {
            handler(.failure(error))
        }
    }
    
    /**
     * Function to change the live URL to mocked ones
     */
    private func getMockURL(for url: URL) throws -> URL {
        var urlComponents = URLComponents()
        urlComponents.scheme = MockScheme
        urlComponents.host = MockHost
        urlComponents.port = MockPort
        switch url.absoluteString {
            case "https://applepay.paylike.io/token":
                urlComponents.path = MockEndpoints.APPLE_PAY_VAULT.rawValue
            case "https://vault.paylike.io":
                urlComponents.path = MockEndpoints.CARD_DATA_VAULT.rawValue
            case "https://b.paylike.io":
                urlComponents.path = MockEndpoints.CREATE_PAYMENT_API.rawValue
            default:
                throw HTTPClientError.InvalidURL(url)
        }
        guard let url = urlComponents.url else {
            throw HTTPClientError.InvalidURL(url)
        }
        return url
    }
}
