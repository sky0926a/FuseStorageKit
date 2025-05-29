import Foundation

/// A protocol that defines the requirements for database records in FuseStorageKit.
/// This protocol combines Codable for JSON serialization, FuseFetchableRecord for reading from the database,
/// and FusePersistableRecord for writing to the database.
public protocol FuseDatabaseRecord: Codable, FuseFetchableRecord, FusePersistableRecord {
    /// The unique identifier for the record in the database
    var _fuseid: FuseDatabaseValueConvertible { get }
    
    /// The name of the ID field in the database table
    static var _fuseidField: String { get }
    
    /// The name of the database table for this record type
    static var databaseTableName: String { get }
    
    /// Converts the record to a dictionary of database values
    /// - Returns: A dictionary mapping column names to their corresponding database values
    func toDatabaseValues() -> [String: FuseDatabaseValueConvertible?]
}

public extension FuseDatabaseRecord {
    /// The unique identifier for the record, automatically retrieved from the specified ID field.
    /// This implementation uses reflection to find the ID field value.
    var _fuseid: FuseDatabaseValueConvertible {
        let mirror = Mirror(reflecting: self)
        guard let value = mirror.children.first(where: { $0.label == Self._fuseidField })?.value as? FuseDatabaseValueConvertible else {
            fatalError("Can not find ID field: \(Self._fuseidField)")
        }
        return value
    }
    
    /// Default implementation that delegates to the database factory
    /// The actual implementation will be provided by the concrete database implementation (e.g., GRDB)
    func toDatabaseValues() -> [String: FuseDatabaseValueConvertible?] {
        // This will be overridden by the GRDB implementation through extensions
        fatalError("toDatabaseValues() must be implemented by the database implementation")
    }
    
    /// Default implementation that delegates to the database factory
    /// The actual implementation will be provided by the concrete database implementation (e.g., GRDB)
    static func fromDatabase(row: FuseDatabaseRow) throws -> Self {
        // This will be overridden by the GRDB implementation through extensions
        fatalError("fromDatabase() must be implemented by the database implementation")
    }
}

/// Helper function to convert database values to JSON-compatible values with type hints
private func convertToJSONValue(_ value: Any?, expectedType: Any.Type) -> Any? {
    guard let value = value else { return nil }
    
    // Handle different expected types
    switch expectedType {
    case is String.Type:
        return value as? String ?? String(describing: value)
    case is Int.Type:
        if let intValue = value as? Int { return intValue }
        if let int64Value = value as? Int64 { return Int(int64Value) }
        if let stringValue = value as? String { return Int(stringValue) }
        return 0
    case is Int64.Type:
        if let int64Value = value as? Int64 { return int64Value }
        if let intValue = value as? Int { return Int64(intValue) }
        if let stringValue = value as? String { return Int64(stringValue) }
        return 0
    case is Double.Type:
        if let doubleValue = value as? Double { return doubleValue }
        if let floatValue = value as? Float { return Double(floatValue) }
        if let stringValue = value as? String { return Double(stringValue) }
        return 0.0
    case is Bool.Type:
        if let boolValue = value as? Bool { return boolValue }
        if let intValue = value as? Int { return intValue != 0 }
        if let stringValue = value as? String { 
            return stringValue.lowercased() == "true" || stringValue == "1" 
        }
        return false
    case is Date.Type:
        if let dateValue = value as? Date {
            let formatter = ISO8601DateFormatter()
            return formatter.string(from: dateValue)
        }
        if let stringValue = value as? String {
            return stringValue // Let JSONDecoder handle the parsing
        }
        return ISO8601DateFormatter().string(from: Date())
    case is Data.Type:
        if let dataValue = value as? Data {
            return dataValue.base64EncodedString()
        }
        if let stringValue = value as? String {
            return stringValue
        }
        return ""
    default:
        return value
    }
}
