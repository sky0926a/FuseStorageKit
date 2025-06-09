import Foundation

// MARK: - Database Value Protocols
/// A protocol that abstracts database value conversion without depending on specific database implementations
public protocol FuseDatabaseValueConvertible {
    /// Convert this value to a database-compatible representation
    var fuseDatabaseValue: Any { get }
}

// Make standard types conform to our protocol
extension String: FuseDatabaseValueConvertible {
    public var fuseDatabaseValue: Any { return self }
}

extension Int: FuseDatabaseValueConvertible {
    public var fuseDatabaseValue: Any { return self }
}

extension Int64: FuseDatabaseValueConvertible {
    public var fuseDatabaseValue: Any { return self }
}

extension Double: FuseDatabaseValueConvertible {
    public var fuseDatabaseValue: Any { return self }
}

extension Bool: FuseDatabaseValueConvertible {
    public var fuseDatabaseValue: Any { return self }
}

extension Date: FuseDatabaseValueConvertible {
    public var fuseDatabaseValue: Any { return self }
}

extension Data: FuseDatabaseValueConvertible {
    public var fuseDatabaseValue: Any { return self }
}

extension NSNull: FuseDatabaseValueConvertible {
    public var fuseDatabaseValue: Any { return self }
}

extension Optional: FuseDatabaseValueConvertible where Wrapped: FuseDatabaseValueConvertible {
    public var fuseDatabaseValue: Any {
        switch self {
        case .none:
            return NSNull()
        case .some(let wrapped):
            return wrapped.fuseDatabaseValue
        }
    }
}

// MARK: - Database Row Protocol
/// A protocol that abstracts database row access
public protocol FuseDatabaseRow {
    subscript(columnName: String) -> Any? { get }
    
    /// Get all available column names in this row
    var columnNames: [String] { get }
}

// MARK: - Statement Arguments Protocol
/// A protocol that abstracts statement arguments for database queries
public protocol FuseStatementArgumentsProtocol {
    init<S: Sequence>(_ arguments: S) where S.Element == (any FuseDatabaseValueConvertible)?
}

/// A wrapper for statement arguments that can be used across different database implementations
public struct FuseStatementArguments: FuseStatementArgumentsProtocol {
    private let arguments: [(any FuseDatabaseValueConvertible)?]
    
    public init<S: Sequence>(_ arguments: S) where S.Element == (any FuseDatabaseValueConvertible)? {
        self.arguments = Array(arguments)
    }
    
    public func toGRDBArguments() -> Any {
        // Convert our abstract values to concrete database values
        return arguments.map { argument in
            if let arg = argument {
                return arg.fuseDatabaseValue
            } else {
                return NSNull()
            }
        }
    }
}

// MARK: - Database Connection Protocol
/// A protocol that abstracts database connection operations
public protocol FuseDatabaseConnection {
    func execute(sql: String, arguments: FuseStatementArguments) throws
    func tableExists(_ tableName: String) throws -> Bool
    func create(table: String, options: [String], body: (FuseTableBuilder) throws -> Void) throws
    func fetchAll<T: FuseFetchableRecord>(_ type: T.Type, sql: String, arguments: FuseStatementArguments) throws -> [T]
    func fetchRows(sql: String, arguments: FuseStatementArguments) throws -> [FuseDatabaseRow]
}

// MARK: - Table Builder Protocol
/// A protocol that abstracts table building operations
public protocol FuseTableBuilder {
    func column(_ name: String, _ type: String, isPrimaryKey: Bool, isNotNull: Bool, isUnique: Bool, defaultValue: FuseDatabaseValueConvertible?) throws
}

// MARK: - Database Queue Protocol
/// A protocol that abstracts database queue operations
public protocol FuseDatabaseQueueProtocol {
    func read<T>(_ block: @escaping (FuseDatabaseConnection) throws -> T) throws -> T
    func write<T>(_ block: @escaping (FuseDatabaseConnection) throws -> T) throws -> T
}

// MARK: - Record Protocols
/// A protocol that abstracts fetchable record operations
public protocol FuseFetchableRecord {
    /// Creates an instance from a database row using tableDefinition for direct type conversion
    /// This method directly converts database values based on FuseColumnType without JSON encoding/decoding
    /// - Parameter row: Database row containing the record data
    /// - Returns: New instance of the record type with directly converted values
    /// - Throws: DecodingError if direct type conversion fails
    static func fromDatabase(row: FuseDatabaseRow) throws -> Self
    
    /// Fetches all records from the database using a SQL query
    static func fetchAll(_ db: FuseDatabaseConnection, sql: String, arguments: FuseStatementArguments) throws -> [Self]
}

// Provide default implementations for FuseFetchableRecord
public extension FuseFetchableRecord {
    static func fetchAll(_ db: FuseDatabaseConnection, sql: String, arguments: FuseStatementArguments) throws -> [Self] {
        let rows = try db.fetchRows(sql: sql, arguments: arguments)
        return try rows.map { try Self.fromDatabase(row: $0) }
    }
    
    /// Default implementation of fromDatabase using tableDefinition for direct type conversion
    /// 
    /// This method uses tableDefinition to directly cast database values to Swift types:
    /// 1. Gets column definitions from tableDefinition()
    /// 2. Directly casts each database value according to its FuseColumnType
    /// 3. Uses JSON decoding only as final reconstruction step
    /// 4. Provides precise error messages for failed type conversions
    /// 
    /// - Parameter row: Database row containing raw values
    /// - Returns: Properly typed Swift object
    /// - Throws: DecodingError if type conversion fails
    static func fromDatabase(row: FuseDatabaseRow) throws -> Self where Self: Decodable {
        guard let recordType = Self.self as? any (FuseDatabaseRecord.Type) else {
            fatalError("FuseFetchableRecord must be used with FuseDatabaseRecord")
        }
        
        // Step 1: Get table definition for direct type conversion
        let tableDefinition = recordType.tableDefinition()
        let columnsByName = Dictionary(uniqueKeysWithValues: tableDefinition.columns.map { ($0.name, $0) })
        
        // Step 2: Build a dictionary with directly converted values
        var typedValues: [String: Any?] = [:]
        let availableColumnNames = row.columnNames
        
        for columnName in availableColumnNames {
            let rawValue = row[columnName]
            
            if let columnDef = columnsByName[columnName] {
                // Direct type conversion based on FuseColumnType
                let convertedValue = try convertDatabaseValueDirectly(
                    rawValue, 
                    columnType: columnDef.type, 
                    columnName: columnName
                )
                typedValues[columnName] = convertedValue
            } else {
                // Fallback for columns not in tableDefinition
                typedValues[columnName] = rawValue
            }
        }
        
        // Step 3: Use JSON decoding only as final reconstruction step
        return try reconstructFromTypedValues(typedValues)
    }
    
    /// Direct type conversion based on FuseColumnType without JSON encoding/decoding
    /// 
    /// - Parameters:
    ///   - dbValue: Raw value from database row
    ///   - columnType: Expected column type from tableDefinition
    ///   - columnName: Column name for error reporting
    /// - Returns: Directly converted value of correct Swift type
    /// - Throws: DecodingError if conversion fails
    private static func convertDatabaseValueDirectly(_ dbValue: Any?, columnType: FuseColumnType, columnName: String) throws -> Any? {
        // Handle nil/NSNull values
        guard let dbValue = dbValue else { return nil }
        if dbValue is NSNull { return nil }
        
        // Direct type conversion based on FuseColumnType
        switch columnType {
        case .text:
            if let stringValue = dbValue as? String {
                return stringValue
            }
            // Convert other types to string
            return String(describing: dbValue)
            
        case .integer:
            if let int64Value = dbValue as? Int64 {
                return int64Value
            }
            if let intValue = dbValue as? Int {
                return Int64(intValue)
            }
            if let stringValue = dbValue as? String, let int64Value = Int64(stringValue) {
                return int64Value
            }
            throw DecodingError.typeMismatch(Int64.self, 
                DecodingError.Context(codingPath: [], 
                    debugDescription: "Cannot convert value '\(dbValue)' to Int64 for column '\(columnName)'"))
            
        case .real, .double:
            if let doubleValue = dbValue as? Double {
                return doubleValue
            }
            if let floatValue = dbValue as? Float {
                return Double(floatValue)
            }
            if let intValue = dbValue as? Int {
                return Double(intValue)
            }
            if let int64Value = dbValue as? Int64 {
                return Double(int64Value)
            }
            if let stringValue = dbValue as? String, let doubleValue = Double(stringValue) {
                return doubleValue
            }
            throw DecodingError.typeMismatch(Double.self, 
                DecodingError.Context(codingPath: [], 
                    debugDescription: "Cannot convert value '\(dbValue)' to Double for column '\(columnName)'"))
            
        case .numeric:
            // Similar to double but more flexible
            if let doubleValue = dbValue as? Double {
                return doubleValue
            }
            if let intValue = dbValue as? Int {
                return Double(intValue)
            }
            if let int64Value = dbValue as? Int64 {
                return Double(int64Value)
            }
            return Double(0) // Fallback for numeric
            
        case .boolean:
            if let boolValue = dbValue as? Bool {
                return boolValue
            }
            if let intValue = dbValue as? Int {
                return intValue != 0
            }
            if let int64Value = dbValue as? Int64 {
                return int64Value != 0
            }
            if let stringValue = dbValue as? String {
                let lowercased = stringValue.lowercased()
                return lowercased == "true" || lowercased == "1" || lowercased == "yes"
            }
            throw DecodingError.typeMismatch(Bool.self, 
                DecodingError.Context(codingPath: [], 
                    debugDescription: "Cannot convert value '\(dbValue)' to Bool for column '\(columnName)'"))
            
        case .date:
            if let dateValue = dbValue as? Date {
                return dateValue
            }
            if let timestamp = dbValue as? Double {
                return Date(timeIntervalSince1970: timestamp)
            }
            if let timestamp = dbValue as? Int64 {
                return Date(timeIntervalSince1970: Double(timestamp))
            }
            if let stringValue = dbValue as? String {
                // Try multiple date formats
                if let date = parseDate(from: stringValue) {
                    return date
                }
            }
            throw DecodingError.typeMismatch(Date.self, 
                DecodingError.Context(codingPath: [], 
                    debugDescription: "Cannot convert value '\(dbValue)' to Date for column '\(columnName)'"))
            
        case .blob:
            if let dataValue = dbValue as? Data {
                return dataValue
            }
            if let stringValue = dbValue as? String {
                // Try base64 decoding first, then UTF-8
                if let data = Data(base64Encoded: stringValue) {
                    return data
                }
                return stringValue.data(using: .utf8)
            }
            throw DecodingError.typeMismatch(Data.self, 
                DecodingError.Context(codingPath: [], 
                    debugDescription: "Cannot convert value '\(dbValue)' to Data for column '\(columnName)'"))
            
        case .any:
            // For .any type, return the value as-is without conversion
            // This allows maximum flexibility for dynamic content
            return dbValue
        }
    }
    
    /// Helper method to parse date from string
    private static func parseDate(from string: String) -> Date? {
        let formatters = [
            ISO8601DateFormatter(),
        ]
        
        for formatter in formatters {
            if let date = formatter.date(from: string) {
                return date
            }
        }
        
        // Try timestamp parsing
        if let timestamp = Double(string) {
            return Date(timeIntervalSince1970: timestamp)
        }
        
        return nil
    }
    
    /// Reconstruct object from directly typed values using JSON decoding
    /// 
    /// This method receives data that has already been directly typed using FuseColumnType,
    /// so it should be ready for JSON decoding with minimal additional conversion.
    /// 
    /// - Parameter typedValues: Values that have been directly converted using FuseColumnType
    /// - Returns: Fully constructed Swift object
    /// - Throws: DecodingError if final reconstruction fails
    private static func reconstructFromTypedValues(_ typedValues: [String: Any?]) throws -> Self where Self: Decodable {
        // Convert NSNull values to nil for proper JSON serialization
        var cleanedDict: [String: Any] = [:]
        for (key, value) in typedValues {
            if let value = value {
                if value is NSNull {
                    // Skip NSNull values for JSON
                } else {
                    cleanedDict[key] = value
                }
            }
            // Skip nil values
        }
        
        // JSON encode then decode to reconstruct the object
        let jsonData = try JSONSerialization.data(withJSONObject: cleanedDict, options: [])
        let decoder = JSONDecoder()
        
        // Since we've done direct type conversion based on FuseColumnType, 
        // the data should be properly typed and ready for JSON decoding
        return try decoder.decode(Self.self, from: jsonData)
    }
}

/// A protocol that abstracts persistable record operations
public protocol FusePersistableRecord {
    /// Converts the record to a dictionary of database values using tableDefinition
    /// - Returns: A dictionary mapping column names to their corresponding database values
    func toDatabaseValues() -> [String: FuseDatabaseValueConvertible?]
}

// Provide default implementation for FusePersistableRecord that requires tableDefinition
public extension FusePersistableRecord {
    /// Default implementation of toDatabaseValues using tableDefinition for type-safe conversion
    func toDatabaseValues() -> [String: FuseDatabaseValueConvertible?] {
        guard let recordType = Self.self as? any (FuseDatabaseRecord.Type) else {
            fatalError("FusePersistableRecord must be used with FuseDatabaseRecord")
        }
        
        var values: [String: FuseDatabaseValueConvertible?] = [:]
        let mirror = Mirror(reflecting: self)
        let columnsByName = Dictionary(uniqueKeysWithValues: recordType.tableDefinition().columns.map { ($0.name, $0) })
        
        for child in mirror.children {
            guard let label = child.label,
                  let columnDef = columnsByName[label] else { continue }
            
            // Use column definition to handle type conversion properly
            values[label] = convertToFuseDatabaseValue(child.value, columnType: columnDef.type)
        }
        
        return values
    }
    
    /// Helper method to convert Swift values to database values based on column type
    private func convertToFuseDatabaseValue(_ value: Any, columnType: FuseColumnType) -> FuseDatabaseValueConvertible? {
        // Handle nil/NSNull first
        if value is NSNull {
            return NSNull()
        }
        
        // Handle Optional values
        if let optionalMirror = Mirror(reflecting: value).displayStyle, optionalMirror == .optional {
            let mirror = Mirror(reflecting: value)
            if mirror.children.isEmpty {
                // nil value
                return NSNull()
            } else {
                // unwrap and convert
                let unwrappedValue = mirror.children.first!.value
                return convertToFuseDatabaseValue(unwrappedValue, columnType: columnType)
            }
        }
        
        // Convert based on column type - direct conversion based on FuseColumnType
        switch columnType {
        case .text:
            return String(describing: value)
        case .integer:
            if let intValue = value as? Int {
                return Int64(intValue)
            } else if let int64Value = value as? Int64 {
                return int64Value
            } else if let stringValue = value as? String {
                return Int64(stringValue) ?? 0
            }
            return 0
        case .real, .double:
            if let doubleValue = value as? Double {
                return doubleValue
            } else if let floatValue = value as? Float {
                return Double(floatValue)
            } else if let stringValue = value as? String {
                return Double(stringValue) ?? 0.0
            }
            return 0.0
        case .numeric:
            if let doubleValue = value as? Double {
                return doubleValue
            } else if let intValue = value as? Int {
                return Double(intValue)
            }
            return 0.0
        case .boolean:
            if let boolValue = value as? Bool {
                return boolValue
            } else if let stringValue = value as? String {
                return stringValue.lowercased() == "true" || stringValue == "1"
            } else if let intValue = value as? Int {
                return intValue != 0
            }
            return false
        case .date:
            if let dateValue = value as? Date {
                return dateValue
            } else if let stringValue = value as? String {
                // Try to parse as ISO date string
                let formatter = ISO8601DateFormatter()
                return formatter.date(from: stringValue) ?? Date()
            }
            return Date()
        case .blob:
            if let dataValue = value as? Data {
                return dataValue
            } else if let stringValue = value as? String {
                return stringValue.data(using: .utf8) ?? Data()
            }
            return Data()
        case .any:
            // For ANY type, preserve as FuseDatabaseValueConvertible if possible
            if let convertibleValue = value as? FuseDatabaseValueConvertible {
                return convertibleValue
            }
            return String(describing: value)
        }
    }
}

// MARK: - Database Factory
/// A protocol for creating database queues
public protocol FuseDatabaseFactory {
    func createDatabaseQueue(path: String, encryptionOptions: EncryptionOptions?) throws -> FuseDatabaseQueueProtocol
}

// MARK: - Database Factory Registry
/// Registry for managing database factory implementations
public class FuseDatabaseFactoryRegistry {
    public static let shared = FuseDatabaseFactoryRegistry()
    
    private var registeredFactory: FuseDatabaseFactory?
    private let lock = NSLock()
    
    private init() {
//        tryFactoryRegistration()
    }
    
    /// Register a database factory implementation
    /// This is typically called by database implementation modules during their initialization
    public func setMainFactory(_ factory: FuseDatabaseFactory) {
        lock.lock()
        defer { lock.unlock() }
        registeredFactory = factory
    }
    
    /// Get the currently registered factory
    /// Returns nil if no factory has been registered
    func mainFactory() -> FuseDatabaseFactory? {
        lock.lock()
        defer { lock.unlock() }
        return registeredFactory
    }
    
    private func tryFactoryRegistration() {
        #if use_sqlcipher
        let factoryClassName = "FuseStorageSQLCipher.FuseGRDBDatabaseFactory"
        #else
        let factoryClassName = "FuseStorageSQLCipher.FuseGRDBDatabaseFactory"
        #endif
        
        if let factoryClass = NSClassFromString(factoryClassName) as? NSObject.Type {
            // If the class exists, try to create an instance which should trigger registration
            if let factory = factoryClass.init() as? FuseDatabaseFactory {
                setMainFactory(factory)
            }
        }
    }
}
