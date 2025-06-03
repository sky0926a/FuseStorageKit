import Foundation

/// A concrete implementation of `FuseDatabaseManageable` protocol using dependency injection.
/// This class provides a robust and type-safe interface for database operations without directly depending on GRDB.
public final class FuseDatabaseManager: FuseDatabaseManageable {
    private let dbQueue: FuseDatabaseQueueProtocol

    /// Initializes a new database manager with a specified SQLite file path.
    /// - Parameters:
    ///   - path: The name of the SQLite database file. Defaults to "fuse.sqlite"
    ///   - encryptions: Optional encryption options for database encryption. If provided, SQLCipher will be used to encrypt the database.
    /// - Throws: Database initialization errors if the file cannot be created or accessed
    public init(path: String = "fuse.sqlite", encryptions: EncryptionOptions? = nil) throws {
        // Ensure database modules are initialized before proceeding
        
        
        // Get factory from the unified registry
        guard let factory = FuseDatabaseFactoryRegistry.shared.mainFactory() else {
            throw FuseDatabaseError.noFactoryInjected
        }
        
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let url = docs.appendingPathComponent(path)
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)

        // Create database queue
        self.dbQueue = try factory.createDatabaseQueue(path: url.path, encryptionOptions: encryptions)
    }

    /// Initializes a database manager with an existing database queue.
    /// - Parameter dbQueue: An existing `FuseDatabaseQueueProtocol` instance
    public init(dbQueue: FuseDatabaseQueueProtocol) throws {
        // Ensure database modules are initialized before proceeding
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
            
            var options: [String] = []
            if definition.options.contains(.ifNotExists)  { options.append("ifNotExists") }
            if definition.options.contains(.temporary)    { options.append("temporary") }
            if definition.options.contains(.withoutRowID) { options.append("withoutRowID") }
            if #available(iOS 15.4, macOS 12.4, *) {
                if definition.options.contains(.strict) { options.append("strict") }
            }
            
            try db.create(table: definition.name, options: options) { t in
                for colDef in definition.columns {
                    try t.column(
                        colDef.name,
                        colDef.type.sqlType,
                        isPrimaryKey: colDef.isPrimaryKey,
                        isNotNull: colDef.isNotNull,
                        isUnique: colDef.isUnique,
                        defaultValue: colDef.defaultValue
                    )
                }
            }
        }
    }

    // MARK: - Record Operations

    /// Inserts a new record into the database.
    /// - Parameter record: The record to insert
    /// - Throws: Database operation errors if the insertion fails
    public func add<T: FuseDatabaseRecord>(_ record: T) throws {
        let query = FuseQuery(
            table: T.databaseTableName,
            action: .insert(values: record.toDatabaseValues())
        )
        
        try write(query)
    }

    /// Inserts multiple records into the database in a single batch operation to optimize performance.
    /// - Parameter records: An array of records to be inserted.
    /// - Throws: A database error if the batch insertion fails.
    public func add<T: FuseDatabaseRecord>(_ records: [T]) throws {
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
    ) throws -> [T] {
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
    public func delete<T: FuseDatabaseRecord>(_ record: T) throws {
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
    public func delete<T: FuseDatabaseRecord>(_ records: [T]) throws {
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
    public func read<T: FuseDatabaseRecord>(_ query: FuseQuery) throws -> [T] {
        return try dbQueue.read { db in
            let (sql, args) = query.build()
            
            return try T.fetchAll(db, sql: sql, arguments: FuseStatementArguments(args))
        }
    }

    /// Executes a read operation
    /// - Parameter sql: The SQL to execute
    /// - Parameter arguments: The arguments to pass to the SQL
    /// - Returns: Array of records matching the query
    /// - Throws: Database operation errors if the query fails
    public func read<T: FuseDatabaseRecord>(_ sql: String, arguments: some Sequence<(any FuseDatabaseValueConvertible)?>) throws -> [T] {
        return try dbQueue.read { db in
            return try T.fetchAll(db, sql: sql, arguments: FuseStatementArguments(arguments))
        }
    }

    /// Executes a write operation (INSERT/UPDATE/DELETE/UPSERT).
    /// - Parameter query: The query to execute
    /// - Throws: Database operation errors if the write operation fails
    public func write(_ query: FuseQuery) throws {
        let (sql, args) = query.build()
        try dbQueue.write { db in
            try db.execute(sql: sql, arguments: FuseStatementArguments(args))
        }
    }

    /// Executes a write operation
    /// - Parameter sql: The SQL to execute
    /// - Parameter arguments: The arguments to pass to the SQL
    /// - Throws: Database operation errors if the write operation fails
    public func write(_ sql: String, arguments: some Sequence<(any FuseDatabaseValueConvertible)?>) throws {
        try dbQueue.write { db in
            try db.execute(sql: sql, arguments: FuseStatementArguments(arguments))
        }
    }
    
    // MARK: - Debug/Testing Methods
    
    /// Executes a SELECT query and returns raw database rows for debugging/testing purposes.
    /// - Parameter sql: The SQL query to execute
    /// - Parameter arguments: The arguments to pass to the SQL query
    /// - Returns: Array of raw database rows
    /// - Throws: Database operation errors if the query fails
    public func debugFetchRows(_ sql: String, arguments: [FuseDatabaseValueConvertible] = []) throws -> [FuseDatabaseRow] {
        return try dbQueue.read { db in
            try db.fetchRows(sql: sql, arguments: FuseStatementArguments(arguments))
        }
    }
}
