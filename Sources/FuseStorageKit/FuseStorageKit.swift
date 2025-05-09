import Foundation
import GRDB

/// Main facade for the FuseStorageKit providing unified access to storage services
public final class FuseStorageKit {
  public let databaseManager: FuseDatabaseManageable
  public let preferencesManager: FusePreferencesManageable
  public let fileManager: FuseFileManageable
  public let syncManager: FuseSyncManageable

  /// Initialize with all dependencies
  /// - Parameters:
  ///   - databaseManager: The database manager for data persistence
  ///   - preferencesManager: The preferences manager for user settings
  ///   - fileManager: The file manager for file operations
  ///   - syncManager: The sync manager for data synchronization
  public init(
    databaseManager: FuseDatabaseManageable,
    preferencesManager: FusePreferencesManageable,
    fileManager: FuseFileManageable,
    syncManager: FuseSyncManageable
  ) {
    self.databaseManager = databaseManager
    self.preferencesManager = preferencesManager
    self.fileManager = fileManager
    self.syncManager = syncManager

    syncManager.startSync()
  }

  // —— Database API Methods ——
  
  /// Add a record to the database with optional associated files and synchronization
  /// - Parameters:
  ///   - record: The database record to add
  ///   - image: Optional image to save with the record
  ///   - imagePath: Path where the image should be saved, required if image is provided
  ///   - data: Optional binary data to save with the record
  ///   - dataPath: Path where the data should be saved, required if data is provided
  ///   - remoteSyncPath: Optional path for remote synchronization
  /// - Throws: Errors from database insertion or file operations
  public func addRecord<T: FuseDatabaseRecord>(
    _ record: T,
    image: FuseImage? = nil,
    imagePath: String? = nil,
    data: Data? = nil,
    dataPath: String? = nil,
    remoteSyncPath: String? = nil
  ) throws {
    try databaseManager.insert(record)
    
    if let img = image, let path = imagePath {
      _ = try fileManager.save(image: img, relativePath: path)
    }
    
    if let d = data, let path = dataPath {
      _ = try fileManager.save(data: d, relativePath: path)
    }
    
    if let syncPath = remoteSyncPath {
      syncManager.pushLocalChanges([record], at: syncPath)
    }
  }

  /// Fetch all records of a specific type from the database
  /// - Parameter type: The type of records to fetch
  /// - Returns: An array of fetched records
  /// - Throws: Database errors during fetching
  public func fetchAll<T: FuseDatabaseRecord>(
    of type: T.Type
  ) throws -> [T] {
    try databaseManager.fetch(type)
  }

  /// Delete a record from the database with optional file deletion
  /// - Parameters:
  ///   - record: The record to delete
  ///   - filePath: Optional path of associated file to delete
  ///   - remoteSyncPath: Optional path for remote synchronization (not implemented in base class)
  /// - Throws: Errors from database or file operations
  public func deleteRecord<T: FuseDatabaseRecord>(
    _ record: T,
    filePath: String? = nil,
    remoteSyncPath: String? = nil
  ) throws {
    try databaseManager.delete(record)
    if let fp = filePath { try? fileManager.delete(relativePath: fp) }
    // 遠端刪除可按需擴展
  }
  
  // —— Preferences API Methods ——
  
  /// Store a Codable value in user preferences
  /// - Parameters:
  ///   - value: The value to store
  ///   - key: The key to associate with the value
  public func setPreference<Value: Codable>(_ value: Value, forKey key: String) {
    preferencesManager.set(value, forKey: key)
  }
  
  /// Retrieve a Codable value from user preferences
  /// - Parameter key: The key associated with the value
  /// - Returns: The value if found and successfully decoded, or nil otherwise
  public func getPreference<Value: Codable>(forKey key: String) -> Value? {
    preferencesManager.get(forKey: key)
  }
  
  // —— File Management API Methods ——
  
  /// Save an image to the file system
  /// - Parameters:
  ///   - image: The image to save
  ///   - relativePath: Path where the image should be saved
  /// - Returns: The URL where the image was saved
  /// - Throws: Errors during file operations
  public func saveImage(_ image: FuseImage, relativePath: String) throws -> URL {
    try fileManager.save(image: image, relativePath: relativePath)
  }
  
  /// Save binary data to the file system
  /// - Parameters:
  ///   - data: The data to save
  ///   - relativePath: Path where the data should be saved
  /// - Returns: The URL where the data was saved
  /// - Throws: Errors during file operations
  public func saveData(_ data: Data, relativePath: String) throws -> URL {
    try fileManager.save(data: data, relativePath: relativePath)
  }
  
  /// Get the absolute URL for a relative path
  /// - Parameter relativePath: The relative path
  /// - Returns: The absolute URL for the path
  public func getFileURL(for relativePath: String) -> URL {
    fileManager.url(for: relativePath)
  }
  
  /// Delete a file at the specified path
  /// - Parameter relativePath: The path of the file to delete
  /// - Throws: Errors during file deletion
  public func deleteFile(at relativePath: String) throws {
    try fileManager.delete(relativePath: relativePath)
  }
  
  // —— Synchronization API Methods ——
  
  /// Synchronize data records to remote storage
  /// - Parameters:
  ///   - items: The records to synchronize
  ///   - path: The remote path where records should be stored
  public func syncData<T: FuseDatabaseRecord>(
    _ items: [T], 
    at path: String
  ) {
    syncManager.pushLocalChanges(items, at: path)
  }
  
  /// Observe changes from remote storage at the specified path
  /// - Parameters:
  ///   - path: The remote path to observe
  ///   - handler: Callback that will be invoked when remote data changes
  public func observeRemoteData(
    at path: String,
    handler: @escaping (Result<Data, Error>) -> Void
  ) {
    syncManager.observeRemoteChanges(path: path, handler: handler)
  }
  
  // —— Database Schema API Methods ——
  
  /// Check if a table exists in the database
  /// - Parameter tableName: The name of the table to check
  /// - Returns: A boolean indicating whether the table exists
  /// - Throws: Database errors during the check
  public func tableExists(_ tableName: String) throws -> Bool {
    try databaseManager.tableExists(tableName)
  }
  
  /// Create a table in the database
  /// - Parameters:
  ///   - tableName: The name of the table to create
  ///   - columnDefinitions: A dictionary mapping column names to their SQL type definitions
  ///   - primaryKey: The name of the primary key column, if any
  /// - Throws: Database errors during table creation
  public func createTable(
    _ tableName: String,
    columnDefinitions: [String: String],
    primaryKey: String? = nil
  ) throws {
    try databaseManager.createTable(tableName, columnDefinitions: columnDefinitions, primaryKey: primaryKey)
  }
  
  /// 使用更抽象的表格定義創建表格
  /// - Parameter tableDefinition: 表格的定義
  /// - Throws: 資料庫操作錯誤
  public func createTable(_ tableDefinition: TableDefinition) throws {
    try databaseManager.createTable(tableDefinition)
  }
} 
