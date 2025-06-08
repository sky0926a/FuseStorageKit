import Foundation
import Security

// MARK: - Keychain Manager

/// A secure preferences manager implementation using the system Keychain
/// 
/// This class provides secure storage for sensitive data using the iOS/macOS Keychain,
/// offering hardware-level encryption and access control. It supports all Codable types
/// with optimized storage for primitive types and JSON encoding for complex objects.
public class FuseKeychainManager: FusePreferencesManageable {
    private let service: String
    private let accessGroup: String?
    private let accessibility: FuseKeychainAccessibility
    private let dateFormatter: ISO8601DateFormatter
    private let jsonEncoder: JSONEncoder
    private let jsonDecoder: JSONDecoder
    private let store: FuseKeychainStore

    /// Convenience initializer for standard Keychain configuration
    /// 
    /// Creates a Keychain manager with the specified service identifier and optional
    /// access group for sharing data between apps. Uses the default SecItem-based
    /// Keychain store implementation.
    /// 
    /// - Parameters:
    ///   - service: The service identifier for Keychain items
    ///   - accessGroup: Optional access group for sharing between apps
    ///   - accessibility: The accessibility level for stored items
    public convenience init(service: String,
                            accessGroup: String? = nil,
                            accessibility: FuseKeychainAccessibility = .whenUnlocked) {
        self.init(service: service,
                  accessGroup: accessGroup,
                  accessibility: accessibility,
                  store: FuseSecItemKeychainStore())
    }

    /// Designated initializer (internal for testing)
    init(service: String,
         accessGroup: String?,
         accessibility: FuseKeychainAccessibility,
         store: FuseKeychainStore) {
        self.service = service
        self.accessGroup = accessGroup
        self.accessibility = accessibility
        self.dateFormatter = ISO8601DateFormatter()
        // configure once
        self.jsonEncoder = JSONEncoder()
        self.jsonEncoder.dateEncodingStrategy = .iso8601
        self.jsonDecoder = JSONDecoder()
        self.jsonDecoder.dateDecodingStrategy = .iso8601
        self.store = store
    }

    public func set<Value: Codable>(_ value: Value, forKey key: String) throws {
        // Use unified type system to handle encoding
        let dataType = try FuseKeychainDataType.from(value, jsonEncoder: jsonEncoder)
        let data = try dataType.encode(dateFormatter: dateFormatter, jsonEncoder: jsonEncoder)

        var query = baseQuery(key: key)
        query[kSecValueData as String] = data

        let status = store.copyMatching(query as CFDictionary, result: nil)
        switch status {
        case errSecSuccess:
            let attributes = [kSecValueData as String: data] as CFDictionary
            let updateStatus = store.updateItem(query as CFDictionary, attributes: attributes)
            guard updateStatus == errSecSuccess else {
                throw FuseKeychainError.unhandledError(status: updateStatus)
            }
        case errSecItemNotFound:
            let addStatus = store.addItem(query as CFDictionary)
            guard addStatus == errSecSuccess else {
                throw FuseKeychainError.unhandledError(status: addStatus)
            }
        default:
            throw FuseKeychainError.unhandledError(status: status)
        }
    }

    public func get<Value: Codable>(forKey key: String) -> Value? {
        var query = baseQuery(key: key)
        query[kSecReturnData as String] = kCFBooleanTrue
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: AnyObject?
        let status = store.copyMatching(query as CFDictionary, result: &result)
        guard status == errSecSuccess, let data = result as? Data else { return nil }

        // Use unified type system to handle decoding
        return FuseKeychainDataType.decode(
            data,
            as: Value.self,
            dateFormatter: dateFormatter,
            jsonDecoder: jsonDecoder
        )
    }

    public func removeValue(forKey key: String) {
        let query = baseQuery(key: key)
        _ = store.deleteItem(query as CFDictionary)
    }

    public func containsValue(forKey key: String) -> Bool {
        var query = baseQuery(key: key)
        query[kSecReturnData as String] = kCFBooleanFalse
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        return store.copyMatching(query as CFDictionary, result: nil) == errSecSuccess
    }

    private func baseQuery(key: String) -> [String: Any] {
        var dict: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecAttrAccessible as String: accessibility.secValue
        ]
        if let group = accessGroup {
            dict[kSecAttrAccessGroup as String] = group
        }
        return dict
    }
}
