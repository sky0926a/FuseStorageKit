import Foundation
import FirebaseStorage

#if canImport(FirebaseStorage)
/// Implementation of FuseSyncManageable that uses Firebase Storage for remote synchronization
public final class FirebaseSyncManager: FuseSyncManageable {
  private let storage = Storage.storage()
  
  /// Initialize a new Firebase sync manager
  public init() {}
  
  /// Start synchronization process (optional: can be used for global listeners)
  public func startSync() {
    // 可選：全局監聽
  }
  
  /// Push local database records to Firebase Storage
  /// - Parameters:
  ///   - items: The records to push to Firebase Storage
  ///   - path: The Firebase Storage path where the records will be stored
  public func pushLocalChanges<T: FuseDatabaseRecord>(_ items: [T], at path: String) {
    items.forEach { item in
      if let data = try? JSONEncoder().encode(item) {
        let ref = storage.reference(withPath: "\(path)/\(UUID().uuidString).json")
        _ = ref.putData(data, metadata: nil)
      }
    }
  }
  
  /// Observe changes from Firebase Storage at the specified path
  /// - Parameters:
  ///   - path: The Firebase Storage path to observe
  ///   - handler: Callback that will be invoked when data changes
  public func observeRemoteChanges(
    path: String,
    handler: @escaping (Result<Data, Error>) -> Void
  ) {
    let ref = storage.reference(withPath: path)
    ref.getData(maxSize: 10*1024*1024) { data, err in
      if let e = err { handler(.failure(e)) }
      else if let d = data { handler(.success(d)) }
    }
  }
}
#endif 
