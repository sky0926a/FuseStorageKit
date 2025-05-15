import Foundation

/// Main facade for the FuseStorageKit providing unified access to storage services
public final class FuseStorageKit {
  public let database: FuseDatabaseManageable
  public let preferences: FusePreferencesManageable
  public let file: FuseFileManageable
  public let sync: FuseSyncManageable
  public let keychain: FuseKeychainManageable

  /// Initialize with all dependencies
  /// - Parameters:
  ///   - databaseManager: The database manager for data persistence
  ///   - preferencesManager: The preferences manager for user settings
  ///   - fileManager: The file manager for file operations
  ///   - syncManager: The sync manager for data synchronization
  ///   - keychainManager: The keychain manager for secure storage
  public init(
    databaseManager: FuseDatabaseManageable,
    preferencesManager: FusePreferencesManageable,
    fileManager: FuseFileManageable,
    syncManager: FuseSyncManageable,
    keychainManager: FuseKeychainManageable
  ) {
    self.database = databaseManager
    self.preferences = preferencesManager
    self.file = fileManager
    self.sync = syncManager
    self.keychain = keychainManager

    syncManager.startSync()
  }
}
