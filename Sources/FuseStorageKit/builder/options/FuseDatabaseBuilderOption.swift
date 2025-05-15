import Foundation

/// Internal enumeration defining the types of database configurations available
enum FuseDatabaseBuilderOptionType {
    case sqlite(path: String, encryptions: EncryptionOptions?)
    case custom(name: String, database: FuseDatabaseManageable)
}

/// Builder option for configuring database managers in FuseStorageKit
/// 
/// This structure provides factory methods for creating different types of database
/// configurations, including SQLite databases with optional encryption and custom
/// database implementations. It implements the builder pattern for flexible
/// database manager configuration.
public struct FuseDatabaseBuilderOption: FuseStorageBuilderOption {
    private let optionType: FuseDatabaseBuilderOptionType

    init(optionType: FuseDatabaseBuilderOptionType) {
        self.optionType = optionType
    }
    
    /// Creates a SQLite database configuration with optional encryption
    /// 
    /// This factory method configures a SQLite database manager with the specified
    /// file path and optional encryption settings. The database will be created
    /// in the app's Documents directory.
    /// 
    /// - Parameters:
    ///   - path: The SQLite database filename. Defaults to the standard database name
    ///   - encryptions: Optional encryption configuration for database security
    /// - Returns: A configured database builder option
    public static func sqlite(_ path: String = FuseConstants.databaseName, encryptions: EncryptionOptions? = nil) -> Self {
        return .init(optionType: .sqlite(path: path, encryptions: encryptions))
    }
    
    /// Creates a custom database configuration using a provided database manager
    /// 
    /// This factory method allows integration of custom database implementations
    /// that conform to FuseDatabaseManageable, providing flexibility for specialized
    /// database requirements or third-party database solutions.
    /// 
    /// - Parameters:
    ///   - name: A unique identifier for this database configuration
    ///   - database: The custom database manager implementation
    /// - Returns: A configured database builder option
    public static func custom(_ name: String, database: FuseDatabaseManageable) -> Self {
        return .init(optionType: .custom(name: name, database: database))
    }
    
    public func build() throws -> FuseManageable {
        switch self.optionType {
        case .sqlite(let path, let encryptions):
            return try FuseDatabaseManager(path: path, encryptions: encryptions)
        case .custom(_, let database):
            return database
        }
    }
    
    public var name: String {
        switch self.optionType {
        case .sqlite(let path, _):
            return "db_sqlite_\(path)"
        case .custom(let name, _):
            return "db_custom_\(name)"
        }
    }
}
