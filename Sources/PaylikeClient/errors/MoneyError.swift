import Foundation

/**
 Describes errors regarding the library
 */
public enum MoneyError : Error {
    /**
     Happens when the input is considered an unsafe integer
     */
    case UnsafeNumber(number: Double)
}
