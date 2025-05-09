import Foundation

/// No-operation implementation of FuseSyncManageable that doesn't perform any actual synchronization
public final class NoSyncManager: FuseSyncManageable {
  /// Initialize a new no-operation sync manager
  public init() {}
  
  /// Start synchronization process (no-op implementation)
  public func startSync() {
    // 無操作實現
  }
  
  /// Push local changes to remote (no-op implementation)
  /// - Parameters:
  ///   - items: The records that would be pushed
  ///   - path: The path where records would be pushed
  public func pushLocalChanges<T: FuseDatabaseRecord>(_ items: [T], at path: String) {
    // 無操作實現
  }
  
  /// Observe remote changes (no-op implementation)
  /// - Parameters:
  ///   - path: The path that would be observed
  ///   - handler: Callback that would be invoked on changes
  public func observeRemoteChanges(
    path: String, 
    handler: @escaping (Result<Data, Error>) -> Void
  ) {
    // 無操作實現
  }
} 
