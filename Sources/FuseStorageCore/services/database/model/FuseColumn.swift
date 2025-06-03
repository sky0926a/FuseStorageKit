import Foundation

/// Defines the supported column types for database tables
public enum FuseColumnType {
    /// Text data type for storing strings
    case text
    /// Integer data type for storing whole numbers
    case integer
    /// Real data type for storing floating-point numbers
    case real
    /// Boolean data type for storing true/false values
    case boolean
    /// Date data type for storing timestamps
    case date
    /// Blob data type for storing binary data
    case blob
    /// Double data type for storing double-precision floating-point numbers
    case double
    /// Numeric data type for storing numeric values
    case numeric
    /// Any data type, allowing any kind of data
    case any
    
    /// Returns the SQL type string for this column type
    public var sqlType: String {
        switch self {
            case .text:    return "TEXT"
            case .integer: return "INTEGER"
            case .real:    return "REAL"
            case .boolean: return "BOOLEAN"
            case .date:    return "DATETIME"
            case .blob:    return "BLOB"
            case .double:  return "DOUBLE"
            case .numeric: return "NUMERIC"
            case .any:     return "ANY"
        }
    }
    
    public static func sqlType(_ type: String) -> FuseColumnType {
        switch type.uppercased() {
            case let t where t.contains("TEXT"): return .text
            case let t where t.contains("INTEGER"): return .integer
            case let t where t.contains("REAL"): return .real
            case let t where t.contains("DOUBLE"): return .double
            case let t where t.contains("NUMERIC"): return .numeric
            case let t where t.contains("BOOLEAN"): return .boolean
            case let t where t.contains("DATE"): return .date
            case let t where t.contains("DATETIME"): return .date
            case let t where t.contains("BLOB"): return .blob
            case let t where t.contains("ANY"): return .any
            default: return .text
        }
    }
}

/// Represents a column definition in a database table
public struct FuseColumnDefinition {
    /// The name of the column
    public let name: String
    /// The data type of the column
    public let type: FuseColumnType
    /// Whether this column is a primary key
    public let isPrimaryKey: Bool
    /// Whether this column cannot contain null values
    public let isNotNull: Bool
    /// Whether this column must contain unique values
    public let isUnique: Bool
    /// The default value for this column, if any
    public let defaultValue: FuseDatabaseValueConvertible?
    
    /// Creates a new column definition
    /// - Parameters:
    ///   - name: The name of the column
    ///   - type: The data type of the column
    ///   - isPrimaryKey: Whether this column is a primary key
    ///   - isNotNull: Whether this column cannot contain null values
    ///   - isUnique: Whether this column must contain unique values
    ///   - defaultValue: The default value for this column
    public init(
        name: String,
        type: FuseColumnType,
        isPrimaryKey: Bool = false,
        isNotNull: Bool = false,
        isUnique: Bool = false,
        defaultValue: FuseDatabaseValueConvertible? = nil
    ) {
        self.name        = name
        self.type        = type
        self.isPrimaryKey = isPrimaryKey
        self.isNotNull   = isNotNull
        self.isUnique    = isUnique
        self.defaultValue = defaultValue
    }
}
