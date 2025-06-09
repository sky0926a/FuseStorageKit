import Foundation

/// Defines the available comparison operators for database queries
public enum FuseQueryOperator {
    /// Equal to comparison
    case equals
    /// Not equal to comparison
    case notEquals
    /// Pattern matching using SQL LIKE
    case like
    /// Greater than comparison
    case greaterThan
    /// Less than comparison
    case lessThan
    /// Value is in a set of values
    case inSet
}
