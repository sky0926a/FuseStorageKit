import Foundation

/// A custom decoder that directly maps from [String: Any?] values to Swift structs
/// without using JSON serialization. This provides zero-overhead decoding with precise
/// type conversion based on FuseColumnType definitions.
public class FuseDirectDecoder {
    private let values: [String: Any?]?
    private let row: FuseDatabaseRow?
    private let tableDefinition: FuseTableDefinition?
    private let inferredTypes: [String: (FuseColumnType, Bool)]?
    private let autoInfer: Bool
    
    /// Initialize with table definition (original approach)
    /// 
    /// - Parameters:
    ///   - values: Dictionary of property values from database
    ///   - tableDefinition: Table definition for type validation
    init(values: [String: Any?], tableDefinition: FuseTableDefinition) {
        self.values = values
        self.row = nil
        self.tableDefinition = tableDefinition
        self.inferredTypes = nil
        self.autoInfer = false
    }
    
    /// Initialize with inferred types (intermediate approach)
    /// 
    /// - Parameters:
    ///   - values: Dictionary of property values from database
    ///   - inferredTypes: Dictionary mapping property names to (column type, is optional)
    init(values: [String: Any?], inferredTypes: [String: (FuseColumnType, Bool)]) {
        self.values = values
        self.row = nil
        self.tableDefinition = nil
        self.inferredTypes = inferredTypes
        self.autoInfer = false
    }
    
    /// Initialize with auto-inference (intermediate approach)
    /// 
    /// - Parameters:
    ///   - values: Dictionary of property values from database
    ///   - autoInfer: Enable automatic type inference during decoding
    init(values: [String: Any?], autoInfer: Bool) {
        self.values = values
        self.row = nil
        self.tableDefinition = nil
        self.inferredTypes = nil
        self.autoInfer = autoInfer
    }
    
    /// 🎯 NEW: Initialize directly with database row (most efficient approach)
    /// 
    /// - Parameters:
    ///   - row: Database row to decode from
    ///   - autoInfer: Enable automatic type inference during decoding
    public init(row: FuseDatabaseRow, autoInfer: Bool = true) {
        self.values = nil
        self.row = row
        self.tableDefinition = nil
        self.inferredTypes = nil
        self.autoInfer = autoInfer
    }
    
    /// 🎯 NEW: Initialize with database row and table definition (best of both worlds)
    /// 
    /// - Parameters:
    ///   - row: Database row to decode from
    ///   - tableDefinition: Table definition for precise type validation
    public init(row: FuseDatabaseRow, tableDefinition: FuseTableDefinition) {
        self.values = nil
        self.row = row
        self.tableDefinition = tableDefinition
        self.inferredTypes = nil
        self.autoInfer = false
    }
    
    /// 🎯 NEW: Initialize with database row, table definition, and auto-inference (ultimate flexibility)
    /// 
    /// - Parameters:
    ///   - row: Database row to decode from
    ///   - tableDefinition: Table definition for precise type validation
    ///   - autoInfer: Enable automatic type inference for columns not in tableDefinition
    public init(row: FuseDatabaseRow, tableDefinition: FuseTableDefinition, autoInfer: Bool) {
        self.values = nil
        self.row = row
        self.tableDefinition = tableDefinition
        self.inferredTypes = nil
        self.autoInfer = autoInfer
    }
    
    /// Decode the values into a target Swift type
    /// 
    /// - Parameter type: Target Swift type to decode to
    /// - Returns: Decoded instance
    /// - Throws: DecodingError if decoding fails
    public func decode<T: Decodable>(_ type: T.Type) throws -> T {
        let decoder = DirectDecoder(
            values: values,
            row: row,
            tableDefinition: tableDefinition, 
            inferredTypes: inferredTypes,
            autoInfer: autoInfer
        )
        return try T(from: decoder)
    }
}

/// Internal implementation of the Decoder protocol for direct value mapping
private class DirectDecoder: Decoder {
    let values: [String: Any?]?
    let row: FuseDatabaseRow?
    let tableDefinition: FuseTableDefinition?
    let inferredTypes: [String: (FuseColumnType, Bool)]?
    let autoInfer: Bool
    var codingPath: [CodingKey] = []
    var userInfo: [CodingUserInfoKey: Any] = [:]
    
    init(values: [String: Any?]?, row: FuseDatabaseRow?, tableDefinition: FuseTableDefinition?, inferredTypes: [String: (FuseColumnType, Bool)]?, autoInfer: Bool) {
        self.values = values
        self.row = row
        self.tableDefinition = tableDefinition
        self.inferredTypes = inferredTypes
        self.autoInfer = autoInfer
    }
    
    func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> where Key: CodingKey {
        let container = DirectKeyedDecodingContainer<Key>(
            values: values,
            row: row,
            tableDefinition: tableDefinition,
            inferredTypes: inferredTypes,
            autoInfer: autoInfer,
            codingPath: codingPath
        )
        return KeyedDecodingContainer(container)
    }
    
    func unkeyedContainer() throws -> UnkeyedDecodingContainer {
        throw DecodingError.dataCorrupted(.init(codingPath: codingPath, debugDescription: "Unkeyed containers not supported - arrays should be handled through FuseTypeConverter"))
    }
    
    func singleValueContainer() throws -> SingleValueDecodingContainer {
        throw DecodingError.dataCorrupted(.init(codingPath: codingPath, debugDescription: "Single value containers not supported"))
    }
}

/// Internal keyed decoding container for direct value mapping
private struct DirectKeyedDecodingContainer<Key: CodingKey>: KeyedDecodingContainerProtocol {
    let values: [String: Any?]?
    let row: FuseDatabaseRow?
    let tableDefinition: FuseTableDefinition?
    let inferredTypes: [String: (FuseColumnType, Bool)]?
    let autoInfer: Bool
    let codingPath: [CodingKey]
    
    var allKeys: [Key] {
        if let values = values {
            return values.compactMap { Key(stringValue: $0.key) }
        } else if let row = row {
            return row.columnNames.compactMap { Key(stringValue: $0) }
        } else {
            return []
        }
    }
    
    func contains(_ key: Key) -> Bool {
        if let values = values {
            return values[key.stringValue] != nil
        } else if let row = row {
            return row.columnNames.contains(key.stringValue)
        } else {
            return false
        }
    }
    
    // MARK: - Helper Methods
    
    /// Get value for a key from either values dictionary or database row
    private func getValue(forKey keyString: String) -> Any? {
        if let values = values {
            return values[keyString] ?? nil
        } else if let row = row {
            return row[keyString]
        } else {
            return nil
        }
    }
    
    /// Unified decode method that handles all types through FuseTypeConverter
    private func decodeValue<T>(_ type: T.Type, forKey key: Key, isOptional: Bool = false) throws -> T {
        let keyString = key.stringValue
        let value = getValue(forKey: keyString)
        
        // Handle nil values
        if value == nil || value is NSNull {
            if isOptional {
                // For optionals, return nil wrapped in the optional type
                return Optional<Any>.none as! T
            } else {
                // For non-optionals, throw appropriate error
                if value == nil {
                    throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: codingPath, debugDescription: "Key '\(keyString)' not found"))
                } else {
                    throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: codingPath + [key], debugDescription: "Value for key '\(keyString)' is nil"))
                }
            }
        }
        
        // Use FuseTypeConverter for all conversions
        if let converted = FuseTypeConverter.databaseToSwiftValue(value, targetType: type, autoInfer: autoInfer || inferredTypes != nil) {
            return converted
        }
        
        // If conversion failed, throw error
        let context = DecodingError.Context(codingPath: codingPath + [key], debugDescription: "Failed to convert value to \(type)")
        throw DecodingError.typeMismatch(type, context)
    }
    
    // MARK: - Decoding Methods
    
    func decodeNil(forKey key: Key) throws -> Bool {
        let value = getValue(forKey: key.stringValue)
        return value == nil || value is NSNull
    }
    
    func decode<T>(_ type: T.Type, forKey key: Key) throws -> T where T: Decodable {
        // Check if this is an optional type by trying to decode as optional first
        let isOptional = "\(type)".contains("Optional")
        return try decodeValue(type, forKey: key, isOptional: isOptional)
    }
    
    func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type, forKey key: Key) throws -> KeyedDecodingContainer<NestedKey> where NestedKey: CodingKey {
        throw DecodingError.dataCorrupted(.init(codingPath: codingPath + [key], debugDescription: "Nested containers not supported"))
    }
    
    func nestedUnkeyedContainer(forKey key: Key) throws -> UnkeyedDecodingContainer {
        throw DecodingError.dataCorrupted(.init(codingPath: codingPath + [key], debugDescription: "Nested unkeyed containers not supported"))
    }
    
    func superDecoder() throws -> Decoder {
        throw DecodingError.dataCorrupted(.init(codingPath: codingPath, debugDescription: "Super decoders not supported"))
    }
    
    func superDecoder(forKey key: Key) throws -> Decoder {
        throw DecodingError.dataCorrupted(.init(codingPath: codingPath + [key], debugDescription: "Super decoders not supported"))
    }
}