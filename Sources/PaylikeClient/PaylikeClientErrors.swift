import Foundation

/**
 Describes errors that can happen in the client library
 */
public enum PaylikeClientErrors : Error {
    /**
     Happens when a response has an unexpected body
     */
case UnexpectedResponseBody(body: Data?)
}
