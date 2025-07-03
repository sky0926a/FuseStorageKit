import Foundation
internal import GRDB
@_exported import FuseStorageCore

/// Minimal queue that exposes GRDB with minimal overhead
class FuseGRDBDatabaseQueue: FuseDatabaseQueueProtocol {
    internal let queue: DatabaseQueue
    
    init(queue: DatabaseQueue) {
        self.queue = queue
    }
    
    func read<T>(_ block: @escaping (FuseDatabaseConnection) throws -> T) throws -> T {
        return try queue.read { database in
            return try block(FuseGRDBConnection(database: database))
        }
    }
    
    func write<T>(_ block: @escaping (FuseDatabaseConnection) throws -> T) throws -> T {
        return try queue.write { database in
            return try block(FuseGRDBConnection(database: database))
        }
    }
}

/// Minimal connection that directly uses GRDB
class FuseGRDBConnection: FuseDatabaseConnection {
    internal let database: Database
    
    init(database: Database) {
        self.database = database
    }
    
    func execute(sql: String, arguments: FuseStatementArguments) throws {
        let grdbArgs = StatementArguments((arguments.toGRDBArguments() as! [Any]).map { $0 as? DatabaseValueConvertible })
        try database.execute(sql: sql, arguments: grdbArgs)
    }
    
    func tableExists(_ tableName: String) throws -> Bool {
        return try database.tableExists(tableName)
    }
    
    func create(table: String, options: [String], body: (FuseTableBuilder) throws -> Void) throws {
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
            try body(FuseGRDBTableBuilder(definition: tableDefinition))
        }
    }
    
    func fetchAll<T: FuseFetchableRecord>(_ type: T.Type, sql: String, arguments: FuseStatementArguments) throws -> [T] {
        return try type.fetchAll(self, sql: sql, arguments: arguments)
    }
    
    func fetchRows(sql: String, arguments: FuseStatementArguments) throws -> [FuseDatabaseRow] {
        let grdbArgs = StatementArguments((arguments.toGRDBArguments() as! [Any]).map { $0 as? DatabaseValueConvertible })
        let rows = try Row.fetchAll(database, sql: sql, arguments: grdbArgs)
        return rows.map { FuseGRDBDatabaseRow(row: $0) }
    }
}

/// Fuse GRDB table builder
class FuseGRDBTableBuilder: FuseTableBuilder {
    private let definition: TableDefinition
    
    init(definition: TableDefinition) {
        self.definition = definition
    }
    
    func column(_ name: String, _ type: String, isPrimaryKey: Bool = false, isNotNull: Bool = false, isUnique: Bool = false, defaultValue: FuseDatabaseValueConvertible? = nil) throws {
        let columnType = FuseColumnType.sqlType(type)
        
        var column = definition.column(name, columnType.sqlType)
        if isPrimaryKey { column = column.primaryKey() }
        if isNotNull { column = column.notNull() }
        if isUnique { column = column.unique() }
        if let defaultValue = defaultValue as? DatabaseValueConvertible { 
            column = column.defaults(to: defaultValue) 
        }
    }
}

/// Fuse GRDB row wrapper
class FuseGRDBDatabaseRow: FuseDatabaseRow {
    internal let row: Row
    
    init(row: Row) {
        self.row = row
    }
    
    subscript(columnName: String) -> Any? {
        return row[columnName]
    }
    
    /// Get all available column names in this row
    var columnNames: [String] {
        return Array(row.columnNames)
    }
}

// MARK: - Statement Arguments Simplification

extension FuseStatementArguments {
    /// Access to values for direct conversion to GRDB
    var grdbArguments: StatementArguments {
        let grdbArgs = self.toGRDBArguments() as! [Any]
        return StatementArguments(grdbArgs.map { $0 as? DatabaseValueConvertible })
    }
}

extension FuseColumnType {
    var sqlType: Database.ColumnType {
        switch self {
        case .text: return .text
        case .integer: return .integer
        case .real: return .real
        case .double: return .double
        case .numeric: return .numeric
        case .boolean: return .boolean
        case .date: return .date
        case .blob: return .blob
        case .any: return .any
        @unknown default:
            return .text
        }
    }
}

