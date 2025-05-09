import Foundation

/// Implementation of FusePreferencesManageable that uses UserDefaults with Codable types
public final class FusePreferencesManager: FusePreferencesManageable {
  private let defaults: UserDefaults
  
  /// Initialize with optional suite name for UserDefaults
  /// - Parameter suiteName: The suite name for UserDefaults, uses standard UserDefaults if nil
  public init(suiteName: String? = nil) {
    defaults = suiteName.flatMap { UserDefaults(suiteName: $0) } ?? .standard
  }
  
  /// Store a Codable value for the specified key
  /// - Parameters:
  ///   - value: The value to store, must conform to Codable
  ///   - key: The key to associate with the value
  public func set<Value>(_ value: Value, forKey key: String) where Value: Codable {
    let data = try? JSONEncoder().encode(value)
    defaults.set(data, forKey: key)
  }
  
  /// Retrieve a Codable value for the specified key
  /// - Parameter key: The key associated with the value
  /// - Returns: The value if found and successfully decoded, or nil otherwise
  public func get<Value>(forKey key: String) -> Value? where Value: Codable {
    guard let data = defaults.data(forKey: key) else { return nil }
    return try? JSONDecoder().decode(Value.self, from: data)
  }
} 