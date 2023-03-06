import Foundation

/**
 * Responsible for creating and manipulating payment amounts
 */
public struct PaymentAmount : Encodable, Equatable {
    /**
     * Currency of the payment
     */
    public var currency: CurrencyCodes;
    /**
     * Value of the amount
     */
    public var value: Int;
    /**
     * Exponent of the amount
     */
    public var exponent: Int;
    
    /**
     * Default initialization
     */
    public init(
        currency code: CurrencyCodes,
        value: Int,
        exponent: Int
    ) {
        self.currency = code
        self.value = value
        self.exponent = exponent
    }
    
    /**
     * Allows the conversion from double to PaymentAmount
     */
    public init(
        currency code: CurrencyCodes,
        double value: Double
    ) throws {
        if !value.isFinite {
            throw ClientError.UnsafeNumber(number: value)
        }
        if (!PaymentAmount.isInSafeRange(n: Decimal(value))) {
            throw ClientError.UnsafeNumber(number: value)
        }
        let splitted = value.description.split(separator: ".")
        let wholes = String(splitted[0]);
        let somes =
        (splitted.count > 1 && String(splitted[1]) != "0")
        ? String(splitted[1])
        : ""
        guard let value = Int(wholes + somes) else {
            throw ClientError.UnsafeNumber(number: value)
        }
        self.currency = code
        self.exponent = somes.count
        self.value = value
    }
    
    /**
     * Maximum integer that can be used (originates from JS limitations)
     */
    static private let maxInt = Int64(9007199254740991)
    /**
     * Checks if the input parameter is in the safe range or not
     */
    static private func isInSafeRange(n: Decimal) -> Bool {
        return n <= Decimal(maxInt) && n >= Decimal(-maxInt)
    }
    
    /**
     * Check if they are
     * - the same currency and
     * - has the same value on common denominator
     */
    public static func == (lhs: PaymentAmount, rhs: PaymentAmount) -> Bool {
        if (lhs.currency != rhs.currency) {
            return false
        }
        let lhsOnCommonDenominator = Decimal(lhs.value) * pow(10, rhs.exponent)
        let rhsOnCommonDenominator = Decimal(rhs.value) * pow(10, lhs.exponent)
        return lhsOnCommonDenominator == rhsOnCommonDenominator
    }
}
