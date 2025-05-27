import Foundation

/// Enumeration of database-specific errors that can occur during FuseStorageKit operations
/// 
/// This error type provides specific error cases for database operations, helping
/// developers identify and handle different types of database-related failures
/// with appropriate error messages and recovery strategies.
public enum FuseDatabaseError: Error {
    /// Indicates that the record type is not suitable for database operations
    /// 
    /// This error occurs when attempting to use a type that doesn't conform to
    /// the required database record protocols or has invalid configuration.
    case invalidRecordType
    
    /// Indicates that the table already exists when trying to create it
    /// 
    /// This error occurs when attempting to create a table that already exists
    /// in the database without using the `ifNotExists` option.
    /// - Parameter tableName: The name of the table that already exists
    case tableAlreadyExists(String)
    
    /// Indicates that a passphrase was required but not provided for encryption
    /// 
    /// This error occurs when trying to open an encrypted database without
    /// providing the required passphrase or when the passphrase is empty.
    case missingPassphrase
}