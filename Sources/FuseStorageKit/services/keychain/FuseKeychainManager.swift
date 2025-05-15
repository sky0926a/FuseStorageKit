import Foundation
import Security // Import Security framework

/// Implementation of the FuseKeychainManageable protocol
public class FuseKeychainManager: FuseKeychainManageable {
    public init() {}

    public func save(key: String, value: String, accessGroup: String? = nil) throws { // Add accessGroup parameter
        let data = value.data(using: .utf8)!
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]

        if let accessGroup = accessGroup { // Add access group to query
            query[kSecAttrAccessGroup as String] = accessGroup
        }

        SecItemDelete(query as CFDictionary) // Remove existing item if it exists
        let status = SecItemAdd(query as CFDictionary, nil)
        if status != errSecSuccess {
            throw NSError(domain: "FuseKeychainManager", code: Int(status), userInfo: nil)
        }
    }

    public func retrieve(key: String, accessGroup: String? = nil) throws -> String? { // Add accessGroup parameter
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne       
        ]

        if let accessGroup = accessGroup { // Add access group to query
            query[kSecAttrAccessGroup as String] = accessGroup
        }

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        if status == errSecSuccess, let data = item as? Data {
            return String(data: data, encoding: .utf8)
        } else if status == errSecItemNotFound {
            return nil
        } else {
            throw NSError(domain: "FuseKeychainManager", code: Int(status), userInfo: nil)
        }
    }

    public func delete(key: String, accessGroup: String? = nil) throws { // Add accessGroup parameter
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]

        if let accessGroup = accessGroup { // Add access group to query
            query[kSecAttrAccessGroup as String] = accessGroup
        }

        let status = SecItemDelete(query as CFDictionary)
        if status != errSecSuccess && status != errSecItemNotFound {
            throw NSError(domain: "FuseKeychainManager", code: Int(status), userInfo: nil)
        }
    }
}