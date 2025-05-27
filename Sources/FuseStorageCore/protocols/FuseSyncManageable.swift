import Foundation

/// Protocol defining synchronization operations for FuseStorageKit
/// 
/// This protocol provides an interface for data synchronization between local
/// storage and remote services. Implementations can range from no-operation
/// for offline-only apps to full cloud-based synchronization with services
/// like Firebase or custom backend solutions.
public protocol FuseSyncManageable: FuseManageable {
  /// Start the synchronization process
  /// 
  /// Initializes the synchronization system, setting up any necessary
  /// listeners or background processes for data synchronization.
  func startSync()
  
  /// Push changes from local database to remote storage
  /// 
  /// Uploads local database records to the remote storage system,
  /// enabling data sharing across devices and platforms.
  /// 
  /// - Parameters:
  ///   - items: The database records to push to remote storage
  ///   - path: The remote path where the records will be stored
  func pushLocalChanges<T: FuseDatabaseRecord>(
    _ items: [T], at path: String
  )
  
  /// Observe changes from remote storage
  /// 
  /// Sets up monitoring for changes in remote storage, invoking the
  /// provided handler when data is updated from other sources.
  /// 
  /// - Parameters:
  ///   - path: The remote path to observe for changes
  ///   - handler: Callback that will be invoked when remote data changes
  func observeRemoteChanges(
    path: String,
    handler: @escaping (Result<Data, Error>) -> Void
  )
} 
