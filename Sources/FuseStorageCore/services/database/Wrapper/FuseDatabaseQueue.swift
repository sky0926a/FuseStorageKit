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

// MARK: - Module System

/// A protocol for modules that can be automatically initialized
public protocol FuseStorageModule {
    /// The name of the module for identification purposes
    static var moduleName: String { get }
    
    /// Initialize the module and register its services
    static func initialize()
    
    /// Check if the module has been initialized
    static var initialized: Bool { get }
}

/// Registry for managing FuseStorage modules and services
public class FuseStorageModuleRegistry {
    private static var registeredModules: [String: FuseStorageModule.Type] = [:]
    private static var initializedModules: Set<String> = []
    private static var defaultDatabaseFactory: FuseDatabaseFactory?
    private static let lock = NSLock()
    
    /// Register a module for automatic initialization
    /// - Parameter moduleType: The module type to register
    public static func registerModule(_ moduleType: FuseStorageModule.Type) {
        lock.lock()
        defer { lock.unlock() }
        registeredModules[moduleType.moduleName] = moduleType
    }
    
    /// Initialize all registered modules
    public static func initializeAllModules() {
        lock.lock()
        defer { lock.unlock() }
        
        for (moduleName, moduleType) in registeredModules {
            if !initializedModules.contains(moduleName) {
                moduleType.initialize()
                initializedModules.insert(moduleName)
            }
        }
    }
    
    /// Check if a specific module is initialized
    /// - Parameter moduleName: The name of the module to check
    /// - Returns: True if the module is initialized
    public static func isModuleInitialized(_ moduleName: String) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        return initializedModules.contains(moduleName)
    }
    
    /// Get list of all registered modules
    /// - Returns: Array of module names
    public static func getRegisteredModules() -> [String] {
        lock.lock()
        defer { lock.unlock() }
        return Array(registeredModules.keys)
    }
    
    // MARK: - Database Factory Management
    
    /// Sets the default database factory
    /// - Parameter factory: The factory to use as default
    public static func setDefaultDatabaseFactory(_ factory: FuseDatabaseFactory) {
        lock.lock()
        defer { lock.unlock() }
        defaultDatabaseFactory = factory
    }
    
    /// Gets the default database factory
    /// - Returns: The default factory, or throws an error if none is set
    public static func getDefaultDatabaseFactory() throws -> FuseDatabaseFactory {
        lock.lock()
        defer { lock.unlock() }
        
        // If no factory is available, try running initialization hooks
        if defaultDatabaseFactory == nil {
            lock.unlock() // Release lock temporarily to avoid deadlock
            initializeAllModules()
            lock.lock()
        }
        
        guard let factory = defaultDatabaseFactory else {
            throw FuseDatabaseError.noFactoryInjected
        }
        return factory
    }
    
    /// Checks if a default database factory is available
    /// - Returns: True if a factory is available
    public static func hasDefaultDatabaseFactory() -> Bool {
        lock.lock()
        defer { lock.unlock() }
        return defaultDatabaseFactory != nil
    }
    
    /// Clears all registrations (useful for testing)
    public static func clearAll() {
        lock.lock()
        defer { lock.unlock() }
        registeredModules.removeAll()
        initializedModules.removeAll()
        defaultDatabaseFactory = nil
    }
}

/// Convenience function to ensure database modules are initialized
public func ensureDatabaseModulesInitialized() {
    // Trigger module initialization
    FuseStorageModuleRegistry.initializeAllModules()
    
    // If still no factory after module initialization, provide helpful guidance
    if !FuseStorageModuleRegistry.hasDefaultDatabaseFactory() {
        print("Warning: No database factory registered after module initialization.")
        print("Make sure to 'import FuseStorageSQLCipher' in your code to enable SQLCipher database support.")
        print("The FuseStorageSQLCipher module provides GRDB-based SQLite database functionality.")
    }
}
