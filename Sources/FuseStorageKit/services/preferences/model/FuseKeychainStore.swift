import Foundation
import Security

/// Protocol defining the interface for Keychain storage operations
/// 
/// This protocol abstracts the Security framework's Keychain operations,
/// enabling dependency injection and testability for Keychain-based storage.
/// It provides a clean interface for the core Keychain operations.
protocol FuseKeychainStore {
    /// Search for Keychain items matching the specified query
    /// - Parameters:
    ///   - query: The search query dictionary
    ///   - result: Pointer to store the search result
    /// - Returns: OSStatus indicating the operation result
    @discardableResult
    func copyMatching(_ query: CFDictionary, result: UnsafeMutablePointer<AnyObject?>?) -> OSStatus
    
    /// Add a new item to the Keychain
    /// - Parameter query: The item attributes and data to add
    /// - Returns: OSStatus indicating the operation result
    @discardableResult
    func addItem(_ query: CFDictionary) -> OSStatus
    
    /// Update an existing Keychain item
    /// - Parameters:
    ///   - query: The search query to find the item to update
    ///   - attributes: The new attributes to apply
    /// - Returns: OSStatus indicating the operation result
    @discardableResult
    func updateItem(_ query: CFDictionary, attributes: CFDictionary) -> OSStatus
    
    /// Delete a Keychain item
    /// - Parameter query: The search query to find the item to delete
    /// - Returns: OSStatus indicating the operation result
    @discardableResult
    func deleteItem(_ query: CFDictionary) -> OSStatus
}

/// Default implementation of FuseKeychainStore using Security framework
/// 
/// This structure provides the standard implementation that directly calls
/// the Security framework's SecItem functions for actual Keychain operations.
struct FuseSecItemKeychainStore: FuseKeychainStore {
    func copyMatching(_ query: CFDictionary, result: UnsafeMutablePointer<AnyObject?>?) -> OSStatus {
        SecItemCopyMatching(query, result)
    }
    func addItem(_ query: CFDictionary) -> OSStatus {
        SecItemAdd(query, nil)
    }
    func updateItem(_ query: CFDictionary, attributes: CFDictionary) -> OSStatus {
        SecItemUpdate(query, attributes)
    }
    func deleteItem(_ query: CFDictionary) -> OSStatus {
        SecItemDelete(query)
    }
}
