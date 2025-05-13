import Foundation

public enum FuseDatabaseError: Error {
    /// Indicates that the record type is not suitable for database operations
    case invalidRecordType
    /// Indicates that the table already exists
    case tableAlreadyExists(String)
    /// Indicates that a passphrase was required but not provided
    case missingPassphrase
}