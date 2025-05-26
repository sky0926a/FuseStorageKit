import Foundation
import GRDB
import FuseStorageCoreKit

/// A type alias for GRDB's DatabaseValueConvertible to maintain consistency in the FuseStorageKit API
extension String: FuseDatabaseValueConvertible {}
extension Int: FuseDatabaseValueConvertible {}
extension Int64: FuseDatabaseValueConvertible {}
extension Double: FuseDatabaseValueConvertible {}
extension Bool: FuseDatabaseValueConvertible {}
extension Date: FuseDatabaseValueConvertible {}
extension Data: FuseDatabaseValueConvertible {}
extension NSNull: FuseDatabaseValueConvertible {}

// Bridge GRDB types to our abstraction
extension DatabaseValueConvertible {
    var asFuseDatabaseValueConvertible: FuseDatabaseValueConvertible {
        if let string = self as? String { return string }
        if let int = self as? Int { return int }
        if let int64 = self as? Int64 { return int64 }
        if let double = self as? Double { return double }
        if let bool = self as? Bool { return bool }
        if let date = self as? Date { return date }
        if let data = self as? Data { return data }
        return NSNull()
    }
}

/// Extension to make FuseDatabaseRecord work with GRDB
extension FuseDatabaseRecord where Self: FetchableRecord & PersistableRecord {
    // GRDB integration is handled automatically through protocol conformance
}

/// A concrete implementation of `FuseDatabaseManageable` protocol using standard GRDB.
/// This class provides a robust and type-safe interface for SQLite database operations without encryption support.
public final class FuseDatabaseManager: FuseDatabaseManageable {
    private let dbQueue: DatabaseQueue

    /// Initializes a new database manager with a specified SQLite file path.
    /// - Parameters:
    ///   - path: The name of the SQLite database file. Defaults to "fuse.sqlite"
    ///   - encryptions: Optional encryption options. Note: Encryption is not supported in the standard version.
    /// - Throws: Database initialization errors if the file cannot be created or accessed
    public init(path: String = "fuse.sqlite", encryptions: EncryptionOptions? = nil) throws {
        if encryptions != nil {
            throw FuseDatabaseError.encryptionNotSupported
        }
        
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let url = docs.appendingPathComponent(path)
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)

        let configuration = Configuration()
        self.dbQueue = try DatabaseQueue(path: url.path, configuration: configuration)
    }

    /// Initializes a database manager with an existing database queue.
    /// - Parameter dbQueue: An existing `DatabaseQueue` instance
    init(dbQueue: DatabaseQueue) {
        self.dbQueue = dbQueue
    }

    // MARK: - Table Management

    /// Checks if a table exists in the database.
    /// - Parameter tableName: The name of the table to check
    /// - Returns: `true` if the table exists, `false` otherwise
    /// - Throws: Database operation errors
    public func tableExists(_ tableName: String) throws -> Bool {
        try dbQueue.read { db in
            try db.tableExists(tableName)
        }
    }

    /// Creates a new table in the database using the provided table definition.
    /// - Parameter definition: A `FuseTableDefinition` object containing table schema and options
    /// - Throws: Database operation errors if the table cannot be created
    public func createTable(_ definition: FuseTableDefinition) throws {
        try dbQueue.write { db in
            // 檢查表格是否已存在
            let tableExists = try db.tableExists(definition.name)
            if tableExists && !definition.options.contains(.ifNotExists) {
                throw FuseDatabaseError.tableAlreadyExists(definition.name)
            }
            
            var options: GRDB.TableOptions = []
            if definition.options.contains(.ifNotExists)  { options.insert(.ifNotExists) }
            if definition.options.contains(.temporary)    { options.insert(.temporary) }
            if definition.options.contains(.withoutRowID) { options.insert(.withoutRowID) }
            if #available(iOS 15.4, *) {
                if definition.options.contains(.strict) { options.insert(.strict) }
            }
            try db.create(table: definition.name, options: options) { t in
                for colDef in definition.columns {
                    var b = t.column(colDef.name, mapToDBColumnType(colDef.type)!)
                    if colDef.isPrimaryKey { b = b.primaryKey() }
                    if colDef.isNotNull   { b = b.notNull() }
                    if colDef.isUnique    { b = b.unique() }
                    if let def = colDef.defaultValue {
                        // Convert FuseDatabaseValueConvertible to DatabaseValueConvertible
                        if let string = def as? String { b = b.defaults(to: string) }
                        else if let int = def as? Int { b = b.defaults(to: int) }
                        else if let int64 = def as? Int64 { b = b.defaults(to: int64) }
                        else if let double = def as? Double { b = b.defaults(to: double) }
                        else if let bool = def as? Bool { b = b.defaults(to: bool) }
                        else if let date = def as? Date { b = b.defaults(to: date) }
                        else if let data = def as? Data { b = b.defaults(to: data) }
                    }
                }
            }
        }
    }

    // MARK: - Record Operations

    /// Inserts a new record into the database.
    /// - Parameter record: The record to insert
    /// - Throws: Database operation errors if the insertion fails
    public func add<T: FuseDatabaseRecord>(_ record: T) throws where T: FetchableRecord & PersistableRecord {
        let query = FuseQuery(
            table: T.databaseTableName,
            action: .insert(values: record.toDatabaseValues())
        )
        
        try write(query)
    }

    /// Inserts multiple records into the database in a single batch operation to optimize performance.
    /// - Parameter records: An array of records to be inserted.
    /// - Throws: A database error if the batch insertion fails.
    public func add<T: FuseDatabaseRecord>(_ records: [T]) throws where T: FetchableRecord & PersistableRecord {
        guard !records.isEmpty else { return }
        
        // Gather database values for all records
        let valuesArray = records.map { $0.toDatabaseValues() }
        
        // Construct a batch insert query
        let query = FuseQuery(
            table: T.databaseTableName,
            action: .insertMany(values: valuesArray)
        )
        
        // Execute the query
        try write(query)
    }

    /// Fetches records from the database with optional filtering, sorting, and pagination.
    /// - Parameters:
    ///   - type: The type of records to fetch
    ///   - filters: Array of filter conditions to apply
    ///   - sort: Optional sorting criteria
    ///   - limit: Optional maximum number of records to return
    ///   - offset: Optional number of records to skip
    /// - Returns: Array of fetched records
    /// - Throws: Database operation errors if the fetch fails
    public func fetch<T: FuseDatabaseRecord>(
        of type: T.Type,
        filters: [FuseQueryFilter] = [],
        sort: FuseQuerySort? = nil,
        limit: Int? = nil,
        offset: Int? = nil
    ) throws -> [T] where T: FetchableRecord & PersistableRecord {
        let query = FuseQuery(
             table: T.databaseTableName,
             action: .select(
               fields: ["*"],
               filters: filters,
               sort: sort,
               limit: limit,
               offset: offset
             )
           )
           
           return try read(query)
    }

    /// Deletes a record from the database.
    /// - Parameter record: The record to delete
    /// - Throws: Database operation errors if the deletion fails
    public func delete<T: FuseDatabaseRecord>(_ record: T) throws where T: FetchableRecord & PersistableRecord {
        let query = FuseQuery(
            table: T.databaseTableName,
            action: .delete(filters: [
                FuseQueryFilter.equals(field: T._fuseidField, value: record._fuseid)
            ])
        )
        
        try write(query)
    }

    /// Deletes multiple records from the database in a single transaction.
    /// - Parameter records: An array of records to delete.
    /// - Throws: Database operation errors if the deletion fails.
    public func delete<T: FuseDatabaseRecord>(_ records: [T]) throws where T: FetchableRecord & PersistableRecord {
        guard !records.isEmpty else { return }
        
        // Extract _fuseid values from all records
        let ids = records.map { $0._fuseid }
        
        // Create a batch delete query
        let query = FuseQuery(
            table: T.databaseTableName,
            action: .deleteMany(field: T._fuseidField, ids: ids)
        )
        
        // Execute the query
        try write(query)
    }

    // MARK: - Query

    /// Executes a SELECT query and returns the results as an array of records.
    /// - Parameter query: The query to execute
    /// - Returns: Array of records matching the query
    /// - Throws: Database operation errors if the query fails
    public func read<T: FuseDatabaseRecord>(_ query: FuseQuery) throws -> [T] where T: FetchableRecord & PersistableRecord {
        return try dbQueue.read { db in
            let (sql, args) = query.build()
            
            let convertedArgs = args.map { $0 as! DatabaseValueConvertible }
            let request = try T.fetchAll(db, sql: sql, arguments: StatementArguments(convertedArgs))
            return request
        }
    }

    /// Executes a read operation
    /// - Parameter sql: The SQL to execute
    /// - Parameter arguments: The arguments to pass to the SQL
    /// - Returns: Array of records matching the query
    /// - Throws: Database operation errors if the query fails
    public func read<T: FuseDatabaseRecord>(_ sql: String, arguments: some Sequence<(any FuseDatabaseValueConvertible)?>) throws -> [T] where T: FetchableRecord & PersistableRecord {
        return try dbQueue.read { db in
            let convertedArgs = arguments.map { $0 as! DatabaseValueConvertible? }
            let request = try T.fetchAll(db, sql: sql, arguments: StatementArguments(convertedArgs))
            return request
        }
    }

    /// Executes a write operation (INSERT/UPDATE/DELETE/UPSERT).
    /// - Parameter query: The query to execute
    /// - Throws: Database operation errors if the write operation fails
    public func write(_ query: FuseQuery) throws {
        let (sql, args) = query.build()
        try dbQueue.write { db in
            let convertedArgs = args.map { $0 as! DatabaseValueConvertible }
            try db.execute(sql: sql, arguments: StatementArguments(convertedArgs))
        }
    }

    /// Executes a write operation
    /// - Parameter sql: The SQL to execute
    /// - Parameter arguments: The arguments to pass to the SQL
    /// - Throws: Database operation errors if the write operation fails
    public func write(_ sql: String, arguments: some Sequence<(any FuseDatabaseValueConvertible)?>) throws {
        try dbQueue.write { db in
            let convertedArgs = arguments.map { $0 as! DatabaseValueConvertible? }
            try db.execute(sql: sql, arguments: StatementArguments(convertedArgs))
        }
    }

    // MARK: - Helpers
    private func convertToDBColumnType(_ sqlType: String) -> Database.ColumnType? {
        let up = sqlType.uppercased()
        if up.contains("TEXT")     { return .text }
        if up.contains("INTEGER")  { return .integer }
        if up.contains("REAL")     { return .real }
        if up.contains("DOUBLE")   { return .double }
        if up.contains("NUMERIC")  { return .numeric }
        if up.contains("BOOLEAN")  { return .boolean }
        if up.contains("DATE")     { return .date }
        if up.contains("DATETIME") { return .datetime }
        if up.contains("BLOB")     { return .blob }
        if up.contains("ANY")      { return .any }
        return .text
    }

    private func mapToDBColumnType(_ type: FuseColumnType) -> Database.ColumnType? {
        switch type {
        case .text:    return .text
        case .integer: return .integer
        case .real:    return .real
        case .boolean: return .boolean
        case .date:    return .datetime
        case .blob:    return .blob
        case .double:  return .double
        case .numeric: return .numeric
        case .any:     return .any
        case .custom(let s): return convertToDBColumnType(s)
        }
    }
} 