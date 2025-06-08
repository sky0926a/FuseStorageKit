import Foundation

// MARK: - Database Value Protocols
/// A protocol that abstracts database value conversion without depending on specific database implementations
public protocol FuseDatabaseValueConvertible {
    /// Convert this value to a database-compatible representation
    var fuseDatabaseValue: Any { get }
}

// Make standard types conform to our protocol
extension String: FuseDatabaseValueConvertible {
    public var fuseDatabaseValue: Any { return self }
}

extension Int: FuseDatabaseValueConvertible {
    public var fuseDatabaseValue: Any { return self }
}

extension Int64: FuseDatabaseValueConvertible {
    public var fuseDatabaseValue: Any { return self }
}

extension Double: FuseDatabaseValueConvertible {
    public var fuseDatabaseValue: Any { return self }
}

extension Bool: FuseDatabaseValueConvertible {
    public var fuseDatabaseValue: Any { return self }
}

extension Date: FuseDatabaseValueConvertible {
    public var fuseDatabaseValue: Any { return self }
}

extension Data: FuseDatabaseValueConvertible {
    public var fuseDatabaseValue: Any { return self }
}

extension NSNull: FuseDatabaseValueConvertible {
    public var fuseDatabaseValue: Any { return self }
}

extension Optional: FuseDatabaseValueConvertible where Wrapped: FuseDatabaseValueConvertible {
    public var fuseDatabaseValue: Any {
        switch self {
        case .none:
            return NSNull()
        case .some(let wrapped):
            return wrapped.fuseDatabaseValue
        }
    }
}

// MARK: - Database Row Protocol
/// A protocol that abstracts database row access
public protocol FuseDatabaseRow {
    subscript(columnName: String) -> Any? { get }
    
    /// Get all available column names in this row
    var columnNames: [String] { get }
}

// MARK: - Statement Arguments Protocol
/// A protocol that abstracts statement arguments for database queries
public protocol FuseStatementArgumentsProtocol {
    init<S: Sequence>(_ arguments: S) where S.Element == (any FuseDatabaseValueConvertible)?
}

/// A wrapper for statement arguments that can be used across different database implementations
public struct FuseStatementArguments: FuseStatementArgumentsProtocol {
    private let arguments: [(any FuseDatabaseValueConvertible)?]
    
    public init<S: Sequence>(_ arguments: S) where S.Element == (any FuseDatabaseValueConvertible)? {
        self.arguments = Array(arguments)
    }
    
    public func toGRDBArguments() -> Any {
        // Convert our abstract values to concrete database values
        return arguments.map { argument in
            if let arg = argument {
                return arg.fuseDatabaseValue
            } else {
                return NSNull()
            }
        }
    }
}

// MARK: - Database Connection Protocol
/// A protocol that abstracts database connection operations
public protocol FuseDatabaseConnection {
    func execute(sql: String, arguments: FuseStatementArguments) throws
    func tableExists(_ tableName: String) throws -> Bool
    func create(table: String, options: [String], body: (FuseTableBuilder) throws -> Void) throws
    func fetchAll<T: FuseFetchableRecord>(_ type: T.Type, sql: String, arguments: FuseStatementArguments) throws -> [T]
    func fetchRows(sql: String, arguments: FuseStatementArguments) throws -> [FuseDatabaseRow]
}

// MARK: - Table Builder Protocol
/// A protocol that abstracts table building operations
public protocol FuseTableBuilder {
    func column(_ name: String, _ type: String, isPrimaryKey: Bool, isNotNull: Bool, isUnique: Bool, defaultValue: FuseDatabaseValueConvertible?) throws
}

// MARK: - Database Queue Protocol
/// A protocol that abstracts database queue operations
public protocol FuseDatabaseQueueProtocol {
    func read<T>(_ block: @escaping (FuseDatabaseConnection) throws -> T) throws -> T
    func write<T>(_ block: @escaping (FuseDatabaseConnection) throws -> T) throws -> T
}

// MARK: - Record Protocols
/// A protocol that abstracts fetchable record operations
public protocol FuseFetchableRecord {
    /// Creates an instance from a database row
    static func fromDatabase(row: FuseDatabaseRow) throws -> Self
    
    /// Fetches all records from the database using a SQL query
    static func fetchAll(_ db: FuseDatabaseConnection, sql: String, arguments: FuseStatementArguments) throws -> [Self]
}

// Provide default implementation for fetchAll
public extension FuseFetchableRecord {
    static func fetchAll(_ db: FuseDatabaseConnection, sql: String, arguments: FuseStatementArguments) throws -> [Self] {
        let rows = try db.fetchRows(sql: sql, arguments: arguments)
        return try rows.map { try Self.fromDatabase(row: $0) }
    }
}

/// A protocol that abstracts persistable record operations
public protocol FusePersistableRecord {}

// MARK: - Database Factory
/// A protocol for creating database queues
public protocol FuseDatabaseFactory {
    func createDatabaseQueue(path: String, encryptionOptions: EncryptionOptions?) throws -> FuseDatabaseQueueProtocol
}

// MARK: - Database Factory Registry
/// Registry for managing database factory implementations
public class FuseDatabaseFactoryRegistry {
    public static let shared = FuseDatabaseFactoryRegistry()
    
    private var registeredFactory: FuseDatabaseFactory?
    private let lock = NSLock()
    
    private init() {
//        tryFactoryRegistration()
    }
    
    /// Register a database factory implementation
    /// This is typically called by database implementation modules during their initialization
    public func setMainFactory(_ factory: FuseDatabaseFactory) {
        lock.lock()
        defer { lock.unlock() }
        registeredFactory = factory
    }
    
    /// Get the currently registered factory
    /// Returns nil if no factory has been registered
    func mainFactory() -> FuseDatabaseFactory? {
        lock.lock()
        defer { lock.unlock() }
        return registeredFactory
    }
    
    private func tryFactoryRegistration() {
        #if use_sqlcipher
        let factoryClassName = "FuseStorageSQLCipher.FuseGRDBDatabaseFactory"
        #else
        let factoryClassName = "FuseStorageSQLCipher.FuseGRDBDatabaseFactory"
        #endif
        
        if let factoryClass = NSClassFromString(factoryClassName) as? NSObject.Type {
            // If the class exists, try to create an instance which should trigger registration
            if let factory = factoryClass.init() as? FuseDatabaseFactory {
                setMainFactory(factory)
            }
        }
    }
}
