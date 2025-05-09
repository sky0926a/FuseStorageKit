import Foundation
import GRDB

/// Builder class for creating and configuring FuseStorageKit instances
public class FuseStorageKitBuilder {
  private var database: FuseDatabaseManageable?
  private var preferences: FusePreferencesManageable?
  private var file: FuseFileManageable?
  private var sync: FuseSyncManageable = NoSyncManager()

  /// Initialize a new builder with default configurations
  public init() {}

  /// Configure the database manager
  /// - Parameter databaseManager: The database manager implementation to use
  /// - Returns: Self for method chaining
  public func with(database: FuseDatabaseManageable) -> Self {
    self.database = database
    return self
  }
  
  /// Configure the preferences manager
  /// - Parameter preferencesManager: The preferences manager implementation to use
  /// - Returns: Self for method chaining
  public func with(preferences: FusePreferencesManageable) -> Self {
    self.preferences = preferences
    return self
  }
  
  /// Configure the file manager
  /// - Parameter fileManager: The file manager implementation to use
  /// - Returns: Self for method chaining
  public func with(file: FuseFileManageable) -> Self {
    self.file = file
    return self
  }
  
  /// Configure the synchronization manager
  /// - Parameter syncManager: The sync manager implementation to use
  /// - Returns: Self for method chaining
  public func with(sync: FuseSyncManageable) -> Self {
    self.sync = sync
    return self 
  }

  /// Build a FuseStorageKit instance with the configured components
  /// - Returns: A fully configured FuseStorageKit instance
  /// - Throws: Errors during component initialization
  public func build() throws -> FuseStorageKit {
    let db   = try database ?? FuseDatabaseManager()
    let pref = preferences ?? FusePreferencesManager()
    let file = file ?? FuseFileManager()
    let sync = sync
    
    return FuseStorageKit(
      databaseManager: db,
      preferencesManager: pref,
      fileManager: file,
      syncManager: sync
    )
  }
} 
