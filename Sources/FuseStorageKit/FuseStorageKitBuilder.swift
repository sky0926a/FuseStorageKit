import Foundation
import GRDB

/// Builder class for creating and configuring FuseStorageKit instances
public class FuseStorageKitBuilder {
  private var databaseManager: FuseDatabaseManageable?
  private var preferencesManager: FusePreferencesManageable?
  private var fileManager: FuseFileManageable?
  private var syncManager: FuseSyncManageable = NoSyncManager()

  /// Initialize a new builder with default configurations
  public init() {}

  /// Configure the database manager
  /// - Parameter databaseManager: The database manager implementation to use
  /// - Returns: Self for method chaining
  public func with(databaseManager: FuseDatabaseManageable) -> Self { 
    self.databaseManager = databaseManager
    return self 
  }
  
  /// Configure the preferences manager
  /// - Parameter preferencesManager: The preferences manager implementation to use
  /// - Returns: Self for method chaining
  public func with(preferencesManager: FusePreferencesManageable) -> Self { 
    self.preferencesManager = preferencesManager
    return self
  }
  
  /// Configure the file manager
  /// - Parameter fileManager: The file manager implementation to use
  /// - Returns: Self for method chaining
  public func with(fileManager: FuseFileManageable) -> Self { 
    self.fileManager = fileManager
    return self 
  }
  
  /// Configure the synchronization manager
  /// - Parameter syncManager: The sync manager implementation to use
  /// - Returns: Self for method chaining
  public func with(syncManager: FuseSyncManageable) -> Self {
    self.syncManager = syncManager
    return self 
  }

  /// Build a FuseStorageKit instance with the configured components
  /// - Returns: A fully configured FuseStorageKit instance
  /// - Throws: Errors during component initialization
  public func build() throws -> FuseStorageKit {
    let db   = try databaseManager ?? FuseDatabaseManager()
    let pref = preferencesManager ?? FusePreferencesManager()
    let file = fileManager ?? FuseFileManager()
    let sync = syncManager
    
    return FuseStorageKit(
      databaseManager: db,
      preferencesManager: pref,
      fileManager: file,
      syncManager: sync
    )
  }
} 
