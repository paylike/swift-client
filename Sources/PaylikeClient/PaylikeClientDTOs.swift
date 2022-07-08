import Foundation
import PaylikeMoney

/**
 Describes card information for a payment request
 */
public struct PaymentRequestCardDTO : Codable {
    /**
     Tokenized card number
     */
    public var number: String
    /**
     Expiry. Need to have a `year` and a `month` property
     */
    public var expiry: [String: Int8]
    /**
     Tokenized CVC code
     */
    public var code: String
    public init(
        number: String,
        month: Int8,
        year: Int8,
        code: String
    ) {
        self.number = number
        self.expiry = [
            "month": month,
            "year": year,
        ]
        self.code = code
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
 All possible options for creating a payment request. More information: https://github.com/paylike/api-reference/blob/main/payments/index.md
 */
public struct PaymentRequestDTO {
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
     Custom data to include in your request. The information you set here will appear on our dashboard
     */
    public var custom: Codable?
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
     Inits the DTO with a key
     */
    public init(key: String) {
        self.integration = ["key": key]
    }
    
}
