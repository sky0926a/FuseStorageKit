import Foundation

/// A protocol that defines the requirements for database records in FuseStorageKit.
/// This protocol combines Codable for JSON serialization, FuseFetchableRecord for reading from the database,
/// and FusePersistableRecord for writing to the database.
public protocol FuseDatabaseRecord: Codable, Identifiable, FuseFetchableRecord, FusePersistableRecord {
    /// The unique identifier for the record in the database
    var _fuseid: FuseDatabaseValueConvertible { get }
    
    /// The name of the ID field in the database table
    static var _fuseidField: String { get }
    
    /// The name of the database table for this record type
    static var databaseTableName: String { get }
    
    /// The table definition for this record type, defining column types and constraints
    /// This property provides type information for proper encode/decode operations
    var tableDefinition: FuseTableDefinition { get }
    
    /// Converts the record to a dictionary of database values
    /// - Returns: A dictionary mapping column names to their corresponding database values
    func toDatabaseValues() -> [String: FuseDatabaseValueConvertible?]
}

public extension FuseDatabaseRecord {
    /// The unique identifier for the record, automatically retrieved from the specified ID field.
    /// This implementation uses reflection to find the ID field value.
    var _fuseid: FuseDatabaseValueConvertible {
        let mirror = Mirror(reflecting: self)
        guard let value = mirror.children.first(where: { $0.label == Self._fuseidField })?.value as? FuseDatabaseValueConvertible else {
            fatalError("Can not find ID field: \(Self._fuseidField)")
        }
        return value
    }

    /// The name of the database table for this record type.
    /// By default, it uses the lowercase name of the record type.
    static var databaseTableName: String {
        return String(describing: self).lowercased()
    }
    
    /// Default implementation of toDatabaseValues using tableDefinition for type-safe conversion
    func toDatabaseValues() -> [String: FuseDatabaseValueConvertible?] {
        var values: [String: FuseDatabaseValueConvertible?] = [:]
        let mirror = Mirror(reflecting: self)
        let columnsByName = Dictionary(uniqueKeysWithValues: tableDefinition.columns.map { ($0.name, $0) })
        
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
        
        // Convert based on column type
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
    
    /// Helper method to convert database values back to Swift values based on column type
    /// This method is available for GRDB integration layer to use
    func convertFromDatabaseValue(_ dbValue: Any?, columnType: FuseColumnType, targetType: Any.Type) -> Any? {
        // Handle nil values
        guard let dbValue = dbValue else { return nil }
        
        // Handle NSNull
        if dbValue is NSNull {
            return nil
        }
        
        // Convert based on column type and target type
        switch columnType {
        case .text:
            if let stringValue = dbValue as? String {
                return stringValue
            }
            return String(describing: dbValue)
            
        case .integer:
            if let int64Value = dbValue as? Int64 {
                // Convert to appropriate integer type
                if targetType is Int.Type {
                    return Int(int64Value)
                }
                return int64Value
            } else if let intValue = dbValue as? Int {
                if targetType is Int64.Type {
                    return Int64(intValue)
                }
                return intValue
            } else if let stringValue = dbValue as? String {
                let int64Value = Int64(stringValue) ?? 0
                if targetType is Int.Type {
                    return Int(int64Value)
                }
                return int64Value
            }
            return targetType is Int.Type ? 0 : Int64(0)
            
        case .real, .double:
            if let doubleValue = dbValue as? Double {
                return doubleValue
            } else if let floatValue = dbValue as? Float {
                return Double(floatValue)
            } else if let stringValue = dbValue as? String {
                return Double(stringValue) ?? 0.0
            }
            return 0.0
            
        case .numeric:
            if let doubleValue = dbValue as? Double {
                return doubleValue
            } else if let intValue = dbValue as? Int {
                return Double(intValue)
            } else if let int64Value = dbValue as? Int64 {
                return Double(int64Value)
            }
            return 0.0
            
        case .boolean:
            if let boolValue = dbValue as? Bool {
                return boolValue
            } else if let intValue = dbValue as? Int {
                return intValue != 0
            } else if let int64Value = dbValue as? Int64 {
                return int64Value != 0
            } else if let stringValue = dbValue as? String {
                return stringValue.lowercased() == "true" || stringValue == "1"
            }
            return false
            
        case .date:
            if let dateValue = dbValue as? Date {
                return dateValue
            } else if let stringValue = dbValue as? String {
                // Try multiple date formats
                
                // ISO8601 format
                let iso8601Formatter = ISO8601DateFormatter()
                if let date = iso8601Formatter.date(from: stringValue) {
                    return date
                }
                
                // SQLite format with milliseconds
                let sqliteWithMillisFormatter = DateFormatter()
                sqliteWithMillisFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
                sqliteWithMillisFormatter.timeZone = TimeZone(secondsFromGMT: 0)
                if let date = sqliteWithMillisFormatter.date(from: stringValue) {
                    return date
                }
                
                // SQLite format without milliseconds
                let sqliteFormatter = DateFormatter()
                sqliteFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                sqliteFormatter.timeZone = TimeZone(secondsFromGMT: 0)
                if let date = sqliteFormatter.date(from: stringValue) {
                    return date
                }
                
                // Date only format
                let dateOnlyFormatter = DateFormatter()
                dateOnlyFormatter.dateFormat = "yyyy-MM-dd"
                dateOnlyFormatter.timeZone = TimeZone(secondsFromGMT: 0)
                if let date = dateOnlyFormatter.date(from: stringValue) {
                    return date
                }
                
                return Date()
            } else if let timestamp = dbValue as? Double {
                return Date(timeIntervalSince1970: timestamp)
            } else if let timestamp = dbValue as? Int64 {
                return Date(timeIntervalSince1970: Double(timestamp))
            }
            return Date()
            
        case .blob:
            if let dataValue = dbValue as? Data {
                return dataValue
            } else if let stringValue = dbValue as? String {
                // Try base64 decoding first
                if let data = Data(base64Encoded: stringValue) {
                    return data
                }
                // Fallback to UTF-8 encoding
                return stringValue.data(using: .utf8) ?? Data()
            }
            return Data()
            
        case .any:
            return dbValue
        }
    }
    
    /// Default implementation of fromDatabase using tableDefinition for type-safe conversion
    static func fromDatabase(row: FuseDatabaseRow) throws -> Self {
        // Extract all available column data from the row using actual column names
        var jsonDict: [String: Any?] = [:]
        
        // Get all actual column names from the row
        let columnNames = row.columnNames
        print("🔍 [DEBUG] Available column names: \(Array(columnNames))")
        
        for columnName in columnNames {
            let value = row[columnName]
            // Include all values, even nil and NSNull, as they represent database data
            jsonDict[columnName] = value
            print("🔍 [DEBUG] Column '\(columnName)': \(value ?? "nil")")
        }
        
        print("🔍 [DEBUG] JSON dict keys: \(jsonDict.keys.sorted())")
        
        return try reconstructFromRowData(jsonDict)
    }
    
    /// Reconstruct object from row data using JSON decoding with type conversion
    private static func reconstructFromRowData(_ jsonDict: [String: Any?]) throws -> Self {
        // Convert NSNull values to nil for proper JSON serialization
        var cleanedDict: [String: Any] = [:]
        for (key, value) in jsonDict {
            if let value = value {
                if value is NSNull {
                    // Skip NSNull values - JSON serialization will treat missing keys as nil
                    continue
                } else {
                    cleanedDict[key] = value
                }
            }
            // Skip nil values - they will be treated as missing keys in JSON
        }
        
        // Use JSON decoding with enhanced type handling
        let jsonData = try JSONSerialization.data(withJSONObject: cleanedDict)
        let decoder = JSONDecoder()
        
        // Enhanced date decoding strategy
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            
            if let timestamp = try? container.decode(Double.self) {
                return Date(timeIntervalSince1970: timestamp)
            }
            
            if let dateString = try? container.decode(String.self) {
                return parseDate(from: dateString) ?? Date()
            }
            
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode date from value")
        }
        
        // Try decoding with boolean conversion fallback
        return try decodeBooleanCompatible(Self.self, from: jsonData, using: decoder)
    }
    
    /// Parse date string using multiple formats
    private static func parseDate(from dateString: String) -> Date? {
        // ISO8601 format
        let iso8601Formatter = ISO8601DateFormatter()
        if let date = iso8601Formatter.date(from: dateString) {
            return date
        }
        
        // SQLite format with milliseconds
        let sqliteWithMillisFormatter = DateFormatter()
        sqliteWithMillisFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        sqliteWithMillisFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        if let date = sqliteWithMillisFormatter.date(from: dateString) {
            return date
        }
        
        // SQLite format without milliseconds
        let sqliteFormatter = DateFormatter()
        sqliteFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        sqliteFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        if let date = sqliteFormatter.date(from: dateString) {
            return date
        }
        
        // Date only format
        let dateOnlyFormatter = DateFormatter()
        dateOnlyFormatter.dateFormat = "yyyy-MM-dd"
        dateOnlyFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        if let date = dateOnlyFormatter.date(from: dateString) {
            return date
        }
        
        // Try parsing as timestamp
        if let timestamp = Double(dateString) {
            return Date(timeIntervalSince1970: timestamp)
        }
        
        return nil
    }
    
    /// Custom decoding method that handles boolean conversion from integers
    private static func decodeBooleanCompatible<T: Codable>(_ type: T.Type, from data: Data, using decoder: JSONDecoder) throws -> T {
        // First, try normal decoding
        do {
            return try decoder.decode(type, from: data)
        } catch let error as DecodingError {
            // If we get a type mismatch error involving Bool, try to fix it
            if case .typeMismatch(let expectedType, _) = error,
               expectedType is Bool.Type {
                
                // Convert the JSON data to fix boolean issues
                if let jsonObject = try? JSONSerialization.jsonObject(with: data),
                   var jsonDict = jsonObject as? [String: Any] {
                    
                    // Convert integer 0/1 values to boolean for known boolean fields
                    for (key, value) in jsonDict {
                        if let intValue = value as? Int64 {
                            // Convert 0/1 to boolean for common boolean field names
                            if key.contains("attachment") || key.contains("active") || key.contains("enabled") || 
                               key.contains("visible") || key.contains("selected") || key.hasPrefix("is") || 
                               key.hasPrefix("has") || key.hasPrefix("can") || key.hasPrefix("should") {
                                jsonDict[key] = (intValue != 0)
                            }
                        }
                        if let intValue = value as? Int {
                            // Handle regular Int as well
                            if key.contains("attachment") || key.contains("active") || key.contains("enabled") || 
                               key.contains("visible") || key.contains("selected") || key.hasPrefix("is") || 
                               key.hasPrefix("has") || key.hasPrefix("can") || key.hasPrefix("should") {
                                jsonDict[key] = (intValue != 0)
                            }
                        }
                    }
                    
                    // Try decoding again with the fixed data
                    let fixedData = try JSONSerialization.data(withJSONObject: jsonDict)
                    return try decoder.decode(type, from: fixedData)
                }
            }
            
            // If we can't fix it, re-throw the original error
            throw error
        }
    }
}
