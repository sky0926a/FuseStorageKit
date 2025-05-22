import Foundation
import Security // Import Security framework

/// Implementation of the FuseKeychainManageable protocol
public class FuseKeychainManager: FusePreferencesManageable {
    private let service: String?
    private let accessGroup: String?
    private let accessibility: CFString

    init(service: String? = nil,
         accessGroup: String? = nil,
         accessibility: FuseKeychainAccessibility = .whenUnlocked) {
        self.service = service
        self.accessGroup = accessGroup
        self.accessibility = accessibility.secValue
    }

    public func set<Value: Codable>(_ value: Value, forKey key: String) {
        // Prepare data: basic types without JSON
        let data: Data
        switch value {
        case let str as String:
            data = Data(str.utf8)
        case let d as Data:
            data = d
        case let n as Int:
            data = Data(String(n).utf8)
        case let n as Double:
            data = Data(String(n).utf8)
        case let b as Bool:
            data = Data(b ? [1] : [0])
        default:
            // Fallback to JSON encode
            data = (try? JSONEncoder().encode(value)) ?? Data()
        }

        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecAttrAccessible as String: accessibility,
            kSecValueData as String: data
        ]
        if let service = service {
            query[kSecAttrService as String] = service
        }
        if let group = accessGroup {
            query[kSecAttrAccessGroup as String] = group
        }
        // Upsert
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }

    public func get<Value: Codable>(forKey key: String) -> Value? {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        if let service = service {
            query[kSecAttrService as String] = service
        }
        if let group = accessGroup {
            query[kSecAttrAccessGroup as String] = group
        }
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else {
            return nil
        }
        // Decode basic types
        if Value.self == String.self, let str = String(data: data, encoding: .utf8) {
            return str as? Value
        }
        if Value.self == Data.self {
            return data as? Value
        }
        if Value.self == Int.self, let str = String(data: data, encoding: .utf8), let i = Int(str) {
            return i as? Value
        }
        if Value.self == Double.self, let str = String(data: data, encoding: .utf8), let d = Double(str) {
            return d as? Value
        }
        if Value.self == Bool.self {
            return (data.first == 1) as? Value
        }
        // Fallback to JSON decode
        return (try? JSONDecoder().decode(Value.self, from: data))
    }

    public func removeValue(forKey key: String) {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        if let service = service {
            query[kSecAttrService as String] = service
        }
        if let group = accessGroup {
            query[kSecAttrAccessGroup as String] = group
        }
        SecItemDelete(query as CFDictionary)
    }

    public func containsValue(forKey key: String) -> Bool {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: false,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        if let service = service {
            query[kSecAttrService as String] = service
        }
        if let group = accessGroup {
            query[kSecAttrAccessGroup as String] = group
        }
        let status = SecItemCopyMatching(query as CFDictionary, nil)
        return status == errSecSuccess
    }
}
