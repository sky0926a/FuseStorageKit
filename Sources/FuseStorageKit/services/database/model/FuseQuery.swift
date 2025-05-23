import Foundation
import GRDB

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

/// Represents the value(s) for a query filter, supporting single or multiple values.
// Added to support type-safe single or multiple values for filters.
public enum FuseQueryValue {
    /// A single value for comparison.
    case single(FuseDatabaseValueConvertible)
    /// A collection of values, typically for 'IN' clauses.
    case multiple([FuseDatabaseValueConvertible])
}

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

/// Defines the sort order for database queries
public enum FuseQuerySortOrder {
    /// Ascending order (A to Z, 1 to 9)
    case ascending
    /// Descending order (Z to A, 9 to 1)
    case descending
}

/// Represents a field to sort by in database queries
public struct FuseSortField {
    /// The name of the field to sort by
    public let field: String
    /// The sort order to apply
    public let order: FuseQuerySortOrder

    /// Creates a new sort field
    /// - Parameters:
    ///   - field: The name of the field to sort by
    ///   - order: The sort order to apply
    public init(field: String, order: FuseQuerySortOrder) {
        self.field = field
        self.order = order
    }
}

/// Represents a sorting configuration for database queries
public struct FuseQuerySort {
    private let sortFields: [FuseSortField]
    
    /// Creates a sort configuration with a single field
    /// - Parameters:
    ///   - field: The name of the field to sort by
    ///   - order: The sort order to apply
    public init(field: String, order: FuseQuerySortOrder) {
        self.sortFields = [FuseSortField(field: field, order: order)]
    }
    
    /// Creates a sort configuration with multiple fields
    /// - Parameter sortFields: Array of fields to sort by
    public init(sortFields: [FuseSortField]) {
        self.sortFields = sortFields
    }

    /// Builds the SQL ORDER BY clause
    /// - Returns: The SQL ORDER BY clause
    internal func build() -> String {
        let sortClauses = sortFields.map { field in
            let dir = (field.order == .ascending ? "ASC" : "DESC")
            return "\(field.field) \(dir)"
        }
        return "ORDER BY " + sortClauses.joined(separator: ", ")
    }
}

/// Defines the available query actions for database operations
public enum FuseQueryAction {
    /// Select records with optional filtering, sorting, and pagination
    case select(fields: [String], filters: [FuseQueryFilter], sort: FuseQuerySort?, limit: Int? = nil, offset: Int? = nil)
    /// Insert new records
    case insert(values: [String: FuseDatabaseValueConvertible?])
    /// Insert multiple records at once
    case insertMany(values: [[String: FuseDatabaseValueConvertible?]])
    /// Update existing records
    case update(values: [String: FuseDatabaseValueConvertible?], filters: [FuseQueryFilter])
    /// Delete records
    case delete(filters: [FuseQueryFilter])
    /// Delete multiple records by their IDs
    case deleteMany(field: String, ids: [FuseDatabaseValueConvertible])
    /// Insert or update records (UPSERT)
    case upsert(values: [String: FuseDatabaseValueConvertible?], conflict: [String], update: [String]?)
}

/// Represents a database query with its action and target table
public struct FuseQuery {
    /// The name of the table to query
    public let table: String
    /// The action to perform on the table
    public let action: FuseQueryAction

    /// Creates a new query
    /// - Parameters:
    ///   - table: The name of the table to query
    ///   - action: The action to perform
    public init(table: String, action: FuseQueryAction) {
        self.table = table
        self.action = action
    }

    /// Builds the SQL query and its parameters
    /// - Returns: A tuple containing the SQL query and its parameter values
    internal func build() -> (sql: String, args: [FuseDatabaseValueConvertible]) {
        switch action {
        case .select(let fields, let filters, let sort, let limit, let offset):
            var sql = "SELECT \(fields.joined(separator: ", ")) FROM \(table)"
            var args: [FuseDatabaseValueConvertible] = []
            if !filters.isEmpty {
                let parts = filters.map { f in f.build() }
                sql += " WHERE " + parts.map { $0.clause }.joined(separator: " AND ")
                args = parts.flatMap { $0.values }
            }
            if let s = sort {
                sql += " " + s.build()
            }
            if let limit = limit {
                sql += " LIMIT \(limit)"
            }
            if let offset = offset {
                sql += " OFFSET \(offset)"
            }
            return (sql, args)

        case .insert(let values):
            let sortedKeys = values.keys.sorted()
            let cols = sortedKeys.joined(separator: ", ")
            let placeholders = Array(repeating: "?", count: values.count).joined(separator: ", ")
            let sql = "INSERT INTO \(table) (\(cols)) VALUES (\(placeholders))"
            let args = sortedKeys.map { (values[$0] as? FuseDatabaseValueConvertible) ?? NSNull() }
            return (sql, args)

        case .insertMany(let manyValues):
            guard !manyValues.isEmpty else {
                return ("", [])
            }
            
            // 從所有記錄中找出所有可能的欄位
            let allKeys = Set(manyValues.flatMap { $0.keys }).sorted()
            let cols = allKeys.joined(separator: ", ")
            
            // 為每筆記錄創建值佔位符 (?, ?, ...)
            let valuePlaceholders = Array(repeating: "?", count: allKeys.count).joined(separator: ", ")
            let rowPlaceholders = Array(repeating: "(\(valuePlaceholders))", count: manyValues.count).joined(separator: ", ")
            
            let sql = "INSERT INTO \(table) (\(cols)) VALUES \(rowPlaceholders)"
            
            // 組裝所有參數，確保每筆記錄的欄位順序與 allKeys 一致
            var args: [FuseDatabaseValueConvertible] = []
            for values in manyValues {
                args.append(contentsOf: allKeys.map { values[$0] as? FuseDatabaseValueConvertible ?? NSNull() })
            }
            
            return (sql, args)

        case .update(let values, let filters):
            let sortedKeys = values.keys.sorted()
            let setClause = sortedKeys.map { "\($0) = ?" }.joined(separator: ", ")
            var sql = "UPDATE \(table) SET \(setClause)"
            var args = sortedKeys.map { (values[$0] as? FuseDatabaseValueConvertible) ?? NSNull() }
            if !filters.isEmpty {
                let parts = filters.map { f in f.build() }
                sql += " WHERE " + parts.map { $0.clause }.joined(separator: " AND ")
                args += parts.flatMap { $0.values }
            }
            return (sql, args)

        case .delete(let filters):
            var sql = "DELETE FROM \(table)"
            var args: [FuseDatabaseValueConvertible] = []
            if !filters.isEmpty {
                let parts = filters.map { f in f.build() }
                sql += " WHERE " + parts.map { $0.clause }.joined(separator: " AND ")
                args = parts.flatMap { $0.values }
            }
            return (sql, args)

        case .deleteMany(let field, let ids):
            let placeholders = Array(repeating: "?", count: ids.count).joined(separator: ", ")
            let sql = "DELETE FROM \(table) WHERE \(field) IN (\(placeholders))"
            let args = ids
            return (sql, args)

        case .upsert(let values, let conflictCols, let updateCols):
            let sortedValueKeys = values.keys.sorted()
            let cols = sortedValueKeys.joined(separator: ", ")
            let placeholders = Array(repeating: "?", count: values.count).joined(separator: ", ")
            let conflictList = conflictCols.joined(separator: ", ")
            
            let keysForUpdateClause: [String]
            if let specificUpdateCols = updateCols {
                keysForUpdateClause = specificUpdateCols.sorted()
            } else {
                keysForUpdateClause = values.keys.filter { !conflictCols.contains($0) }.sorted()
            }
            
            let updateList = keysForUpdateClause
                .map { "\($0) = excluded.\($0)" }
                .joined(separator: ", ")
                
            let sql = "INSERT INTO \(table) (\(cols)) VALUES (\(placeholders)) ON CONFLICT(\(conflictList)) DO UPDATE SET \(updateList)"
            let args = sortedValueKeys.map { (values[$0] as? FuseDatabaseValueConvertible) ?? NSNull() }
            return (sql, args)
        }
    }
}
