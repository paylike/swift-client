import Foundation

/**
 Describes endpoints used
 */
public struct PaylikeHosts {
    /**
     General API of the ecosystem
     */
    public var api = "https://b.paylike.io"
    /**
     Vault used for tokenization of card numbers
     */
    public var vault = "https://vault.paylike.io"
    /**
     Apple Pay API
     */
    public var applePayAPI = "https://applepay.paylike.io/token"
}
