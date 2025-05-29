import Foundation
@_exported import FuseStorageCore
import GRDB

/// Global function to ensure FuseStorageSQLCipher is initialized
/// This function can be called from anywhere to guarantee initialization
public func ensureFuseStorageSQLCipherInitialized() {
    FuseStorageSQLCipher.ensureInitialized()
}

/// This variable triggers module initialization as soon as the module is loaded
/// The underscore prefix indicates it's an internal implementation detail
public let _fuseStorageSQLCipherModuleInitialized: Bool = {
    FuseStorageSQLCipher.initialize()
    return true
}()

/// FuseStorageSQLCipher module entry point
/// This module provides SQLCipher-based database implementations for FuseStorageCore
public struct FuseStorageSQLCipher {
    /// Returns the version of the FuseStorageSQLCipher module
    public static let version = "1.0.0"
    
    /// Thread-safe initialization flag
    private static var isInitialized = false
    private static let initializationLock = NSLock()
    
    /// Initialize the SQLCipher module and register the GRDB factory
    /// This method is safe to call multiple times
    public static func initialize() {
        initializationLock.lock()
        defer { initializationLock.unlock() }
        
        guard !isInitialized else {
            return // Already initialized
        }
        
        // Register the GRDB factory as the default implementation
        FuseDatabaseFactoryRegistry.setDefaultFactory(GRDBSQLCipherDatabaseFactory())
        isInitialized = true
        print("FuseStorageSQLCipher module initialized with GRDB factory")
    }
    
    /// Ensures that the module is initialized
    /// This is a safe method that can be called from anywhere to guarantee initialization
    public static func ensureInitialized() {
        _ = _fuseStorageSQLCipherModuleInitialized // This ensures initialize() is called
    }
    
    /// Returns whether the module has been initialized
    public static var initialized: Bool {
        initializationLock.lock()
        defer { initializationLock.unlock() }
        return isInitialized
    }
}

/// Helper class to make static methods available to Objective-C runtime
@objc public class FuseStorageSQLCipherHelper: NSObject {
    @objc public static func ensureInitialized() {
        FuseStorageSQLCipher.ensureInitialized()
    }
}

// MARK: - GRDB Implementation

/// GRDB SQLCipher implementation of the database factory
public struct GRDBSQLCipherDatabaseFactory: FuseDatabaseFactory {
    public init() {
        // Note: We don't call ensureInitialized() here to avoid potential circular dependencies
        // The initialization should happen when the module is first imported
    }
    
    public func createDatabaseQueue(path: String, encryptionOptions: EncryptionOptions?) throws -> FuseDatabaseQueueProtocol {
        var configuration = Configuration()
        if let encryptionOptions = encryptionOptions {
            configuration.prepareDatabase { db in
                try applyEncryptionOptions(encryptionOptions, to: db)
            }
        }
        let grdbQueue = try DatabaseQueue(path: path, configuration: configuration)
        return GRDBDatabaseQueueWrapper(databaseQueue: grdbQueue)
    }
    
    private func applyEncryptionOptions(_ options: EncryptionOptions, to db: Database) throws {
        guard !options.passphrase.isEmpty else {
            throw FuseDatabaseError.missingPassphrase
        }
        
        try db.usePassphrase(options.passphrase)

        if let pageSize = options.pageSize {
            try db.execute(sql: "PRAGMA cipher_page_size = \(pageSize)")
        }
        if let kdfIter = options.kdfIter {
            try db.execute(sql: "PRAGMA kdf_iter = \(kdfIter)")
        }
        if options.memorySecurity == true {
            try db.execute(sql: "PRAGMA cipher_memory_security = ON")
        }
        if let defaultKdf = options.defaultKdfIter {
            try db.execute(sql: "PRAGMA cipher_default_kdf_iter = \(defaultKdf)")
        }
        if let defaultPage = options.defaultPageSize {
            try db.execute(sql: "PRAGMA cipher_default_page_size = \(defaultPage)")
        }
    }
}

/// GRDB wrapper for DatabaseQueue
public class GRDBDatabaseQueueWrapper: FuseDatabaseQueueProtocol {
    private let databaseQueue: DatabaseQueue
    
    public init(databaseQueue: DatabaseQueue) {
        self.databaseQueue = databaseQueue
    }
    
    public func read<T>(_ block: @escaping (FuseDatabaseConnection) throws -> T) throws -> T {
        return try databaseQueue.read { database in
            let wrapper = GRDBDatabaseConnectionWrapper(database: database)
            return try block(wrapper)
        }
    }
    
    public func write<T>(_ block: @escaping (FuseDatabaseConnection) throws -> T) throws -> T {
        return try databaseQueue.write { database in
            let wrapper = GRDBDatabaseConnectionWrapper(database: database)
            return try block(wrapper)
        }
    }
}

/// GRDB wrapper for Database connection
public class GRDBDatabaseConnectionWrapper: FuseDatabaseConnection {
    private let database: Database
    
    public init(database: Database) {
        self.database = database
    }
    
    public func execute(sql: String, arguments: FuseStatementArguments) throws {
        let grdbArguments = convertToGRDBArguments(arguments)
        try database.execute(sql: sql, arguments: grdbArguments)
    }
    
    public func tableExists(_ tableName: String) throws -> Bool {
        return try database.tableExists(tableName)
    }
    
    public func create(table: String, options: [String], body: (FuseTableBuilder) throws -> Void) throws {
        var grdbOptions: TableOptions = []
        
        for option in options {
            switch option {
            case "ifNotExists": grdbOptions.insert(.ifNotExists)
            case "temporary": grdbOptions.insert(.temporary)
            case "withoutRowID": grdbOptions.insert(.withoutRowID)
            case "strict":
                if #available(iOS 15.4, *) {
                    grdbOptions.insert(.strict)
                }
            default: break
            }
        }
        
        try database.create(table: table, options: grdbOptions) { tableDefinition in
            let fuseTableBuilder = GRDBTableBuilderWrapper(tableDefinition: tableDefinition)
            try body(fuseTableBuilder)
        }
    }
    
    public func fetchAll<T: FuseFetchableRecord>(_ type: T.Type, sql: String, arguments: FuseStatementArguments) throws -> [T] {
        // Use the default implementation provided by FuseFetchableRecord
        return try type.fetchAll(self, sql: sql, arguments: arguments)
    }
    
    public func fetchRows(sql: String, arguments: FuseStatementArguments) throws -> [FuseDatabaseRow] {
        let grdbArguments = convertToGRDBArguments(arguments)
        let rows = try Row.fetchAll(database, sql: sql, arguments: grdbArguments)
        return rows.map { GRDBRowWrapper(row: $0) }
    }
    
    private func convertToGRDBArguments(_ fuseArguments: FuseStatementArguments) -> StatementArguments {
        // Convert our abstract arguments to GRDB StatementArguments
        let rawArguments = fuseArguments.toGRDBArguments() as! [Any]
        let grdbArguments: [DatabaseValueConvertible?] = rawArguments.map { value in
            // Convert Any back to DatabaseValueConvertible
            if value is NSNull {
                return nil
            } else if let dbValue = value as? DatabaseValueConvertible {
                return dbValue
            } else {
                // Fallback for other types
                return String(describing: value)
            }
        }
        return StatementArguments(grdbArguments)
    }
}

/// GRDB wrapper for TableDefinition
public class GRDBTableBuilderWrapper: FuseTableBuilder {
    private let tableDefinition: TableDefinition
    
    public init(tableDefinition: TableDefinition) {
        self.tableDefinition = tableDefinition
    }
    
    public func column(_ name: String, _ type: String, isPrimaryKey: Bool = false, isNotNull: Bool = false, isUnique: Bool = false, defaultValue: FuseDatabaseValueConvertible? = nil) throws {
        let columnType = convertToDBColumnType(type)
        var column = tableDefinition.column(name, columnType)
        
        if isPrimaryKey { column = column.primaryKey() }
        if isNotNull { column = column.notNull() }
        if isUnique { column = column.unique() }
        if let defaultValue = defaultValue as? DatabaseValueConvertible { 
            column = column.defaults(to: defaultValue) 
        }
    }
    
    private func convertToDBColumnType(_ sqlType: String) -> Database.ColumnType {
        let up = sqlType.uppercased()
        if up.contains("TEXT") { return .text }
        if up.contains("INTEGER") { return .integer }
        if up.contains("REAL") { return .real }
        if up.contains("DOUBLE") { return .double }
        if up.contains("NUMERIC") { return .numeric }
        if up.contains("BOOLEAN") { return .boolean }
        if up.contains("DATE") { return .date }
        if up.contains("DATETIME") { return .datetime }
        if up.contains("BLOB") { return .blob }
        if up.contains("ANY") { return .any }
        return .text
    }
}

/// GRDB wrapper for Row
public class GRDBRowWrapper: FuseDatabaseRow {
    private let row: Row
    
    public init(row: Row) {
        self.row = row
    }
    
    public subscript(columnName: String) -> Any? {
        return row[columnName]
    }
    
    /// Expose the underlying GRDB row for internal use
    internal var grdbRow: Row {
        return row
    }
}

// MARK: - GRDB Integration Helpers

/// Helper function to convert GRDB DatabaseValue to FuseDatabaseValueConvertible
public func convertGRDBValueToFuseValue(_ value: DatabaseValue) -> FuseDatabaseValueConvertible? {
    if value.isNull {
        return nil
    }
    
    // Try different types in order of preference
    if let stringValue = String.fromDatabaseValue(value) {
        return stringValue
    }
    if let int64Value = Int64.fromDatabaseValue(value) {
        return int64Value
    }
    if let doubleValue = Double.fromDatabaseValue(value) {
        return doubleValue
    }
    if let boolValue = Bool.fromDatabaseValue(value) {
        return boolValue
    }
    if let dateValue = Date.fromDatabaseValue(value) {
        return dateValue
    }
    if let dataValue = Data.fromDatabaseValue(value) {
        return dataValue
    }
    
    // Fallback to string representation
    return value.description
}

/// Helper function to convert FuseDatabaseValueConvertible to GRDB DatabaseValue
public func convertFuseValueToGRDBValue(_ value: FuseDatabaseValueConvertible?) -> DatabaseValue {
    guard let value = value else {
        return .null
    }
    
    if let databaseValueConvertible = value as? DatabaseValueConvertible {
        return databaseValueConvertible.databaseValue
    }
    
    // Fallback for other types
    return String(describing: value).databaseValue
} 
