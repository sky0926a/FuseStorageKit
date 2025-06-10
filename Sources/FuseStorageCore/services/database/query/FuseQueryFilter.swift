import Foundation

/// Represents a filter condition for database queries
public struct FuseQueryFilter {
    /// The name of the field to filter on
    public let field: String
    /// The comparison operator to use
    public let op: FuseQueryOperator
    /// The value to compare against, now supporting single or multiple values.
    public let value: FuseQueryValue // Changed from FuseDatabaseValueConvertible

    /// Internal initializer, use static factory methods for public construction.
    internal init(field: String, op: FuseQueryOperator, value: FuseQueryValue) {
        self.field = field
        self.op = op
        self.value = value
    }

    /// Creates a new filter condition for equality.
    public static func equals(field: String, value: FuseDatabaseValueConvertible) -> FuseQueryFilter {
        return FuseQueryFilter(field: field, op: .equals, value: .single(value))
    }

    /// Creates a new filter condition for non-equality.
    public static func notEquals(field: String, value: FuseDatabaseValueConvertible) -> FuseQueryFilter {
        return FuseQueryFilter(field: field, op: .notEquals, value: .single(value))
    }

    /// Creates a new filter condition for pattern matching (LIKE).
    /// The value provided should be the SQL pattern string, including any necessary wildcards (e.g., '%', '_').
    public static func like(field: String, value: FuseDatabaseValueConvertible) -> FuseQueryFilter {
        return FuseQueryFilter(field: field, op: .like, value: .single(value))
    }

    /// Creates a new filter condition for greater than.
    public static func greaterThan(field: String, value: FuseDatabaseValueConvertible) -> FuseQueryFilter {
        return FuseQueryFilter(field: field, op: .greaterThan, value: .single(value))
    }

    /// Creates a new filter condition for less than.
    public static func lessThan(field: String, value: FuseDatabaseValueConvertible) -> FuseQueryFilter {
        return FuseQueryFilter(field: field, op: .lessThan, value: .single(value))
    }

    /// Creates a new filter condition for checking if a value is in a set.
    public static func inSet(field: String, values: [FuseDatabaseValueConvertible]) -> FuseQueryFilter {
        return FuseQueryFilter(field: field, op: .inSet, value: .multiple(values))
    }

    /// Builds the SQL WHERE clause and its parameters
    /// - Returns: A tuple containing the SQL clause and its parameter values
    internal func build() -> (clause: String, values: [FuseDatabaseValueConvertible]) {
        switch op {
        case .equals:
            guard case .single(let val) = value else {
                assertionFailure("Invalid value for .equals operator; expected .single(). This should not happen if using static factory methods.")
                return ("1=0", []) // Should be unreachable if factory methods are used
            }
            return ("\(field) = ?", [val])
        case .notEquals:
            guard case .single(let val) = value else {
                assertionFailure("Invalid value for .notEquals operator; expected .single().")
                return ("1=0", [])
            }
            return ("\(field) != ?", [val])
        case .like:
            guard case .single(let val) = value else {
                assertionFailure("Invalid value for .like operator; expected .single().")
                return ("1=0", [])
            }
            return ("\(field) LIKE ?", [val])
        case .greaterThan:
            guard case .single(let val) = value else {
                assertionFailure("Invalid value for .greaterThan operator; expected .single().")
                return ("1=0", [])
            }
            return ("\(field) > ?", [val])
        case .lessThan:
            guard case .single(let val) = value else {
                assertionFailure("Invalid value for .lessThan operator; expected .single().")
                return ("1=0", [])
            }
            return ("\(field) < ?", [val])
        case .inSet:
            guard case .multiple(let seq) = value else {
                assertionFailure("Invalid value for .inSet operator; expected .multiple().")
                return ("1=0", []) // Should be unreachable if .inSet static factory is used
            }
            guard !seq.isEmpty else {
                return ("1=0", []) // SQL standard: IN with an empty set is false
            }
            let placeholders = Array(repeating: "?", count: seq.count).joined(separator: ", ")
            return ("\(field) IN (\(placeholders))", seq)
        }
    }
}
