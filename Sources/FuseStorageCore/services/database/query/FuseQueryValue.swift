import Foundation

/// Represents the value(s) for a query filter, supporting single or multiple values.
// Added to support type-safe single or multiple values for filters.
public enum FuseQueryValue {
    /// A single value for comparison.
    case single(FuseDatabaseValueConvertible)
    /// A collection of values, typically for 'IN' clauses.
    case multiple([FuseDatabaseValueConvertible])
}
