import Foundation

/// No-operation implementation of FuseSyncManageable that doesn't perform any actual synchronization
/// 
/// This class provides a null object pattern implementation for synchronization,
/// suitable for offline-only applications or when synchronization is handled
/// externally. All sync operations are no-ops that complete successfully without
/// performing any actual data transfer.
public final class NoSyncManager: FuseSyncManageable {
  /// Initialize a new no-operation sync manager
  /// 
  /// Creates a sync manager that performs no actual synchronization operations,
  /// useful for testing or offline-only application configurations.
  public init() {}
  
  /// Start synchronization process (no-op implementation)
  /// 
  /// This method performs no operation and returns immediately, suitable
  /// for applications that don't require any synchronization setup.
  public func startSync() {
    // No operation implementation
  }
  
  /// Push local changes to remote (no-op implementation)
  /// 
  /// This method accepts the parameters but performs no actual data transfer,
  /// allowing the application to function normally without remote synchronization.
  /// 
  /// - Parameters:
  ///   - items: The records that would be pushed (ignored)
  ///   - path: The path where records would be pushed (ignored)
  public func pushLocalChanges<T: FuseDatabaseRecord>(_ items: [T], at path: String) {
    // No operation implementation
  }
  
  /// Observe remote changes (no-op implementation)
  /// 
  /// This method accepts the parameters but never invokes the handler,
  /// effectively disabling remote change observation for offline-only operation.
  /// 
  /// - Parameters:
  ///   - path: The path that would be observed (ignored)
  ///   - handler: Callback that would be invoked on changes (never called)
  public func observeRemoteChanges(
    path: String, 
    handler: @escaping (Result<Data, Error>) -> Void
  ) {
    // No operation implementation
  }
} 
