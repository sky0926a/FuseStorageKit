import Foundation

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
         return try rows.map {
             do {
                 return try Self.fromDatabase(row: $0)
             } catch {
                 throw error
             }
           
         }
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
        guard let recordType = Self.self as? any (FuseDatabaseBaseRecord.Type) else {
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
    
    private static func convertDatabaseValueDirectly(_ dbValue: Any?, columnType: FuseColumnType, columnName: String) throws -> Any? {
        // Handle nil/NSNull values
        guard let dbValue = dbValue else { return nil }
        if dbValue is NSNull { return nil }
        let v = dbValue
        // Direct type conversion based on FuseColumnType
        switch columnType {
        case .text:
            guard let s = v as? String else {
                throw DecodingError.typeMismatch(String.self, .init(codingPath: [], debugDescription: "\(columnName) expected TEXT"))
            }
            return s
        case .integer:
            if let i64 = v as? Int64 { return i64 }
            if let i = v as? Int { return Int64(i) }
            if let d = v as? Double { return Int64(d) }
            if let s = v as? String, let i64 = Int64(s) { return i64 }
            throw DecodingError.typeMismatch(Int64.self, .init(codingPath: [], debugDescription: "\(columnName) expected INTEGER"))
        case .real, .double:
            if let d = v as? Double { return d }
            if let f = v as? Float { return Double(f) }
            if let i = v as? Int { return Double(i) }
            if let i64 = v as? Int64 { return Double(i64) }
            if let s = v as? String, let d = Double(s) { return d }
            throw DecodingError.typeMismatch(Double.self, .init(codingPath: [], debugDescription: "\(columnName) expected REAL"))
        case .numeric:
            if let d = v as? Double { return d }
            if let i = v as? Int { return Double(i) }
            if let i64 = v as? Int64 { return Double(i64) }
            if let s = v as? String, let d = Double(s) { return d }
            throw DecodingError.typeMismatch(Double.self, .init(codingPath: [], debugDescription: "\(columnName) expected NUMERIC"))
        case .boolean:
            if let b = v as? Bool { return b }
            if let i = v as? Int { return i != 0 }
            if let i64 = v as? Int64 { return i64 != 0 }
            if let s = v as? String {
                let l = s.trimmingCharacters(in: .whitespaces).lowercased()
                if ["true","1","yes"].contains(l) { return true }
                if ["false","0","no"].contains(l) { return false }
            }
            throw DecodingError.typeMismatch(Bool.self, .init(codingPath: [], debugDescription: "\(columnName) expected BOOLEAN"))
        case .date:
            // Store Date as ISO8601 string
            if let ts = v as? TimeInterval { return Date(timeIntervalSince1970: ts) }
            if let i = v as? Int { return Date(timeIntervalSince1970: TimeInterval(i)) }
            if let s = v as? String, let d = FuseConstants.getDataFormatter().date(from: s) {
                return d
            }
            return nil
        case .blob:
            if let data = v as? Data { return data }
            if let s = v as? String, let data = Data(base64Encoded: s) { return data }
            if let s = v as? String, let data = s.data(using: .utf8) { return data }
            throw DecodingError.typeMismatch(Data.self, .init(codingPath: [], debugDescription: "\(columnName) expected BLOB"))
        case .any:
            return v
        }
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
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: cleanedDict, options: [])
            let decoder = JSONDecoder()
            return try decoder.decode(Self.self, from: jsonData)
        } catch {
            throw error
        }
        // JSON encode then decode to reconstruct the object
        
        
        // Since we've done direct type conversion based on FuseColumnType, 
        // the data should be properly typed and ready for JSON decoding
        
    }
}
