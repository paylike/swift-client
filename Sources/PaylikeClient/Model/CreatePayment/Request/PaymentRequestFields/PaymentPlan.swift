import Foundation

/**
 * Describes a plan / subscription in the payment request. Either scheduled or repeat has to be present
 */
public struct PaymentPlan: Encodable {
    /**
     * Amount of the subscription
     */
    public var amount: PaymentAmount
    /**
     * Future date of the transaction
     */
    public var scheduled: Date?
    /**
     * Repeating pattern of the plan
     */
    public var `repeat`: PlanRepeat?
    
    public init(amount: PaymentAmount, scheduled: Date? = nil) {
        self.amount = amount
        self.scheduled = scheduled
    }
}

/**
 * Describes a repeating pattern in the payment request plan
 */
public struct PlanRepeat: Encodable {
    /**
     * Optional, default: Now
     * The first date time when the payment gets executed
     */
    public var first: Date?
    /**
     * Optional, default: infinite, 1..
     * Describes how many times should the plan execute
     */
    public var count: Int?
    /**
     * Interval of the repeating pattern
     */
    public var interval: RepeatInterval
    
    public init(first: Date? = nil, count: Int? = nil, interval: RepeatInterval) {
        self.first = first
        self.count = count
        self.interval = interval
    }
}

/**
 * Describes an interval in a plan's repeat section when making a payment request
 */
public struct RepeatInterval: Encodable {
    /**
     * Unit of recurrence
     */
    public var unit: RepeatIntervalUnits
    /**
     * Optional, default: 1
     */
    public var value: Int?

    public init(unit: RepeatIntervalUnits, value: Int? = nil) {
        self.unit = unit
        self.value = value
    }
}

/**
 * Lists the available units of recurrence
 */
public enum RepeatIntervalUnits: String, Encodable {
    case DAY = "day"
    case WEEK = "week"
    case MONTH = "month"
    case YEAR = "year"
}
