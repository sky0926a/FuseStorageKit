import Foundation

/// Protocol defining keychain management operations
public protocol FuseKeychainManageable {
    func save(key: String, value: String) throws
    func retrieve(key: String) throws -> String?
    func delete(key: String) throws
}