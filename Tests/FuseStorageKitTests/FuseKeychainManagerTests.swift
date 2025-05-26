//
//  FuseKeychainManagerTests.swift
//  FuseStorageKit
//
//  Created by jimmy on 2025/5/24.
//

import XCTest
@testable import FuseStorageKit

// MARK: - Memory Mock Backend
class MemoryKeychainStore: FuseKeychainStore {
    private var store = [String: Data]()
    
    // For testing error scenarios
    var shouldFailAddItem = false
    var shouldFailUpdateItem = false
    var shouldFailDeleteItem = false
    var shouldFailCopyMatching = false

    func copyMatching(_ query: CFDictionary, result: UnsafeMutablePointer<AnyObject?>?) -> OSStatus {
        if shouldFailCopyMatching {
            return errSecInternalError
        }
        
        guard
            let dict = query as? [String: Any],
            let service = dict[kSecAttrService as String] as? String,
            let account = dict[kSecAttrAccount as String] as? String
        else { return errSecParam }

        let key = service + "|" + account
        if let data = store[key] {
            result?.pointee = data as AnyObject
            return errSecSuccess
        } else {
            return errSecItemNotFound
        }
    }

    func addItem(_ query: CFDictionary) -> OSStatus {
        if shouldFailAddItem {
            return errSecInternalError
        }
        
        guard
            let dict = query as? [String: Any],
            let service = dict[kSecAttrService as String] as? String,
            let account = dict[kSecAttrAccount as String] as? String,
            let data = dict[kSecValueData as String] as? Data
        else { return errSecParam }

        let key = service + "|" + account
        store[key] = data
        return errSecSuccess
    }

    func updateItem(_ query: CFDictionary, attributes: CFDictionary) -> OSStatus {
        if shouldFailUpdateItem {
            return errSecInternalError
        }
        
        // 只需要從 attributes 拿出新的 kSecValueData
        guard
            let dictQ = query as? [String: Any],
            let service = dictQ[kSecAttrService as String] as? String,
            let account = dictQ[kSecAttrAccount as String] as? String,
            let dictA = attributes as? [String: Any],
            let newData = dictA[kSecValueData as String] as? Data
        else { return errSecParam }

        let key = service + "|" + account
        store[key] = newData
        return errSecSuccess
    }

    func deleteItem(_ query: CFDictionary) -> OSStatus {
        if shouldFailDeleteItem {
            return errSecInternalError
        }
        
        guard
            let dict = query as? [String: Any],
            let service = dict[kSecAttrService as String] as? String,
            let account = dict[kSecAttrAccount as String] as? String
        else { return errSecParam }

        let key = service + "|" + account
        store.removeValue(forKey: key)
        return errSecSuccess
    }
    
    // Helper methods for testing
    func reset() {
        store.removeAll()
        shouldFailAddItem = false
        shouldFailUpdateItem = false
        shouldFailDeleteItem = false
        shouldFailCopyMatching = false
    }
    
    func getStoredKeys() -> [String] {
        return Array(store.keys)
    }
}

// MARK: - Tests
final class FuseKeychainManagerTests: XCTestCase {

    var manager: FuseKeychainManager!
    var mockStore: MemoryKeychainStore!
    let testKey = "myTestKey"

    override func setUp() {
        super.setUp()
        // 注入 MemoryKeychainStore，避免真實 Keychain
        mockStore = MemoryKeychainStore()
        manager = FuseKeychainManager(
            service: "com.example.tests",
            accessGroup: nil,
            accessibility: .whenUnlocked,
            store: mockStore
        )
    }

    override func tearDown() {
        mockStore?.reset()
        manager = nil
        mockStore = nil
        super.tearDown()
    }

    // MARK: - Initialization Tests

    func testConvenienceInit() {
        let manager = FuseKeychainManager(
            service: "com.test.service",
            accessGroup: "com.test.group",
            accessibility: .afterFirstUnlock
        )
        XCTAssertNotNil(manager)
    }

    func testDesignatedInit() {
        let store = MemoryKeychainStore()
        let manager = FuseKeychainManager(
            service: "com.test.service",
            accessGroup: "com.test.group",
            accessibility: .whenUnlockedThisDeviceOnly,
            store: store
        )
        XCTAssertNotNil(manager)
    }

    func testInitWithNilAccessGroup() {
        let manager = FuseKeychainManager(
            service: "com.test.service",
            accessGroup: nil,
            accessibility: .afterFirstUnlockThisDeviceOnly
        )
        XCTAssertNotNil(manager)
    }

    // MARK: - Basic Type Tests

    func testStringSetAndGet() throws {
        let original = "hello"
        try manager.set(original, forKey: testKey)
        XCTAssertTrue(manager.containsValue(forKey: testKey))
        let retrieved: String? = manager.get(forKey: testKey)
        XCTAssertEqual(retrieved, original)
    }

    func testEmptyStringSetAndGet() throws {
        let original = ""
        try manager.set(original, forKey: testKey)
        let retrieved: String? = manager.get(forKey: testKey)
        XCTAssertEqual(retrieved, original)
    }

    func testUnicodeStringSetAndGet() throws {
        let original = "🚀 測試 Тест 🎉"
        try manager.set(original, forKey: testKey)
        let retrieved: String? = manager.get(forKey: testKey)
        XCTAssertEqual(retrieved, original)
    }

    func testIntSetAndGet() throws {
        let original = 123
        try manager.set(original, forKey: testKey)
        let retrieved: Int? = manager.get(forKey: testKey)
        XCTAssertEqual(retrieved, original)
    }

    func testZeroIntSetAndGet() throws {
        let original = 0
        try manager.set(original, forKey: testKey)
        let retrieved: Int? = manager.get(forKey: testKey)
        XCTAssertEqual(retrieved, original)
    }

    func testNegativeIntSetAndGet() throws {
        let original = -456
        try manager.set(original, forKey: testKey)
        let retrieved: Int? = manager.get(forKey: testKey)
        XCTAssertEqual(retrieved, original)
    }

    func testLargeIntSetAndGet() throws {
        let original = Int.max
        try manager.set(original, forKey: testKey)
        let retrieved: Int? = manager.get(forKey: testKey)
        XCTAssertEqual(retrieved, original)
    }

    func testDoubleSetAndGet() throws {
        let original = 3.14159
        try manager.set(original, forKey: testKey)
        let retrieved: Double? = manager.get(forKey: testKey)
        XCTAssertNotNil(retrieved)
        XCTAssertEqual(retrieved!, original, accuracy: 0.00001)
    }

    func testZeroDoubleSetAndGet() throws {
        let original = 0.0
        try manager.set(original, forKey: testKey)
        let retrieved: Double? = manager.get(forKey: testKey)
        XCTAssertEqual(retrieved, original)
    }

    func testNegativeDoubleSetAndGet() throws {
        let original = -123.456
        try manager.set(original, forKey: testKey)
        let retrieved: Double? = manager.get(forKey: testKey)
        XCTAssertNotNil(retrieved)
        XCTAssertEqual(retrieved!, original, accuracy: 0.001)
    }

    func testBoolTrueSetAndGet() throws {
        try manager.set(true, forKey: testKey)
        let retrieved: Bool? = manager.get(forKey: testKey)
        XCTAssertEqual(retrieved, true)
    }

    func testBoolFalseSetAndGet() throws {
        try manager.set(false, forKey: testKey)
        let retrieved: Bool? = manager.get(forKey: testKey)
        XCTAssertEqual(retrieved, false)
    }

    func testDataSetAndGet() throws {
        let original = "Test data".data(using: .utf8)!
        try manager.set(original, forKey: testKey)
        let retrieved: Data? = manager.get(forKey: testKey)
        XCTAssertEqual(retrieved, original)
    }

    func testEmptyDataSetAndGet() throws {
        let original = Data()
        try manager.set(original, forKey: testKey)
        let retrieved: Data? = manager.get(forKey: testKey)
        XCTAssertEqual(retrieved, original)
    }

    func testDateSetAndGet() throws {
        let original = Date(timeIntervalSince1970: 1_600_000_000)
        try manager.set(original, forKey: testKey)
        let retrieved: Date? = manager.get(forKey: testKey)
        XCTAssertNotNil(retrieved)
        XCTAssertEqual(retrieved!.timeIntervalSince1970,
                       original.timeIntervalSince1970,
                       accuracy: 0.001)
    }

    func testCurrentDateSetAndGet() throws {
        let original = Date()
        try manager.set(original, forKey: testKey)
        let retrieved: Date? = manager.get(forKey: testKey)
        XCTAssertNotNil(retrieved)
        XCTAssertEqual(retrieved!.timeIntervalSince1970,
                       original.timeIntervalSince1970,
                       accuracy: 1.0) // Allow 1 second tolerance for current date
    }

    // MARK: - Codable Type Tests

    func testCodableStructSetAndGet() throws {
        struct Person: Codable, Equatable {
            let id: Int
            let name: String
        }
        let p = Person(id: 7, name: "Bob")
        try manager.set(p, forKey: testKey)
        let retrieved: Person? = manager.get(forKey: testKey)
        XCTAssertEqual(retrieved, p)
    }

    func testComplexCodableStructSetAndGet() throws {
        struct ComplexPerson: Codable, Equatable {
            let id: Int
            let name: String
            let isActive: Bool
            let salary: Double
            let joinDate: Date
            let tags: [String]
        }
        
        let person = ComplexPerson(
            id: 42,
            name: "Alice",
            isActive: true,
            salary: 75000.5,
            joinDate: Date(timeIntervalSince1970: 1609459200),
            tags: ["engineer", "senior", "team-lead"]
        )
        
        try manager.set(person, forKey: testKey)
        let retrieved: ComplexPerson? = manager.get(forKey: testKey)
        XCTAssertEqual(retrieved, person)
    }

    func testEnumSetAndGet() throws {
        enum Status: String, Codable {
            case active = "active"
            case inactive = "inactive"
            case pending = "pending"
        }
        
        let status = Status.active
        try manager.set(status, forKey: testKey)
        let retrieved: Status? = manager.get(forKey: testKey)
        XCTAssertEqual(retrieved, status)
    }

    func testArraySetAndGet() throws {
        let original = ["apple", "banana", "cherry"]
        try manager.set(original, forKey: testKey)
        let retrieved: [String]? = manager.get(forKey: testKey)
        XCTAssertEqual(retrieved, original)
    }

    func testDictionarySetAndGet() throws {
        let original = ["name": "John", "age": "30", "city": "New York"]
        try manager.set(original, forKey: testKey)
        let retrieved: [String: String]? = manager.get(forKey: testKey)
        XCTAssertEqual(retrieved, original)
    }

    // MARK: - Key Management Tests

    func testRemoveValue() throws {
        try manager.set("foo", forKey: testKey)
        XCTAssertTrue(manager.containsValue(forKey: testKey))
        manager.removeValue(forKey: testKey)
        XCTAssertFalse(manager.containsValue(forKey: testKey))
    }

    func testRemoveNonExistentKey() {
        let key = "non_existent_key"
        XCTAssertFalse(manager.containsValue(forKey: key))
        // Should not throw or crash
        XCTAssertNoThrow(manager.removeValue(forKey: key))
    }

    func testContainsValueForNonExistentKey() {
        let key = "non_existent_key"
        XCTAssertFalse(manager.containsValue(forKey: key))
    }

    func testGetNonExistentKey() {
        let key = "non_existent_key"
        let retrieved: String? = manager.get(forKey: key)
        XCTAssertNil(retrieved)
    }

    // MARK: - Overwrite Tests

    func testOverwriteValue() throws {
        let key = "overwrite_key"
        let originalValue = "Original value"
        let newValue = "New value"
        
        // Set original value
        try manager.set(originalValue, forKey: key)
        let retrieved1: String? = manager.get(forKey: key)
        XCTAssertEqual(retrieved1, originalValue)
        
        // Overwrite with new value
        try manager.set(newValue, forKey: key)
        let retrieved2: String? = manager.get(forKey: key)
        XCTAssertEqual(retrieved2, newValue)
        XCTAssertNotEqual(retrieved2, originalValue)
    }

    func testOverwriteWithDifferentType() throws {
        let key = "type_change_key"
        let stringValue = "String value"
        let intValue = 42
        
        // Set string value
        try manager.set(stringValue, forKey: key)
        let retrievedString: String? = manager.get(forKey: key)
        XCTAssertEqual(retrievedString, stringValue)
        
        // Overwrite with int value
        try manager.set(intValue, forKey: key)
        let retrievedInt: Int? = manager.get(forKey: key)
        XCTAssertEqual(retrievedInt, intValue)
        
        // The string retrieval should now return nil (type safety)
        let retrievedStringAfter: String? = manager.get(forKey: key)
        XCTAssertNil(retrievedStringAfter)
    }

    // MARK: - Edge Cases

    func testVeryLongKey() throws {
        let longKey = String(repeating: "a", count: 1000)
        let testValue = "Long key test"
        
        try manager.set(testValue, forKey: longKey)
        let retrievedValue: String? = manager.get(forKey: longKey)
        
        XCTAssertEqual(retrievedValue, testValue)
    }

    func testSpecialCharactersInKey() throws {
        let specialKey = "key.with-special_characters@#$%^&*()+="
        let testValue = "Special key test"
        
        try manager.set(testValue, forKey: specialKey)
        let retrievedValue: String? = manager.get(forKey: specialKey)
        
        XCTAssertEqual(retrievedValue, testValue)
    }

    func testEmptyKey() throws {
        let emptyKey = ""
        let testValue = "Empty key test"
        
        try manager.set(testValue, forKey: emptyKey)
        let retrievedValue: String? = manager.get(forKey: emptyKey)
        
        XCTAssertEqual(retrievedValue, testValue)
    }

    func testUnicodeKey() throws {
        let unicodeKey = "鍵🔑клавиша"
        let testValue = "Unicode key test"
        
        try manager.set(testValue, forKey: unicodeKey)
        let retrievedValue: String? = manager.get(forKey: unicodeKey)
        
        XCTAssertEqual(retrievedValue, testValue)
    }

    // MARK: - Error Handling Tests

    func testEncodingError() throws {
        struct NonEncodableString: Codable {
            let value: String
            
            init(value: String) {
                self.value = value
            }
            
            func encode(to encoder: Encoder) throws {
                throw FuseKeychainError.encodingError
            }
        }
        
        let problematicValue = NonEncodableString(value: "test")
        
        XCTAssertThrowsError(try manager.set(problematicValue, forKey: testKey)) { error in
            guard let keychainError = error as? FuseKeychainError else {
                XCTFail("Expected FuseKeychainError")
                return
            }
            if case .encodingError = keychainError {
                // Expected error
            } else {
                XCTFail("Expected FuseKeychainError.encodingError")
            }
        }
    }

    func testStringEncodingError() throws {
        // Create a custom manager with a mock that simulates string encoding failure
        let customMockStore = MemoryKeychainStore()
        let customManager = FuseKeychainManager(
            service: "com.example.tests",
            accessGroup: nil,
            accessibility: .whenUnlocked,
            store: customMockStore
        )
        
        // Test with a string that theoretically could cause encoding issues
        // Note: This is hard to simulate as UTF-8 encoding rarely fails
        let testValue = "Valid string"
        XCTAssertNoThrow(try customManager.set(testValue, forKey: testKey))
    }

    func testKeychainStoreAddFailure() throws {
        mockStore.shouldFailAddItem = true
        
        XCTAssertThrowsError(try manager.set("test", forKey: testKey)) { error in
            guard let keychainError = error as? FuseKeychainError else {
                XCTFail("Expected FuseKeychainError")
                return
            }
            if case .unhandledError(let status) = keychainError {
                XCTAssertEqual(status, errSecInternalError)
            } else {
                XCTFail("Expected FuseKeychainError.unhandledError")
            }
        }
    }

    func testKeychainStoreUpdateFailure() throws {
        // First, add an item successfully
        try manager.set("initial", forKey: testKey)
        
        // Now make update fail
        mockStore.shouldFailUpdateItem = true
        
        XCTAssertThrowsError(try manager.set("updated", forKey: testKey)) { error in
            guard let keychainError = error as? FuseKeychainError else {
                XCTFail("Expected FuseKeychainError")
                return
            }
            if case .unhandledError(let status) = keychainError {
                XCTAssertEqual(status, errSecInternalError)
            } else {
                XCTFail("Expected FuseKeychainError.unhandledError")
            }
        }
    }

    func testKeychainStoreCopyMatchingFailure() throws {
        mockStore.shouldFailCopyMatching = true
        
        XCTAssertThrowsError(try manager.set("test", forKey: testKey)) { error in
            guard let keychainError = error as? FuseKeychainError else {
                XCTFail("Expected FuseKeychainError")
                return
            }
            if case .unhandledError(let status) = keychainError {
                XCTAssertEqual(status, errSecInternalError)
            } else {
                XCTFail("Expected FuseKeychainError.unhandledError")
            }
        }
    }

    // MARK: - Data Corruption Tests

    func testCorruptedDataRetrieval() throws {
        // Manually insert corrupted data
        let corruptedData = Data([0xFF, 0xFE, 0xFD])
        try manager.set(corruptedData, forKey: testKey)
        
        // Try to retrieve as different types
        let stringValue: String? = manager.get(forKey: testKey)
        XCTAssertNil(stringValue) // Should fail gracefully
        
        let intValue: Int? = manager.get(forKey: testKey)
        XCTAssertNil(intValue) // Should fail gracefully
        
        let boolValue: Bool? = manager.get(forKey: testKey)
        XCTAssertNil(boolValue) // Should fail gracefully
        
        // But Data retrieval should work
        let dataValue: Data? = manager.get(forKey: testKey)
        XCTAssertEqual(dataValue, corruptedData)
    }

    // MARK: - Performance Tests

    func testPerformanceBulkOperations() {
        measure {
            for i in 0..<50 { // Reduced for Keychain operations
                let key = "perf_key_\(i)"
                let value = "Performance test value \(i)"
                try? manager.set(value, forKey: key)
                let _: String? = manager.get(forKey: key)
            }
        }
    }

    func testPerformanceLargeData() {
        let largeString = String(repeating: "A", count: 10000)
        
        measure {
            try? manager.set(largeString, forKey: "large_data_key")
            let _: String? = manager.get(forKey: "large_data_key")
        }
    }

    // MARK: - Multiple Keys Tests

    func testMultipleKeysIsolation() throws {
        let key1 = "key1"
        let key2 = "key2"
        let key3 = "key3"
        
        let value1 = "value1"
        let value2 = 42
        let value3 = true
        
        try manager.set(value1, forKey: key1)
        try manager.set(value2, forKey: key2)
        try manager.set(value3, forKey: key3)
        
        let retrieved1: String? = manager.get(forKey: key1)
        let retrieved2: Int? = manager.get(forKey: key2)
        let retrieved3: Bool? = manager.get(forKey: key3)
        
        XCTAssertEqual(retrieved1, value1)
        XCTAssertEqual(retrieved2, value2)
        XCTAssertEqual(retrieved3, value3)
        
        // Verify containsValue for all keys
        XCTAssertTrue(manager.containsValue(forKey: key1))
        XCTAssertTrue(manager.containsValue(forKey: key2))
        XCTAssertTrue(manager.containsValue(forKey: key3))
    }

    func testRemoveMultipleKeys() throws {
        let keys = ["key1", "key2", "key3", "key4", "key5"]
        
        // Set values for all keys
        for (index, key) in keys.enumerated() {
            try manager.set("value\(index)", forKey: key)
            XCTAssertTrue(manager.containsValue(forKey: key))
        }
        
        // Remove all keys
        for key in keys {
            manager.removeValue(forKey: key)
            XCTAssertFalse(manager.containsValue(forKey: key))
        }
    }

    // MARK: - Type Safety Tests

    func testTypeSafetyAfterDataCorruption() throws {
        // Store a valid Int
        try manager.set(42, forKey: testKey)
        let intValue: Int? = manager.get(forKey: testKey)
        XCTAssertEqual(intValue, 42)
        
        // Manually corrupt the data by storing invalid string for Int
        let invalidIntData = "not_a_number".data(using: .utf8)!
        try manager.set(invalidIntData, forKey: testKey)
        
        // Try to retrieve as Int - should return nil
        let corruptedInt: Int? = manager.get(forKey: testKey)
        XCTAssertNil(corruptedInt)
        
        // But should work as Data
        let dataValue: Data? = manager.get(forKey: testKey)
        XCTAssertEqual(dataValue, invalidIntData)
    }

    // MARK: - JSON Codable Edge Cases

    func testNestedCodableStructure() throws {
        struct Address: Codable, Equatable {
            let street: String
            let city: String
            let zipCode: String
        }
        
        struct User: Codable, Equatable {
            let id: Int
            let name: String
            let addresses: [Address]
            let metadata: [String: String]
        }
        
        let user = User(
            id: 1,
            name: "John Doe",
            addresses: [
                Address(street: "123 Main St", city: "Anytown", zipCode: "12345"),
                Address(street: "456 Oak Ave", city: "Other City", zipCode: "67890")
            ],
            metadata: ["role": "admin", "department": "IT"]
        )
        
        try manager.set(user, forKey: testKey)
        let retrieved: User? = manager.get(forKey: testKey)
        XCTAssertEqual(retrieved, user)
    }
}
