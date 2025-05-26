import Foundation

/// Unified data type handler for FuseKeychainManager
/// 
/// This internal enumeration manages the encoding and decoding of all supported
/// Codable types for Keychain storage. It uses type prefixes to ensure data
/// integrity and enables proper type reconstruction during retrieval operations.
/// The system optimizes storage for primitive types while supporting complex
/// Codable objects through JSON serialization.
internal enum FuseKeychainDataType {
    case string(String)
    case data(Data)
    case int(Int)
    case double(Double)
    case bool(Bool)
    case date(Date)
    case json(Data)
    
    /// Type prefix constants
    private struct Prefix {
        static let string = "STR:"
        static let data = "DAT:"
        static let int = "INT:"
        static let double = "DBL:"
        static let bool = "BOL:"
        static let date = "DTE:"
        static let json = "JSN:"
    }
    
    /// Minimum valid data length (prefix length)
    private static let minimumDataLength = 4
    
    // MARK: - Encoding
    
    /// Encodes the data type into a Data representation with type prefix
    /// - Parameter dateFormatter: ISO8601 formatter for date encoding
    /// - Parameter jsonEncoder: JSON encoder for complex types
    /// - Returns: Encoded data with type prefix
    /// - Throws: FuseKeychainError.encodingError if encoding fails
    func encode(dateFormatter: ISO8601DateFormatter, jsonEncoder: JSONEncoder) throws -> Data {
        let prefixedString: String
        
        switch self {
        case .string(let value):
            guard let encodedData = value.data(using: .utf8) else {
                throw FuseKeychainError.encodingError
            }
            // For string, append the UTF-8 data directly after prefix
            let prefixData = Prefix.string.data(using: .utf8)!
            return prefixData + encodedData
            
        case .data(let value):
            let base64String = value.base64EncodedString()
            prefixedString = Prefix.data + base64String
            
        case .int(let value):
            prefixedString = Prefix.int + String(value)
            
        case .double(let value):
            prefixedString = Prefix.double + String(value)
            
        case .bool(let value):
            prefixedString = Prefix.bool + (value ? "1" : "0")
            
        case .date(let value):
            let dateString = dateFormatter.string(from: value)
            prefixedString = Prefix.date + dateString
            
        case .json(let jsonData):
            let base64String = jsonData.base64EncodedString()
            prefixedString = Prefix.json + base64String
        }
        
        guard let data = prefixedString.data(using: .utf8) else {
            throw FuseKeychainError.encodingError
        }
        return data
    }
    
    // MARK: - Decoding
    
    /// Attempts to decode raw keychain data into the specified type
    /// - Parameters:
    ///   - data: Raw data from keychain
    ///   - targetType: The type to decode into
    ///   - dateFormatter: ISO8601 formatter for date decoding
    ///   - jsonDecoder: JSON decoder for complex types
    /// - Returns: Decoded value of the specified type, or nil if decoding fails
    static func decode<T: Codable>(
        _ data: Data,
        as targetType: T.Type,
        dateFormatter: ISO8601DateFormatter,
        jsonDecoder: JSONDecoder
    ) -> T? {
        // Extract type prefix and content
        guard let fullString = String(data: data, encoding: .utf8),
              fullString.count >= minimumDataLength else {
            return nil
        }
        
        let prefix = String(fullString.prefix(minimumDataLength))
        let contentString = String(fullString.dropFirst(minimumDataLength))
        
        // Decode based on target type and validate prefix
        switch targetType {
        case is String.Type:
            guard prefix == Prefix.string else { return nil }
            return contentString as? T
            
        case is Data.Type:
            guard prefix == Prefix.data else { return nil }
            // Handle empty Data case
            if contentString.isEmpty {
                return Data() as? T
            }
            guard let decodedData = Data(base64Encoded: contentString) else { return nil }
            return decodedData as? T
            
        case is Int.Type:
            guard prefix == Prefix.int, let number = Int(contentString) else { return nil }
            return number as? T
            
        case is Double.Type:
            guard prefix == Prefix.double, let number = Double(contentString) else { return nil }
            return number as? T
            
        case is Bool.Type:
            guard prefix == Prefix.bool else { return nil }
            return (contentString == "1") as? T
            
        case is Date.Type:
            guard prefix == Prefix.date, let date = dateFormatter.date(from: contentString) else { return nil }
            return date as? T
            
        default:
            // Handle JSON-encoded Codable types
            guard prefix == Prefix.json else { return nil }
            // Handle empty JSON case (though this should not happen in practice)
            if contentString.isEmpty {
                return nil
            }
            guard let jsonData = Data(base64Encoded: contentString) else { return nil }
            return try? jsonDecoder.decode(targetType, from: jsonData)
        }
    }
    
    // MARK: - Factory Methods
    
    /// Creates a FuseKeychainDataType instance for any Codable value
    /// - Parameters:
    ///   - value: The value to wrap
    ///   - jsonEncoder: JSON encoder for complex types
    /// - Returns: Appropriate FuseKeychainDataType case
    /// - Throws: FuseKeychainError.encodingError if JSON encoding fails
    static func from<T: Codable>(_ value: T, jsonEncoder: JSONEncoder) throws -> FuseKeychainDataType {
        switch value {
        case let stringValue as String:
            return .string(stringValue)
        case let dataValue as Data:
            return .data(dataValue)
        case let intValue as Int:
            return .int(intValue)
        case let doubleValue as Double:
            return .double(doubleValue)
        case let boolValue as Bool:
            return .bool(boolValue)
        case let dateValue as Date:
            return .date(dateValue)
        default:
            // Encode as JSON for custom Codable types
            let jsonData = try jsonEncoder.encode(value)
            return .json(jsonData)
        }
    }
    
    // MARK: - Utility
    
    /// Returns the type prefix for debugging purposes
    var typePrefix: String {
        switch self {
        case .string: return Prefix.string
        case .data: return Prefix.data
        case .int: return Prefix.int
        case .double: return Prefix.double
        case .bool: return Prefix.bool
        case .date: return Prefix.date
        case .json: return Prefix.json
        }
    }
    
    /// Returns a human-readable description of the data type
    var description: String {
        switch self {
        case .string(let value): return "String(\"\(value)\")"
        case .data(let value): return "Data(\(value.count) bytes)"
        case .int(let value): return "Int(\(value))"
        case .double(let value): return "Double(\(value))"
        case .bool(let value): return "Bool(\(value))"
        case .date(let value): return "Date(\(value))"
        case .json: return "JSON(Codable)"
        }
    }
} 