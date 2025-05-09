import Foundation

/// Protocol defining user preferences operations (UserDefaults service)
public protocol FusePreferencesManageable {
  /// Store a Codable value for the specified key
  /// - Parameters:
  ///   - value: The value to store, must conform to Codable
  ///   - key: The key to associate with the value
  func set<Value: Codable>(_ value: Value, forKey key: String)
  
  /// Retrieve a Codable value for the specified key
  /// - Parameter key: The key associated with the value
  /// - Returns: The value if found and successfully decoded, or nil otherwise
  func get<Value: Codable>(forKey key: String) -> Value?
} 