import Foundation

/// A protocol that defines the requirements for database records in FuseStorageKit.
/// This protocol combines Codable for JSON serialization, FuseFetchableRecord for reading from the database,
/// and FusePersistableRecord for writing to the database.
public protocol FuseDatabaseRecord: Codable, Identifiable, FuseFetchableRecord, FusePersistableRecord {
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

    /// The name of the database table for this record type.
    /// By default, it uses the lowercase name of the record type.
    static var databaseTableName: String {
        return String(describing: self).lowercased()
    }
}
