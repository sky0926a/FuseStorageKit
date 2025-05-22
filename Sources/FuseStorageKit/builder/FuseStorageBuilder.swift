import Foundation

/// Builder class for creating and configuring FuseStorageKit instances
public class FuseStorageBuilder {
    private var database: [FuseDatabaseBuilderOption] = []
    private var preferences: [FusePreferencesBuilderOption] = []
    private var file: [FuseFileBuilderOption] = []
    private var sync: [FuseSyncBuilderOption] = []

    /// Initialize a new builder with default configurations
    public init() {}

    /// Configure the database manager
    /// - Parameter databaseManager: The database manager implementation to use
    /// - Returns: Self for method chaining
    public func with(database: FuseDatabaseBuilderOption) -> Self {
        self.database.append(database)
        return self
    }

    /// Configure the preferences manager
    /// - Parameter preferencesManager: The preferences manager implementation to use
    /// - Returns: Self for method chaining
    public func with(preferences: FusePreferencesBuilderOption) -> Self {
        self.preferences.append(preferences)
        return self
    }

    /// Configure the file manager
    /// - Parameter fileManager: The file manager implementation to use
    /// - Returns: Self for method chaining
    public func with(file: FuseFileBuilderOption) -> Self {
        self.file.append(file)
        return self
    }

    /// Configure the synchronization manager
    /// - Parameter syncManager: The sync manager implementation to use
    /// - Returns: Self for method chaining
    public func with(sync: FuseSyncBuilderOption) -> Self {
        self.sync.append(sync)
        return self
    }

    /// Build a FuseStorageKit instance with the configured components
    /// - Returns: A fully configured FuseStorageKit instance
    /// - Throws: Errors during component initialization
    public func build() throws -> FuseStorage {
        database = database.isEmpty ? [.sqlite()] : database
        var databaseManager: [String: FuseDatabaseManageable] = [:]
        for db in database {
            if let manager = try db.build() as? FuseDatabaseManageable {
                databaseManager[db.query.name] = manager
            }
        }
        
        preferences = preferences.isEmpty ? [.userDefaults()] : preferences
        var preferencesManager: [String: FusePreferencesManageable] = [:]
        for pref in preferences {
            if let manager = try pref.build() as? FusePreferencesManageable {
                preferencesManager[pref.query.name] = manager
            }
        }
        
        file = file.isEmpty ? [.document()] : file
        var fileManager: [String: FuseFileManageable] = [:]
        for f in file {
            if let manager = try f.build() as? FuseFileManageable {
                fileManager[f.query.name] = manager
            }
        }
        
        sync = sync.isEmpty ? [.noSync()] : sync
        var syncManager: [String: FuseSyncManageable] = [:]
        for s in sync {
            if let manager = try s.build() as? FuseSyncManageable {
                syncManager[s.query.name] = manager
            }
        }

        return FuseStorage(
            databaseManager: databaseManager,
            preferencesManager: preferencesManager,
            fileManager: fileManager,
            syncManager: syncManager
        )
    }
} 
