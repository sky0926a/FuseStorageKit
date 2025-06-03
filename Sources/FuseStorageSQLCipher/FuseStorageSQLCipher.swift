import Foundation
@_exported import FuseStorageCore
import GRDB

// MARK: - Minimal GRDB Integration

/// Minimal GRDB factory that creates database queues
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
        return MinimalGRDBQueue(queue: grdbQueue)
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

/// Minimal queue that exposes GRDB with minimal overhead
public class MinimalGRDBQueue: FuseDatabaseQueueProtocol {
    internal let queue: DatabaseQueue
    
    public init(queue: DatabaseQueue) {
        self.queue = queue
    }
    
    public func read<T>(_ block: @escaping (FuseDatabaseConnection) throws -> T) throws -> T {
        return try queue.read { database in
            return try block(MinimalGRDBConnection(database: database))
        }
    }
    
    public func write<T>(_ block: @escaping (FuseDatabaseConnection) throws -> T) throws -> T {
        return try queue.write { database in
            return try block(MinimalGRDBConnection(database: database))
        }
    }
}

/// Minimal connection that directly uses GRDB
public class MinimalGRDBConnection: FuseDatabaseConnection {
    internal let database: Database
    
    public init(database: Database) {
        self.database = database
    }
    
    public func execute(sql: String, arguments: FuseStatementArguments) throws {
        let grdbArgs = StatementArguments((arguments.toGRDBArguments() as! [Any]).map { $0 as? DatabaseValueConvertible })
        try database.execute(sql: sql, arguments: grdbArgs)
    }
    
    public func tableExists(_ tableName: String) throws -> Bool {
        return try database.tableExists(tableName)
    }
    
    public func create(table: String, options: [String], body: (FuseTableBuilder) throws -> Void) throws {
        var grdbOptions: TableOptions = []
        options.forEach { option in
            switch option {
            case "ifNotExists": grdbOptions.insert(.ifNotExists)
            case "temporary": grdbOptions.insert(.temporary)
            case "withoutRowID": grdbOptions.insert(.withoutRowID)
            case "strict": if #available(iOS 15.4, *) { grdbOptions.insert(.strict) }
            default: break
            }
        }
        
        try database.create(table: table, options: grdbOptions) { tableDefinition in
            try body(MinimalTableBuilder(definition: tableDefinition))
        }
    }
    
    public func fetchAll<T: FuseFetchableRecord>(_ type: T.Type, sql: String, arguments: FuseStatementArguments) throws -> [T] {
        return try type.fetchAll(self, sql: sql, arguments: arguments)
    }
    
    public func fetchRows(sql: String, arguments: FuseStatementArguments) throws -> [FuseDatabaseRow] {
        let grdbArgs = StatementArguments((arguments.toGRDBArguments() as! [Any]).map { $0 as? DatabaseValueConvertible })
        let rows = try Row.fetchAll(database, sql: sql, arguments: grdbArgs)
        return rows.map { MinimalRow(row: $0) }
    }
}

/// Minimal table builder
public class MinimalTableBuilder: FuseTableBuilder {
    private let definition: TableDefinition
    
    public init(definition: TableDefinition) {
        self.definition = definition
    }
    
    public func column(_ name: String, _ type: String, isPrimaryKey: Bool = false, isNotNull: Bool = false, isUnique: Bool = false, defaultValue: FuseDatabaseValueConvertible? = nil) throws {
        let columnType: Database.ColumnType = {
            switch type.uppercased() {
            case let t where t.contains("TEXT"): return .text
            case let t where t.contains("INTEGER"): return .integer
            case let t where t.contains("REAL"): return .real
            case let t where t.contains("DOUBLE"): return .double
            case let t where t.contains("NUMERIC"): return .numeric
            case let t where t.contains("BOOLEAN"): return .boolean
            case let t where t.contains("DATE"): return .date
            case let t where t.contains("DATETIME"): return .datetime
            case let t where t.contains("BLOB"): return .blob
            case let t where t.contains("ANY"): return .any
            default: return .text
            }
        }()
        
        var column = definition.column(name, columnType)
        if isPrimaryKey { column = column.primaryKey() }
        if isNotNull { column = column.notNull() }
        if isUnique { column = column.unique() }
        if let defaultValue = defaultValue as? DatabaseValueConvertible { 
            column = column.defaults(to: defaultValue) 
        }
    }
}

/// Minimal row wrapper
public class MinimalRow: FuseDatabaseRow {
    internal let row: Row
    
    public init(row: Row) {
        self.row = row
    }
    
    public subscript(columnName: String) -> Any? {
        return row[columnName]
    }
}

// MARK: - Statement Arguments Simplification

extension FuseStatementArguments {
    /// Access to values for direct conversion to GRDB
    internal var grdbArguments: StatementArguments {
        let grdbArgs = self.toGRDBArguments() as! [Any]
        return StatementArguments(grdbArgs.map { $0 as? DatabaseValueConvertible })
    }
}

// MARK: - Automatic GRDB Conformance for FuseDatabaseRecord

/// Automatic conformance: Users only need to implement `FuseDatabaseRecord & Codable`
/// The SDK automatically provides GRDB conformance
extension FuseDatabaseRecord where Self: Codable {
    
    /// Provide default toDatabaseValues implementation using reflection
    func toDatabaseValues() -> [String: FuseDatabaseValueConvertible?] {
        var values: [String: FuseDatabaseValueConvertible?] = [:]
        let mirror = Mirror(reflecting: self)
        
        for child in mirror.children {
            guard let label = child.label else { continue }
            
            // Handle Optional values
            if let optionalValue = child.value as? OptionalValueType {
                values[label] = optionalValue.fuseDatabaseValueConvertible
            } else if let value = child.value as? FuseDatabaseValueConvertible {
                values[label] = value
            } else {
                // Fallback for unsupported types
                values[label] = String(describing: child.value)
            }
        }
        
        return values
    }
    
    /// Provide default fromDatabase implementation for Codable types
    static func fromDatabase(row: FuseDatabaseRow) throws -> Self {
        if let minimalRow = row as? MinimalRow {
            // For Codable types, we need to create a dictionary from the row
            // and then decode it using JSONDecoder with proper type conversion
            var data: [String: Any] = [:]
            
            // Detect boolean columns by examining common boolean field names
            // This is a pragmatic approach since we can't easily do reflection on the type without an instance
            let commonBooleanFieldNames = Set([
                "hasAttachment", "isActive", "isCompleted", "isPublic", "isPrivate", "isEnabled", "isDisabled",
                "isVisible", "isHidden", "isRequired", "isOptional", "isValid", "isInvalid", "isChecked",
                "isSelected", "isDeleted", "isArchived", "isFavorite", "isBookmarked", "canEdit", "canDelete",
                "canView", "canCreate", "canUpdate", "shouldSync", "shouldNotify", "willExpire"
            ])
            
            for (columnName, dbValue) in minimalRow.row {
                if let value = dbValue.storage.value {
                    // Handle SQLite type conversions for JSON compatibility
                    switch value {
                    case let intValue as Int64:
                        // Check if this column should be a boolean based on naming convention
                        if commonBooleanFieldNames.contains(columnName) {
                            data[columnName] = intValue != 0
                        } else {
                            // For integer values, keep as NSNumber to preserve type info
                            data[columnName] = NSNumber(value: intValue)
                        }
                    case let intValue as Int:
                        // Check if this column should be a boolean based on naming convention
                        if commonBooleanFieldNames.contains(columnName) {
                            data[columnName] = intValue != 0
                        } else {
                            data[columnName] = NSNumber(value: intValue)
                        }
                    case let doubleValue as Double:
                        data[columnName] = NSNumber(value: doubleValue)
                    case let boolValue as Bool:
                        data[columnName] = boolValue
                    case let stringValue as String:
                        data[columnName] = stringValue
                    case let dataValue as Data:
                        // Convert Data to Base64 string for JSON
                        data[columnName] = dataValue.base64EncodedString()
                    default:
                        data[columnName] = value
                    }
                } else {
                    data[columnName] = NSNull()
                }
            }
            
            // Convert to JSON data and decode
            let jsonData = try JSONSerialization.data(withJSONObject: data)
            let decoder = JSONDecoder()
            
            // Configure date decoding strategy to handle database date strings
            decoder.dateDecodingStrategy = .custom { decoder in
                let container = try decoder.singleValueContainer()
                
                if let dateString = try? container.decode(String.self) {
                    // Parse database date strings (GRDB format: "YYYY-MM-DD HH:MM:SS.SSS")
                    let formatter = DateFormatter()
                    formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
                    formatter.timeZone = TimeZone(secondsFromGMT: 0)
                    
                    if let date = formatter.date(from: dateString) {
                        return date
                    }
                    
                    // Try without milliseconds
                    formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                    if let date = formatter.date(from: dateString) {
                        return date
                    }
                    
                    // Try date only
                    formatter.dateFormat = "yyyy-MM-dd"
                    if let date = formatter.date(from: dateString) {
                        return date
                    }
                }
                
                // Fallback to timestamp if it's a number
                if let timestamp = try? container.decode(Double.self) {
                    return Date(timeIntervalSince1970: timestamp)
                }
                
                throw DecodingError.dataCorrupted(
                    DecodingError.Context(
                        codingPath: decoder.codingPath,
                        debugDescription: "Invalid date format"
                    )
                )
            }
            
            return try decoder.decode(Self.self, from: jsonData)
        } else {
            throw FuseDatabaseError.invalidRowData
        }
    }
}

// MARK: - Helper Protocol for Optional Value Handling

/// Helper protocol to handle Optional values in reflection
private protocol OptionalValueType {
    var fuseDatabaseValueConvertible: FuseDatabaseValueConvertible? { get }
}

extension Optional: OptionalValueType where Wrapped: FuseDatabaseValueConvertible {
    var fuseDatabaseValueConvertible: FuseDatabaseValueConvertible? {
        switch self {
        case .none:
            return nil
        case .some(let wrapped):
            return wrapped
        }
    }
}
