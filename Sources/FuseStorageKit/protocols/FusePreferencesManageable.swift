/// Defines a type-safe, Codable-backed key–value store (e.g. on top of UserDefaults).
public protocol FusePreferencesManageable {
    /// Store a Codable value for the specified key.
    ///
    /// - Parameters:
    ///   - value: The value to store.
    ///   - key:   The key under which to store the value.
    /// - Throws: Encoding or storage errors.
    func set<Value: Codable>(_ value: Value, forKey key: String)

    /// Retrieve a Codable value for the specified key.
    ///
    /// - Parameter key: The key whose value to retrieve.
    /// - Returns: The decoded value, or `nil` if no value was stored.
    /// - Throws: Retrieval or decoding errors.
    func get<Value: Codable>(forKey key: String) -> Value?

    /// Remove any stored value for the given key.
    ///
    /// - Parameter key: The key to clear.
    func removeValue(forKey key: String)

    /// Returns whether a value exists for the given key.
    ///
    /// - Parameter key: The key to check.
    /// - Returns: `true` if a value (even if it decodes to `nil`) is present.
    func containsValue(forKey key: String) -> Bool
}
