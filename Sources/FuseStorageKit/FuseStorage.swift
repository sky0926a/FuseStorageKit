import Foundation

/// Main facade for the FuseStorageKit providing unified access to storage services
public final class FuseStorage {
    public let databaseManagers: [String: FuseDatabaseManageable]
    public let preferencesManagers: [String: FusePreferencesManageable]
    public let fileManagers: [String: FuseFileManageable]
    public let syncManagers: [String: FuseSyncManageable]

    /// Initialize with all dependencies
    /// - Parameters:
    ///   - databaseManager: The database manager for data persistence
    ///   - preferencesManager: The preferences manager for user settings
    ///   - fileManager: The file manager for file operations
    ///   - syncManager: The sync manager for data synchronization
    init(databaseManagers: [String: FuseDatabaseManageable],
         preferencesManagers: [String: FusePreferencesManageable],
         fileManagers: [String: FuseFileManageable],
         syncManagers: [String: FuseSyncManageable]) {
        self.databaseManagers = databaseManagers
        self.preferencesManagers = preferencesManagers
        self.fileManagers = fileManagers
        self.syncManagers = syncManagers
    }

    func db(_ query: FuseDatabaseOptionQuery) -> FuseDatabaseManageable? {
        return databaseManagers[query.name]
    }

    func pref(_ query: FusePreferencesOptionQuery) -> FusePreferencesManageable? {
        return preferencesManagers[query.name]
    }
    
    func file(_ query: FuseFileOptionQuery) -> FuseFileManageable? {
        return fileManagers[query.name]
    }

    func sync(_ query: FuseSyncOptionQuery) -> FuseSyncManageable? {
        return syncManagers[query.name]
    }
}
