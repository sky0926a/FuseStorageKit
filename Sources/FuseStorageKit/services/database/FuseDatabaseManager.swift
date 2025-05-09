import Foundation
import GRDB

/// Implementation of FuseDatabaseManageable using GRDB
public final class FuseDatabaseManager: FuseDatabaseManageable {
  private let dbQueue: DatabaseQueue
  
  /// Initialize a new database service with the specified database path
  /// - Parameter path: The file path for the SQLite database, relative to Documents directory
  /// - Throws: Database errors during initialization
  public init(path: String = "fuse.sqlite") throws {
    // 取得 Documents 目錄
    let documentsDirectory = FileManager.default.documentsDirectory()
    let fullPath = documentsDirectory.appendingPathComponent(path)
    
    // 確保中間資料夾都已建立
    try FileManager.default.createDirectoriesIfNeeded(for: fullPath)
    
    // 建立資料庫連線
    dbQueue = try DatabaseQueue(path: fullPath.path)
  }
  
  /// Insert a record into the database
  /// - Parameter item: The record to be inserted
  /// - Throws: Database errors during insertion
  public func insert<T: FuseDatabaseRecord>(_ item: T) throws {
    _ = try dbQueue.write { db in
      try item.save(db)
    }
  }
  
  /// Fetch all records of a specific type from the database
  /// - Parameter type: The type of records to fetch
  /// - Returns: An array of fetched records
  /// - Throws: Database errors during fetching
  public func fetch<T: FuseDatabaseRecord>(_ type: T.Type) throws -> [T] {
    try dbQueue.read { db in
      try type.fetchAll(db)
    }
  }
  
  /// Delete a record from the database
  /// - Parameter item: The record to be deleted
  /// - Throws: Database errors during deletion
  public func delete<T: FuseDatabaseRecord>(_ item: T) throws {
    _ = try dbQueue.write { db in
      try item.delete(db)
    }
  }
  
  /// Execute a read operation on the database
  /// - Parameter operation: The closure that performs database operations
  /// - Returns: The result of the operation
  /// - Throws: Database errors during operation
  public func read<T>(_ operation: @escaping (Database) throws -> T) throws -> T {
    try dbQueue.read(operation)
  }
  
  /// Execute a write operation on the database
  /// - Parameter operation: The closure that performs database operations
  /// - Returns: The result of the operation
  /// - Throws: Database errors during operation
  public func write<T>(_ operation: @escaping (Database) throws -> T) throws -> T {
    try dbQueue.write(operation)
  }
  
  /// Check if a table exists in the database
  /// - Parameter tableName: The name of the table to check
  /// - Returns: A boolean indicating whether the table exists
  /// - Throws: Database errors during the check
  public func tableExists(_ tableName: String) throws -> Bool {
    try dbQueue.read { db in
      try db.tableExists(tableName)
    }
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
    primaryKey: String?
  ) throws {
    try dbQueue.write { db in
      try db.create(table: tableName) { t in
        // 添加所有列定義
        for (columnName, columnType) in columnDefinitions {
          // 如果是主鍵列，添加主鍵約束
          if let pk = primaryKey, columnName == pk {
            // 將字串類型轉換為 Database.ColumnType
            let dbColumnType = convertToDBColumnType(columnType)
            t.column(columnName, dbColumnType).primaryKey()
          } else {
            let dbColumnType = convertToDBColumnType(columnType)
            t.column(columnName, dbColumnType)
          }
        }
      }
    }
  }
  
  /// 使用更抽象的表格定義創建表格
  /// - Parameter tableDefinition: 表格的定義
  /// - Throws: 資料庫操作錯誤
  public func createTable(_ tableDefinition: TableDefinition) throws {
    try dbQueue.write { db in
      // 將我們的 TableOptions 轉換為 GRDB 的選項
      var grdbOptions: GRDB.TableOptions = []
      
      if tableDefinition.options.contains(.withoutRowID) {
        grdbOptions.insert(.withoutRowID)
      }
      
      if tableDefinition.options.contains(.ifNotExists) {
        grdbOptions.insert(.ifNotExists)
      }
      
      if tableDefinition.options.contains(.temporary) {
        grdbOptions.insert(.temporary)
      }
      
      // 對於 strict 選項，需要檢查版本可用性
      if #available(iOS 15.4, macOS 12.4, tvOS 15.4, watchOS 8.5, *) {
        if tableDefinition.options.contains(.strict) {
          grdbOptions.insert(.strict)
        }
      }
      
      try db.create(table: tableDefinition.name, options: grdbOptions) { t in
        // 添加所有列
        for column in tableDefinition.columns {
          let dbColumnType = mapToDBColumnType(column.type)
          var columnBuilder = t.column(column.name, dbColumnType)
          
          if column.isPrimaryKey {
            columnBuilder = columnBuilder.primaryKey()
          }
          
          if column.isNotNull {
            columnBuilder = columnBuilder.notNull()
          }
          
          if column.isUnique {
            columnBuilder = columnBuilder.unique()
          }
          
          if let defaultValue = column.defaultValue {
            columnBuilder = columnBuilder.defaults(to: defaultValue)
          }
        }
      }
    }
  }
  
  // MARK: - Private Helper Methods
  
  /// 將字串 SQL 類型轉換為 Database.ColumnType
  private func convertToDBColumnType(_ sqlType: String) -> Database.ColumnType? {
    let upperType = sqlType.uppercased()
    
    if upperType.contains("TEXT") {
      return .text
    } else if upperType.contains("INTEGER") {
      return .integer
    } else if upperType.contains("REAL") {
      return .real
    } else if upperType.contains("BOOLEAN") {
      return .boolean
    } else if upperType.contains("DATETIME") || upperType.contains("DATE") {
      return .datetime
    } else if upperType.contains("BLOB") {
      return .blob
    } else {
      // 預設使用 TEXT 類型
      return .text
    }
  }
  
  /// 將我們的抽象列類型映射到 GRDB 的 Database.ColumnType
  private func mapToDBColumnType(_ columnType: ColumnType) -> Database.ColumnType? {
    switch columnType {
    case .text:
      return .text
    case .integer:
      return .integer
    case .real:
      return .real
    case .boolean:
      return .boolean
    case .date:
      return .datetime
    case .blob:
      return .blob
    case .custom(let customType):
      // 對於自定義類型，嘗試解析它
      return convertToDBColumnType(customType)
    }
  }
}

/// Database-related error types
public enum DatabaseError: Error {
  /// Record type is not suitable for database operations
  case invalidRecordType
} 