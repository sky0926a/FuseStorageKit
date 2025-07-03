import Foundation

/// Helper struct for type-erased encoding of Codable objects
private struct AnyEncodable: Encodable {
    private let encodable: Encodable
    
    init(_ encodable: Encodable) {
        self.encodable = encodable
    }
    
    func encode(to encoder: Encoder) throws {
        try encodable.encode(to: encoder)
    }
}

/// Unified type converter that handles all Swift ↔ Database conversions
/// This eliminates duplicate mapping and conversion logic throughout the codebase
public class FuseTypeConverter {
    
    // MARK: - Type Inference
    
    /// Infer FuseColumnType from Swift value with unified logic
    /// 
    /// - Parameter value: Swift value to examine
    /// - Returns: Tuple of (column type, is optional)
    public static func inferColumnType(from value: Any) -> (FuseColumnType, Bool) {
        let mirror = Mirror(reflecting: value)
        
        // Check if it's an optional type
        if mirror.displayStyle == .optional {
            if let unwrapped = mirror.children.first?.value {
                let (columnType, _) = inferColumnType(from: unwrapped)
                return (columnType, true)
            } else {
                return (.text, true) // nil optional defaults to TEXT
            }
        }
        
        // 🎯 Unified type mapping - single source of truth
        switch value {
        case is String: return (.text, false)
        case is Int: return (.integer, false)
        case is Int64: return (.integer, false)
        case is Double: return (.double, false)
        case is Float: return (.real, false)
        case is Bool: return (.boolean, false)
        case is Date: return (.date, false)
        case is Data: return (.blob, false)
        case is Array<Any>: return (.text, false) // Arrays stored as JSON text
        case is Dictionary<String, Any>: return (.text, false) // Dictionaries stored as JSON text
        default: 
            // Check if it's a custom object (struct/class) that can be JSON encoded
            if let _ = value as? Codable {
                return (.text, false) // Custom objects stored as JSON text
            }
            return (.text, false) // Unknown types as text
        }
    }
    
    // MARK: - Swift → Database Conversion
    
    /// Convert Swift value to database value with unified logic
    /// 
    /// - Parameters:
    ///   - swiftValue: Swift value to convert
    ///   - columnType: Target column type
    ///   - isOptional: Whether nil is allowed
    /// - Returns: Database-compatible value
    public static func swiftToDatabaseValue(
        _ swiftValue: Any,
        columnType: FuseColumnType,
        isOptional: Bool
    ) -> FuseDatabaseValueConvertible? {
        
        let unwrappedValue = unwrapOptional(swiftValue)
        
        // Handle nil values
        guard let value = unwrappedValue else {
            if isOptional {
                return nil
            } else {
                fatalError("Non-optional column has nil value")
            }
        }
        
        // 🎯 Unified conversion logic
        switch columnType {
        case .text:
            if let string = value as? String { return string }
            
            // Handle arrays by converting to JSON
            if let array = value as? [Any] {
                return convertArrayToJSON(array)
            }
            
            // Handle dictionaries by converting to JSON
            if let dictionary = value as? [String: Any] {
                return convertDictionaryToJSON(dictionary)
            }
            
            // Handle custom Codable objects by converting to JSON
            if let codableObject = value as? Codable {
                return convertCodableToJSON(codableObject)
            }
            
            return String(describing: value)
            
        case .integer:
            if let int64 = value as? Int64 { return int64 }
            if let int = value as? Int { return Int64(int) }
            fatalError("Cannot convert \(type(of: value)) to INTEGER")
            
        case .real, .double:
            if let double = value as? Double { return double }
            if let float = value as? Float { return Double(float) }
            if let int = value as? Int { return Double(int) }
            if let int64 = value as? Int64 { return Double(int64) }
            fatalError("Cannot convert \(type(of: value)) to REAL/DOUBLE")
            
        case .numeric:
            if let double = value as? Double { return double }
            if let int64 = value as? Int64 { return int64 }
            if let int = value as? Int { return Int64(int) }
            if let float = value as? Float { return Double(float) }
            fatalError("Cannot convert \(type(of: value)) to NUMERIC")
            
        case .boolean:
            if let bool = value as? Bool { return bool }
            fatalError("Cannot convert \(type(of: value)) to BOOLEAN")
            
        case .date:
            if let date = value as? Date { return date }
            fatalError("Cannot convert \(type(of: value)) to DATE")
            
        case .blob:
            if let data = value as? Data { return data }
            fatalError("Cannot convert \(type(of: value)) to BLOB")
            
        case .any:
            if let convertible = value as? FuseDatabaseValueConvertible { return convertible }
            return String(describing: value)
        }
    }
    
    // MARK: - Database → Swift Conversion
    
    /// Convert database value to Swift type with unified logic
    /// 
    /// - Parameters:
    ///   - dbValue: Database value
    ///   - targetType: Target Swift type
    ///   - autoInfer: Enable intelligent type conversion
    /// - Returns: Converted Swift value
    public static func databaseToSwiftValue<T>(
        _ dbValue: Any?,
        targetType: T.Type,
        autoInfer: Bool = false
    ) -> T? {
        
        guard let wrappedValue = dbValue, !(wrappedValue is NSNull) else {
            return nil
        }
        
        // 🎯 Unwrap the value if it's wrapped in Any?
        let value = wrappedValue
        
        // 🎯 Unified type conversion based on target type
        switch targetType {
        case is Bool.Type:
            if let bool = value as? Bool { return bool as? T }
            // 🎯 Enhanced Bool conversion - always try integer conversion for database compatibility
            if let int = value as? Int { return (int != 0) as? T }
            if let int64 = value as? Int64 { return (int64 != 0) as? T }
            if let string = value as? String { 
                let lowercased = string.lowercased()
                if lowercased == "true" || lowercased == "1" { return true as? T }
                if lowercased == "false" || lowercased == "0" { return false as? T }
            }
            
        case is Int.Type:
            if let int = value as? Int { return int as? T }
            if let int64 = value as? Int64 { return Int(int64) as? T }
            if autoInfer {
                if let double = value as? Double, double.truncatingRemainder(dividingBy: 1) == 0 {
                    return Int(double) as? T
                }
            }
            
        case is Int64.Type:
            if let int64 = value as? Int64 { return int64 as? T }
            if let int = value as? Int { return Int64(int) as? T }
            if autoInfer {
                if let double = value as? Double, double.truncatingRemainder(dividingBy: 1) == 0 {
                    return Int64(double) as? T
                }
            }
            
        case is Double.Type:
            if let double = value as? Double { return double as? T }
            if let float = value as? Float { return Double(float) as? T }
            if let int = value as? Int { return Double(int) as? T }
            if let int64 = value as? Int64 { return Double(int64) as? T }
            
        case is Float.Type:
            if let float = value as? Float { return float as? T }
            if let double = value as? Double { return Float(double) as? T }
            if let int = value as? Int { return Float(int) as? T }
            if let int64 = value as? Int64 { return Float(int64) as? T }
            
        case is String.Type:
            if let string = value as? String { return string as? T }
            if autoInfer { return String(describing: value) as? T }
            
        case is Date.Type:
            // 🎯 Enhanced Date conversion - handle all Date types including __NSTaggedDate
            if let date = value as? Date { return date as? T }
            // Try NSDate (which includes __NSTaggedDate)
            if let nsDate = value as? NSDate { return (nsDate as Date) as? T }
            // 🎯 Always try common date conversions for database compatibility
            if let timeInterval = value as? TimeInterval {
                return Date(timeIntervalSince1970: timeInterval) as? T
            }
            if let int = value as? Int {
                return Date(timeIntervalSince1970: TimeInterval(int)) as? T
            }
            if let int64 = value as? Int64 {
                return Date(timeIntervalSince1970: TimeInterval(int64)) as? T
            }
            if let double = value as? Double {
                return Date(timeIntervalSince1970: double) as? T
            }
            if let string = value as? String {
                // Try ISO8601 format first
                let iso8601Formatter = ISO8601DateFormatter()
                if let date = iso8601Formatter.date(from: string) {
                    return date as? T
                }
                
                // Try common database date formats
                let formatters = [
                    // SQLite/GRDB default format: "2023-03-15 13:20:00.000"
                    "yyyy-MM-dd HH:mm:ss.SSS",
                    // Without milliseconds: "2023-03-15 13:20:00"
                    "yyyy-MM-dd HH:mm:ss",
                    // Date only: "2023-03-15"
                    "yyyy-MM-dd",
                    // ISO with T: "2023-03-15T13:20:00.000Z"
                    "yyyy-MM-dd'T'HH:mm:ss.SSSZ",
                    // ISO without Z: "2023-03-15T13:20:00.000"
                    "yyyy-MM-dd'T'HH:mm:ss.SSS"
                ]
                
                for formatString in formatters {
                    let formatter = DateFormatter()
                    formatter.dateFormat = formatString
                    formatter.locale = Locale(identifier: "en_US_POSIX")
                    formatter.timeZone = TimeZone(secondsFromGMT: 0) // UTC
                    
                    if let date = formatter.date(from: string) {
                        return date as? T
                    }
                }
                
                // Try timestamp as string
                if let timestamp = TimeInterval(string) {
                    return Date(timeIntervalSince1970: timestamp) as? T
                }
            }
            
        case is Data.Type:
            if let data = value as? Data { return data as? T }
            if autoInfer {
                if let string = value as? String {
                    if let data = Data(base64Encoded: string) {
                        return data as? T
                    }
                    return string.data(using: .utf8) as? T
                }
            }
            
        default:
            // For complex types (arrays, dictionaries, custom objects), try to decode using JSONDecoder
            if let jsonString = value as? String,
               let decodableType = targetType as? Decodable.Type {
                do {
                    guard let jsonData = jsonString.data(using: .utf8) else { return nil }
                    let decoder = JSONDecoder()
                    let decodedObject = try decoder.decode(decodableType, from: jsonData)
                    return decodedObject as? T
                } catch {
                    // If JSONDecoder fails, this might not be a JSON string or incompatible type
                    return nil
                }
            }
            
            // Fallback: if it's already the correct type, return it directly
            if let directValue = value as? T {
                return directValue
            }
            
            break
        }
        
        return nil
    }
    
    // MARK: - Helper Methods
    
    /// Unwrap optional values with unified logic
    /// 
    /// - Parameter value: Value to unwrap
    /// - Returns: Unwrapped value or nil
    public static func unwrapOptional(_ value: Any) -> Any? {
        let mirror = Mirror(reflecting: value)
        if mirror.displayStyle == .optional {
            return mirror.children.first?.value
        }
        return value
    }
    
    // MARK: - Private Helper Methods
    
    /// Convert array to JSON string, handling complex nested objects
    private static func convertArrayToJSON(_ array: [Any]) -> String {
        // First try to check if all elements are Foundation types
        let isFoundationCompatible = array.allSatisfy { element in
            element is String || element is NSNumber || element is Bool || 
            element is Int || element is Double || element is Float ||
            element is NSNull || element is [String: Any] || element is [Any]
        }
        
        if isFoundationCompatible {
            // Use JSONSerialization for simple types (faster)
            do {
                let jsonData = try JSONSerialization.data(withJSONObject: array, options: [])
                return String(data: jsonData, encoding: .utf8) ?? "[]"
            } catch {
                // Fallback to JSONEncoder if JSONSerialization fails
                return convertArrayWithJSONEncoder(array)
            }
        } else {
            // Use JSONEncoder for complex types containing Codable objects
            return convertArrayWithJSONEncoder(array)
        }
    }
    
    /// Convert array using JSONEncoder (handles Codable objects)
    private static func convertArrayWithJSONEncoder(_ array: [Any]) -> String {
        do {
            // Convert each element to AnyEncodable if it's Encodable
            let encodableArray = array.map { element -> AnyEncodable in
                if let encodable = element as? Encodable {
                    return AnyEncodable(encodable)
                } else {
                    // For non-Encodable types, convert to string representation
                    return AnyEncodable(String(describing: element))
                }
            }
            
            let jsonData = try JSONEncoder().encode(encodableArray)
            return String(data: jsonData, encoding: .utf8) ?? "[]"
        } catch {
            return "[]" // Fallback to empty array
        }
    }
    
    /// Convert dictionary to JSON string, handling complex nested objects
    private static func convertDictionaryToJSON(_ dictionary: [String: Any]) -> String {
        // First try to check if all values are Foundation types
        let isFoundationCompatible = dictionary.values.allSatisfy { value in
            value is String || value is NSNumber || value is Bool || 
            value is Int || value is Double || value is Float ||
            value is NSNull || value is [String: Any] || value is [Any]
        }
        
        if isFoundationCompatible {
            // Use JSONSerialization for simple types (faster)
            do {
                let jsonData = try JSONSerialization.data(withJSONObject: dictionary, options: [])
                return String(data: jsonData, encoding: .utf8) ?? "{}"
            } catch {
                // Fallback to JSONEncoder if JSONSerialization fails
                return convertDictionaryWithJSONEncoder(dictionary)
            }
        } else {
            // Use JSONEncoder for complex types containing Codable objects
            return convertDictionaryWithJSONEncoder(dictionary)
        }
    }
    
    /// Convert dictionary using JSONEncoder (handles Codable objects)
    private static func convertDictionaryWithJSONEncoder(_ dictionary: [String: Any]) -> String {
        do {
            // Convert each value to AnyEncodable if it's Encodable
            let encodableDictionary = dictionary.mapValues { value -> AnyEncodable in
                if let encodable = value as? Encodable {
                    return AnyEncodable(encodable)
                } else {
                    // For non-Encodable types, convert to string representation
                    return AnyEncodable(String(describing: value))
                }
            }
            
            let jsonData = try JSONEncoder().encode(encodableDictionary)
            return String(data: jsonData, encoding: .utf8) ?? "{}"
        } catch {
            return "{}" // Fallback to empty object
        }
    }
    
    /// Convert Codable object to JSON string
    private static func convertCodableToJSON(_ codableObject: Codable) -> String {
        do {
            // Check if it's a struct or class
            let mirror = Mirror(reflecting: codableObject)
            if let style = mirror.displayStyle, style == .struct || style == .class {
                // Codable already includes Encodable, so we can directly use it
                let jsonData = try JSONEncoder().encode(AnyEncodable(codableObject))
                return String(data: jsonData, encoding: .utf8) ?? "{}"
            }
            return "{}"
        } catch {
            return "{}" // Fallback to empty object
        }
    }

} 