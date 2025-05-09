import Foundation
import GRDB

/// Protocol defining the core database operations for FuseStorageKit.
/// This protocol provides a type-safe interface for database operations including
/// table management, record operations, and query execution.
public protocol FuseDatabaseManageable {
    /// Checks if a table exists in the database
    /// - Parameter tableName: The name of the table to check
    /// - Returns: `true` if the table exists, `false` otherwise
    /// - Throws: Database operation errors
    func tableExists(_ tableName: String) throws -> Bool
 
    /// Creates a new table in the database using the provided definition
    /// - Parameter tableDefinition: The definition of the table to create
    /// - Throws: Database operation errors if the table cannot be created
    func createTable(_ tableDefinition: FuseTableDefinition) throws
    
    /// Inserts a new record into the database
    /// - Parameter record: The record to insert
    /// - Throws: Database operation errors if the insertion fails
    func add<T: FuseDatabaseRecord>(_ record: T) throws
    
    /// Fetches records from the database with optional filtering, sorting, and pagination
    /// - Parameters:
    ///   - type: The type of records to fetch
    ///   - filters: Array of filter conditions to apply
    ///   - sort: Optional sorting criteria
    ///   - limit: Optional maximum number of records to return
    ///   - offset: Optional number of records to skip
    /// - Returns: Array of fetched records
    /// - Throws: Database operation errors if the fetch fails
    func fetch<T: FuseDatabaseRecord>(
        of type: T.Type,
        filters: [FuseQueryFilter],
        sort: FuseQuerySort?,
        limit: Int?,
        offset: Int?
    ) throws -> [T]
    
    /// Deletes a record from the database
    /// - Parameter record: The record to delete
    /// - Throws: Database operation errors if the deletion fails
    func delete<T: FuseDatabaseRecord>(_ record: T) throws
    
    /// Executes a SELECT query and returns the results as an array of records
    /// - Parameter query: The query to execute
    /// - Returns: Array of records matching the query
    /// - Throws: Database operation errors if the query fails
    func read<T: FuseDatabaseRecord>(_ query: FuseQuery) throws -> [T]
    
    /// Executes a write operation (INSERT/UPDATE/DELETE/UPSERT)
    /// - Parameter query: The query to execute
    /// - Throws: Database operation errors if the write operation fails
    func write(_ query: FuseQuery) throws
}
