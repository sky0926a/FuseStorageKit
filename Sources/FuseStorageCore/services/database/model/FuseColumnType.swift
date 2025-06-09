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
