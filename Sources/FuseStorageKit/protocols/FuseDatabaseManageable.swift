import Foundation
import GRDB

/// Custom protocol that encapsulates GRDB dependencies
public protocol FuseDatabaseRecord: Codable, FetchableRecord, PersistableRecord {}

/// 定義表格列的類型
public enum ColumnType {
  case text
  case integer
  case real
  case boolean
  case date
  case blob
  
  /// 自定義類型與特定修飾符
  case custom(String)
  
  /// 轉換為 SQL 類型字符串
  var sqlType: String {
    switch self {
    case .text: return "TEXT"
    case .integer: return "INTEGER"
    case .real: return "REAL"
    case .boolean: return "BOOLEAN"
    case .date: return "DATETIME"
    case .blob: return "BLOB"
    case .custom(let type): return type
    }
  }
}

/// 定義表格列配置
public struct ColumnDefinition {
  public let name: String
  public let type: ColumnType
  public let isPrimaryKey: Bool
  public let isNotNull: Bool
  public let isUnique: Bool
  public let defaultValue: String?
  
  public init(
    name: String,
    type: ColumnType,
    isPrimaryKey: Bool = false,
    isNotNull: Bool = false,
    isUnique: Bool = false,
    defaultValue: String? = nil
  ) {
    self.name = name
    self.type = type
    self.isPrimaryKey = isPrimaryKey
    self.isNotNull = isNotNull
    self.isUnique = isUnique
    self.defaultValue = defaultValue
  }
  
  /// 轉換為 SQL 定義字符串
  var sqlDefinition: String {
    var definition = "\(name) \(type.sqlType)"
    
    if isPrimaryKey {
      definition += " PRIMARY KEY"
    }
    
    if isNotNull {
      definition += " NOT NULL"
    }
    
    if isUnique {
      definition += " UNIQUE"
    }
    
    if let value = defaultValue {
      definition += " DEFAULT \(value)"
    }
    
    return definition
  }
}

/// Options for table creation
public struct TableOptions: OptionSet, Sendable {
  public let rawValue: Int
  
  public init(rawValue: Int) { self.rawValue = rawValue }
  
  /// Only creates the table if it does not already exist.
  public static let ifNotExists = TableOptions(rawValue: 1 << 0)
  
  /// Creates a temporary table.
  public static let temporary = TableOptions(rawValue: 1 << 1)
  
  /// Creates a `WITHOUT ROWID` table.
  public static let withoutRowID = TableOptions(rawValue: 1 << 2)
  
  /// Creates a STRICT table (SQLite 3.37+, iOS 15.4+).
  @available(iOS 15.4, macOS 12.4, tvOS 15.4, watchOS 8.5, *)
  public static let strict = TableOptions(rawValue: 1 << 3)
}

/// 表格創建配置
public struct TableDefinition {
  public let name: String
  public let columns: [ColumnDefinition]
  public let options: TableOptions
  
  public init(
    name: String,
    columns: [ColumnDefinition],
    options: TableOptions = .ifNotExists
  ) {
    self.name = name
    self.columns = columns
    self.options = options
  }
}

/// Protocol defining database operations
public protocol FuseDatabaseManageable {
  /// Insert a record into the database
  /// - Parameter item: The record to be inserted
  /// - Throws: Database errors during insertion
  func insert<T: FuseDatabaseRecord>(_ item: T) throws
  
  /// Fetch all records of a specific type from the database
  /// - Parameter type: The type of records to fetch
  /// - Returns: An array of fetched records
  /// - Throws: Database errors during fetching
  func fetch<T: FuseDatabaseRecord>(_ type: T.Type) throws -> [T]
  
  /// Delete a record from the database
  /// - Parameter item: The record to be deleted
  /// - Throws: Database errors during deletion
  func delete<T: FuseDatabaseRecord>(_ item: T) throws
  
  /// Execute a read operation on the database
  /// - Parameter operation: The closure that performs database operations
  /// - Returns: The result of the operation
  /// - Throws: Database errors during operation
  func read<T>(_ operation: @escaping (Database) throws -> T) throws -> T
  
  /// Execute a write operation on the database
  /// - Parameter operation: The closure that performs database operations
  /// - Returns: The result of the operation
  /// - Throws: Database errors during operation
  func write<T>(_ operation: @escaping (Database) throws -> T) throws -> T
  
  /// Check if a table exists in the database
  /// - Parameter tableName: The name of the table to check
  /// - Returns: A boolean indicating whether the table exists
  /// - Throws: Database errors during the check
  func tableExists(_ tableName: String) throws -> Bool
  
  /// Create a table in the database using column definitions dictionary
  /// - Parameters:
  ///   - tableName: The name of the table to create
  ///   - columnDefinitions: A dictionary mapping column names to their SQL type definitions
  ///   - primaryKey: The name of the primary key column, if any
  /// - Throws: Database errors during table creation
  func createTable(
    _ tableName: String,
    columnDefinitions: [String: String],
    primaryKey: String?
  ) throws
  
  /// 使用更抽象的表格定義創建表格
  /// - Parameter tableDefinition: 表格的定義
  /// - Throws: 資料庫操作錯誤
  func createTable(_ tableDefinition: TableDefinition) throws
} 