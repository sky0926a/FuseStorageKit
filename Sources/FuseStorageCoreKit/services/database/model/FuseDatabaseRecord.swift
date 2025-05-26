import Foundation

/// A protocol that defines the requirements for database value conversion in FuseStorageKit.
/// This is an abstraction that allows different database implementations.
public protocol FuseDatabaseValueConvertible {
    // This will be implemented by the concrete database implementations
}

// Basic types conformance
extension String: FuseDatabaseValueConvertible {}
extension Int: FuseDatabaseValueConvertible {}
extension Int64: FuseDatabaseValueConvertible {}
extension Double: FuseDatabaseValueConvertible {}
extension Bool: FuseDatabaseValueConvertible {}
extension Date: FuseDatabaseValueConvertible {}
extension Data: FuseDatabaseValueConvertible {}
extension NSNull: FuseDatabaseValueConvertible {}

/// A protocol that defines the requirements for database records in FuseStorageKit.
/// This protocol provides an abstraction layer that can work with different database implementations.
public protocol FuseDatabaseRecord: Codable {
    /// The unique identifier for the record in the database
    var _fuseid: FuseDatabaseValueConvertible { get }
    
    /// The name of the ID field in the database table
    static var _fuseidField: String { get }
    
    /// Converts the record to a dictionary of database values
    /// - Returns: A dictionary mapping column names to their corresponding database values
    func toDatabaseValues() -> [String: FuseDatabaseValueConvertible?]
}

public extension FuseDatabaseRecord {
    /// The name of the database table for this record type.
    /// By default, it uses the lowercase name of the record type.
    static var databaseTableName: String {
        return String(describing: self).lowercased()
    }
    
    /// The unique identifier for the record, automatically retrieved from the specified ID field.
    /// This implementation uses reflection to find the ID field value.
    var _fuseid: FuseDatabaseValueConvertible {
        let mirror = Mirror(reflecting: self)
        guard let value = mirror.children.first(where: { $0.label == Self._fuseidField })?.value as? FuseDatabaseValueConvertible else {
            fatalError("Can not find ID field: \(Self._fuseidField)")
        }
        return value
    }
    
    /// Converts the record to a dictionary of database values.
    /// This implementation handles Date objects and other FuseDatabaseValueConvertible types.
    /// - Returns: A dictionary mapping column names to their corresponding database values
    func toDatabaseValues() -> [String: FuseDatabaseValueConvertible?] {
            var dict: [String: FuseDatabaseValueConvertible?] = [:]
            let mirror = Mirror(reflecting: self)
            for child in mirror.children {
                guard let key = child.label else { continue }
                let value = child.value
                // Handle Date objects directly
                if let d = value as? Date {
                    dict[key] = d
                }
                // Handle other convertible types
                else if let cv = value as? FuseDatabaseValueConvertible {
                    dict[key] = cv
                }
                else {
                    // Complex types are not supported
                    fatalError("Unsupported type for key \(key)")
                }
            }
            return dict
        }
}
