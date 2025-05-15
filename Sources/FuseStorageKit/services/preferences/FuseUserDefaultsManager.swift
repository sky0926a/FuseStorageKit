import Foundation

/// A manager for storing and retrieving Codable values in UserDefaults.
///
/// This class optimizes storage by using UserDefaults' native APIs for common
/// value types (String, Int, Bool, Double, Float, Data, URL, Date) and
/// falling back to JSON encoding/decoding for custom Codable types and collections.
public final class FuseUserDefaultsManager: FusePreferencesManageable {

    /// The underlying UserDefaults instance.
    private let defaults: UserDefaults
    /// JSON encoder configured for Codable object storage.
    private let encoder: JSONEncoder
    /// JSON decoder configured for Codable object retrieval.
    private let decoder: JSONDecoder

    /// Initializes the manager with an optional suite name.
    ///
    /// - Parameters:
    ///   - suiteName: An optional suite name for namespaced UserDefaults.
    ///                If nil, `UserDefaults.standard` is used.
    public init(suiteName: String? = nil) {
        self.defaults = UserDefaults(suiteName: suiteName) ?? .standard
        self.encoder = JSONEncoder()
        self.encoder.dateEncodingStrategy = .iso8601
        self.decoder = JSONDecoder()
        self.decoder.dateDecodingStrategy = .iso8601
    }

    /// Stores a Codable value for the specified key.
    ///
    /// - Parameters:
    ///   - value: The Codable value to store.
    ///   - key: The key under which to store the value.
    /// - Throws: Encoding or storage errors.
    ///
    /// This method uses native UserDefaults APIs for primitive types and Date.
    /// Custom types and collections are serialized to Data via JSONEncoder.
    public func set<Value>(_ value: Value, forKey key: String) throws where Value: Codable {
        switch value {
        case let v as String:
            defaults.set(v, forKey: key)
        case let v as Int:
            defaults.set(v, forKey: key)
        case let v as Bool:
            defaults.set(v, forKey: key)
        case let v as Double:
            defaults.set(v, forKey: key)
        case let v as Float:
            defaults.set(v, forKey: key)
        case let v as Data:
            defaults.set(v, forKey: key)
        case let v as URL:
            defaults.set(v, forKey: key)
        case let v as Date:
            defaults.set(v, forKey: key)
        default:
            // Fallback: encode custom Codable types to JSON data
            let data = try encoder.encode(value)
            defaults.set(data, forKey: key)
        }
    }

    /// Retrieves a Codable value for the specified key.
    ///
    /// - Parameter key: The key associated with the stored value.
    /// - Returns: The decoded value if present and decodable, or nil otherwise.
    ///
    /// This method first attempts native UserDefaults APIs for primitive types and Date.
    /// If the value type is not one of those, it falls back to JSON decoding.
    public func get<Value>(forKey key: String) -> Value? where Value: Codable {
        // Native String retrieval with type safety
        if Value.self == String.self {
            guard let v = defaults.object(forKey: key) as? String else { return nil }
            return v as? Value
        }
        // Native Int retrieval (distinguish absence vs zero)
        if Value.self == Int.self {
            guard let v = defaults.object(forKey: key) as? Int else { return nil }
            return v as? Value
        }
        // Native Bool retrieval (distinguish absence vs false)
        if Value.self == Bool.self {
            guard let v = defaults.object(forKey: key) as? Bool else { return nil }
            return v as? Value
        }
        // Native Double retrieval
        if Value.self == Double.self {
            guard let v = defaults.object(forKey: key) as? Double else { return nil }
            return v as? Value
        }
        // Native Float retrieval
        if Value.self == Float.self {
            guard let v = defaults.object(forKey: key) as? Float else { return nil }
            return v as? Value
        }
        // Native Data retrieval
        if Value.self == Data.self {
            return defaults.data(forKey: key) as? Value
        }
        // Native URL retrieval
        if Value.self == URL.self {
            return defaults.url(forKey: key) as? Value
        }
        // Native Date retrieval
        if Value.self == Date.self {
            guard let v = defaults.object(forKey: key) as? Date else { return nil }
            return v as? Value
        }

        // Fallback: decode custom Codable types from JSON data
        guard let data = defaults.data(forKey: key) else { return nil }
        do {
            return try decoder.decode(Value.self, from: data)
        } catch {
            assertionFailure("Failed to JSON-decode value for key '\(key)': \(error)")
            return nil
        }
    }
    
    /// Removes the value associated with the specified key.
    ///
    /// - Parameter key: The key of the value to remove.
    public func removeValue(forKey key: String) {
        defaults.removeObject(forKey: key)
    }

    /// Returns whether a value exists for the specified key.
    ///
    /// - Parameter key: The key to check.
    /// - Returns: True if a value (even if it decodes to nil) is present in UserDefaults.
    public func containsValue(forKey key: String) -> Bool {
        return defaults.object(forKey: key) != nil
    }
}
