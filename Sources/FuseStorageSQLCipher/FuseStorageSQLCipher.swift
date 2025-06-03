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
    
    /// Get all available column names in this row
    public var columnNames: [String] {
        return Array(row.columnNames)
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
