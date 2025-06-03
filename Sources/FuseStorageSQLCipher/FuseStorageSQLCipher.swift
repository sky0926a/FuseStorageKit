import Foundation
@_exported import FuseStorageCore
import GRDB

// MARK: - GRDB Implementation

/// Concrete GRDB SQLCipher implementation of the database factory
public class GRDBSQLCipherDatabaseFactory: NSObject, FuseDatabaseFactory {
    public override init() {
        super.init()
    }
    
    public func createDatabaseQueue(path: String, encryptionOptions: EncryptionOptions?) throws -> FuseDatabaseQueueProtocol {
        var configuration = Configuration()
        if let encryptionOptions = encryptionOptions {
            configuration.prepareDatabase { db in
                try self.applyEncryptionOptions(encryptionOptions, to: db)
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

// MARK: - GRDB Extensions for FuseDatabaseRecord

/// Extension to provide GRDB-specific implementations for FuseDatabaseRecord
public extension FuseDatabaseRecord where Self: Codable {
    /// GRDB implementation of toDatabaseValues using reflection
    func toDatabaseValues() -> [String: FuseDatabaseValueConvertible?] {
        var values: [String: FuseDatabaseValueConvertible?] = [:]
        
        let mirror = Mirror(reflecting: self)
        for child in mirror.children {
            guard let label = child.label else { continue }
            
            // Convert the value to FuseDatabaseValueConvertible
            if let convertibleValue = child.value as? FuseDatabaseValueConvertible {
                values[label] = convertibleValue
            } else if let optionalValue = child.value as? any OptionalType {
                values[label] = optionalValue.wrappedValue as? FuseDatabaseValueConvertible
            } else {
                // Handle other types by converting to string as fallback
                values[label] = String(describing: child.value)
            }
        }
        
        return values
    }
    
    /// GRDB implementation of fromDatabase using JSON decoding
    static func fromDatabase(row: FuseDatabaseRow) throws -> Self {
        // Create a dictionary from the row data
        var jsonDict: [String: Any] = [:]
        
        // Get all properties from the type using reflection on a default instance
        let mirror = Mirror(reflecting: try createDefaultInstance())
        for child in mirror.children {
            guard let label = child.label else { continue }
            
            if let value = row[label] {
                // Convert values to JSON-compatible types
                if let grdbRow = row as? GRDBRowWrapper {
                    // Use the GRDB Row subscript to get DatabaseValue
                    let grdbValue: DatabaseValue = grdbRow.grdbRow[label]
                    jsonDict[label] = convertGRDBDatabaseValueToJSON(grdbValue)
                } else {
                    jsonDict[label] = value
                }
            }
        }
        
        // Convert to JSON data and decode
        let jsonData = try JSONSerialization.data(withJSONObject: jsonDict)
        return try JSONDecoder().decode(Self.self, from: jsonData)
    }
    
    /// Helper method to create a default instance for reflection
    private static func createDefaultInstance() throws -> Self {
        // Try to decode from empty JSON first (works if all properties are optional or have default values)
        if let instance = try? JSONDecoder().decode(Self.self, from: Data("{}".utf8)) {
            return instance
        }
        
        // If that fails, try to create an instance with null values for all properties
        // This is a more complex approach, but for now we'll use a simpler fallback
        throw FuseDatabaseError.invalidRecordType
    }
}

/// Helper protocol to work with Optional types
private protocol OptionalType {
    var wrappedValue: Any? { get }
}

extension Optional: OptionalType {
    var wrappedValue: Any? {
        switch self {
        case .none: return nil
        case .some(let value): return value
        }
    }
}

/// Helper function to convert GRDB DatabaseValue to JSON-compatible types
private func convertGRDBDatabaseValueToJSON(_ value: DatabaseValue) -> Any? {
    if value.isNull {
        return nil
    }
    
    // Try different types in order
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
    if let dataValue = Data.fromDatabaseValue(value) {
        return dataValue
    }
    
    // Fallback
    return value.description
} 
