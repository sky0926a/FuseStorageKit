import Foundation

/// Main facade for the FuseStorageKit providing unified access to storage services
public final class FuseStorage {
    private var databaseManagers: [String: FuseDatabaseManageable]
    private var preferencesManagers: [String: FusePreferencesManageable]
    private var fileManagers: [String: FuseFileManageable]
    private var syncManagers: [String: FuseSyncManageable]

    /// Initialize with all dependencies
    /// - Parameters:
    ///   - databaseManagers: Dictionary of database managers for data persistence, keyed by name
    ///   - preferencesManagers: Dictionary of preferences managers for user settings, keyed by name
    ///   - fileManagers: Dictionary of file managers for file operations, keyed by name
    ///   - syncManagers: Dictionary of sync managers for data synchronization, keyed by name
    init(databaseManagers: [String: FuseDatabaseManageable],
         preferencesManagers: [String: FusePreferencesManageable],
         fileManagers: [String: FuseFileManageable],
         syncManagers: [String: FuseSyncManageable]) {
        self.databaseManagers = databaseManagers
        self.preferencesManagers = preferencesManagers
        self.fileManagers = fileManagers
        self.syncManagers = syncManagers
    }

    /// Retrieves or creates a database manager instance based on the provided configuration
    /// 
    /// This method implements a lazy initialization pattern where database managers are cached
    /// by their name to avoid unnecessary recreation. If a manager with the specified name
    /// already exists, it returns the cached instance. Otherwise, it attempts to build a new
    /// manager using the provided builder option.
    /// 
    /// - Parameter query: The database builder option containing configuration and name
    /// - Returns: A database manager instance if successful, nil if creation fails
    public func db(_ query: FuseDatabaseBuilderOption) -> FuseDatabaseManageable? {
        let queryName = query.name
        if let manager = databaseManagers[queryName] {
            return manager
        }
        if let manager: FuseDatabaseManageable = try? query.build() as? FuseDatabaseManageable {
            databaseManagers[queryName] = manager
            return manager
        }
        return nil
    }

    /// Retrieves or creates a preferences manager instance for user settings management
    /// 
    /// This method provides access to preferences managers that handle user settings and
    /// application configurations. It follows the same lazy initialization pattern as other
    /// managers, caching instances by name to ensure efficient resource usage.
    /// 
    /// - Parameter query: The preferences builder option containing configuration and name
    /// - Returns: A preferences manager instance if successful, nil if creation fails
    public func pref(_ query: FusePreferencesBuilderOption) -> FusePreferencesManageable? {
        let queryName = query.name
        if let manager = preferencesManagers[queryName] {
            return manager
        }
        if let manager: FusePreferencesManageable = try? query.build() as? FusePreferencesManageable {
            preferencesManagers[queryName] = manager
            return manager
        }
        return nil
    }
    
    /// Retrieves or creates a file manager instance for file system operations
    /// 
    /// This method provides access to file managers that handle file system operations
    /// such as reading, writing, and managing files and directories. The manager instances
    /// are cached by name to prevent duplicate initialization and ensure consistent
    /// file handling across the application.
    /// 
    /// - Parameter query: The file builder option containing configuration and name
    /// - Returns: A file manager instance if successful, nil if creation fails
    public func file(_ query: FuseFileBuilderOption) -> FuseFileManageable? {
        let queryName = query.name
        if let manager = fileManagers[queryName] {
            return manager
        }
        if let manager: FuseFileManageable = try? query.build() as? FuseFileManageable {
            fileManagers[queryName] = manager
            return manager
        }
        return nil
    }

    /// Retrieves or creates a sync manager instance for data synchronization operations
    /// 
    /// This method provides access to sync managers that handle data synchronization
    /// between local storage and remote services. It manages the coordination of data
    /// consistency across different storage layers and ensures proper conflict resolution
    /// during synchronization processes.
    /// 
    /// - Parameter query: The sync builder option containing configuration and name
    /// - Returns: A sync manager instance if successful, nil if creation fails
    public func sync(_ query: FuseSyncBuilderOption) -> FuseSyncManageable? {
        let queryName = query.name
        if let manager = syncManagers[queryName] {
            return manager
        }
        if let manager: FuseSyncManageable = try? query.build() as? FuseSyncManageable {
            syncManagers[queryName] = manager
            return manager
        }
        return nil
    }
}
