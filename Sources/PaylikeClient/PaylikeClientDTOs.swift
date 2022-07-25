import Foundation
import PaylikeMoney

/**
 Describes the final response from the payment creation API
 */
public struct PaymentResponseDTO : Codable {
    /**
     Transaction ID to refer for the transaction
     */
    public var authorizationId: String
}

/**
 Describes a response recieved during the payment transaction process
 */
public struct PaylikeClientResponse {
    public var HTMLBody: String?
    public var paymentResponse: PaymentResponseDTO?
    public var hints: [String]?
    public var isHTML: Bool
    /**
     Initializes a new client response with an HTML body and optional hints list
     */
    public init(_ HTMLBody: String, hints: [String] = []) {
        self.HTMLBody = HTMLBody
        self.isHTML = true
        self.hints = hints
    }
    /**
     Initializes a new client response with a finalized [PaymentResponseDTO]
     */
    public init(_ response: PaymentResponseDTO, hints: [String] = []) {
        self.paymentResponse = response
        self.hints = hints
        self.isHTML = false
    }
}

/**
 Describes card information for a payment request
 */
public struct PaymentRequestCardDTO : Codable {
    /**
     Tokenized card number
     */
    public var number: [String: String]
    /**
     Expiry. Need to have a `year` and a `month` property
     */
    public var expiry: [String: Int]
    /**
     Tokenized CVC code
     */
    public var code: [String: String]
    public init(
        number: String,
        month: Int,
        year: Int,
        code: String
    ) {
        self.number = ["token": number]
        self.expiry = [
            "month": month,
            "year": year < 100 ? year + 2000 : year,
        ]
        self.code = ["token": code]
    }
}

/**
 Describes an interval in a plan's repeat section when making a payment request
 */
public struct PaymentRequestPlanRepeatIntervalDTO : Codable {
    /**
     Unit of the string, one of: "day", "week", "month", "year"
     */
    public var unit: String
    /**
     Optional, default: 1
     */
    public var value: Int
    /**
     Initialises with a unit and a value
     */
    public init(unit: String, value: Int) {
        self.unit = unit
        self.value = value
    }
    /**
     Uses the default value of 1 with unit set
     */
    public init(unit: String) {
        self.unit = unit
        self.value = 1
    }
}

/**
 Describes a repeating pattern in the payment request plan
 */
public struct PaymentRequestPlanRepeatDTO : Codable {
    /**
     Optional, default: Now
     The first date time when the payment gets executed
     */
    public var first: Date = Date()
    
    /**
     Optional, default: infinite, 1..
     Describes how many times should the plan execute
     */
    public var count: Int = Int.max
    /**
     Interval of the repeating pattern
     */
    public var interval: PaymentRequestPlanRepeatIntervalDTO
}

/**
 Describes a plan / subscription in the payment request. Either scheduled or repeat has to be present
 */
public struct PaymentRequestPlanDTO : Codable {
    /**
     Amount of the subscription
     */
    public var amount: PaymentAmount
    /**
     Future date of the transaction
     */
    public var scheduled: Date?
    /**
     Repeating pattern of the plan
     */
    public var `repeat`: PaymentRequestPlanRepeatDTO?
}

/**
 Describes a single challenge received during the security check flow
 of the payment creation
 */
public struct PaymentChallengeDTO : Codable {
    /**
     Name to identify the challenge
     */
    public var name: String
    /**
     Type of the challenge (e.g.: fetch, tds, fingerprint etc..)
     */
    public var type: String
    /**
     Path to use while solving the challenge
     */
    public var path: String
}

/**
 Describes a response received in payment flow
 */
public struct PaymentFlowResponse: Codable {
    public var challenges: [PaymentChallengeDTO]?
    public var action: String?
    public var fields: [String: String]?
    public var hints: [String]?
    public var authorizationId: String?
    public var transactionId: String?
}

/**
 All possible options for creating a payment request. More information: https://github.com/paylike/api-reference/blob/main/payments/index.md
 */
public class PaymentRequestDTO : Codable {
    /**
     Should be a map with a `key` property, this is the public key for the merchant
     */
    public var integration: [String: String]
    /**
     Optional, if none is provided the merchant's default is used
     */
    public var text: String?
    /**
     Optional,
     This is the (positive) amount immediately due for reservation on the customer's payment instrument.
     */
    public var amount: PaymentAmount?
    /**
     Optional,
     Card information for the payment. Either card or apple pay token should be provided
     */
    public var card: PaymentRequestCardDTO?
    /**
     Optional,
     Collected hints to attach the request. It is required to execute the payment and TDS flow
     */
    public var hints: Set<String>?
    /**
     Optional,
     Can have `merchant` or `customer` key to indicate that
     unplanned charges are possible from one of the parties
     */
    public var unplanned: [String: Bool]?
    /**
     Optional,
     A set of plans to execute (used for subscription)
     */
    public var plan: [PaymentRequestPlanDTO]?
    /**
     Used for testing scenarios in the sandbox environment
     */
    public var test: [String: String] = [:]
    /**
     Inits the DTO with a key
     */
    public init(key: String) {
        self.integration = ["key": key]
    }
}
