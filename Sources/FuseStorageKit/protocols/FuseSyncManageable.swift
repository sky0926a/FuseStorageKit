import Foundation

/// Protocol defining synchronization operations (local ⇄ remote, can be No-Op or cloud-based)
public protocol FuseSyncManageable {
  /// Start the synchronization process
  func startSync()
  
  /// Push changes from local database to remote storage
  /// - Parameters:
  ///   - items: The database records to push to remote storage
  ///   - path: The remote path where the records will be stored
  func pushLocalChanges<T: FuseDatabaseRecord>(
    _ items: [T], at path: String
  )
  
  /// Observe changes from remote storage
  /// - Parameters:
  ///   - path: The remote path to observe for changes
  ///   - handler: Callback that will be invoked when remote data changes
  func observeRemoteChanges(
    path: String,
    handler: @escaping (Result<Data, Error>) -> Void
  )
} 
