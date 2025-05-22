import Foundation

/// Main facade for the FuseStorageKit providing unified access to storage services
public final class FuseStorage {
    public let database: [String: FuseDatabaseManageable]
    public let preferences: [String: FusePreferencesManageable]
    public let file: [String: FuseFileManageable]
    public let sync: [String: FuseSyncManageable]

    /// Initialize with all dependencies
    /// - Parameters:
    ///   - databaseManager: The database manager for data persistence
    ///   - preferencesManager: The preferences manager for user settings
    ///   - fileManager: The file manager for file operations
    ///   - syncManager: The sync manager for data synchronization
    init(databaseManager: [String: FuseDatabaseManageable],
         preferencesManager: [String: FusePreferencesManageable],
         fileManager: [String: FuseFileManageable],
         syncManager: [String: FuseSyncManageable]) {
        self.database = databaseManager
        self.preferences = preferencesManager
        self.file = fileManager
        self.sync = syncManager
    }

    func db(_ query: FuseDatabaseOptionQuery) -> FuseDatabaseManageable? {
        return database[query.name]
    }

    func pref(_ query: FusePreferencesOptionQuery) -> FusePreferencesManageable? {
        return preferences[query.name]
    }
    
    func file(_ query: FuseFileOptionQuery) -> FuseFileManageable? {
        return file[query.name]
    }

    func sync(_ query: FuseSyncOptionQuery) -> FuseSyncManageable? {
        return sync[query.name]
    }
}
