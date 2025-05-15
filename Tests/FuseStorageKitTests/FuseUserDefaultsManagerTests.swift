//
//  FuseUserDefaultsManagerTests.swift
//  FuseStorageKit
//
//  Created by jimmy on 2025/1/4.
//

import XCTest
@testable import FuseStorageKit
import Foundation

final class FuseUserDefaultsManagerTests: XCTestCase {
    
    var manager: FuseUserDefaultsManager!
    var customSuiteManager: FuseUserDefaultsManager!
    let testSuiteName = "com.fuseStorageKit.tests"
    let testKey = "test_key"
    
    override func setUp() {
        super.setUp()
        
        // Initialize with standard UserDefaults
        manager = FuseUserDefaultsManager()
        
        // Initialize with custom suite for isolated testing
        customSuiteManager = FuseUserDefaultsManager(suiteName: testSuiteName)
        
        // Clean up any existing test data
        cleanup()
    }
    
    override func tearDown() {
        cleanup()
        manager = nil
        customSuiteManager = nil
        super.tearDown()
    }
    
    private func cleanup() {
        // Remove test data from both managers
        let keys = ["test_key", "string_key", "int_key", "bool_key", "double_key", 
                   "float_key", "data_key", "url_key", "date_key", "custom_key", 
                   "array_key", "dict_key", "complex_key"]
        
        for key in keys {
            manager.removeValue(forKey: key)
            customSuiteManager.removeValue(forKey: key)
        }
    }
    
    // MARK: - Initialization Tests
    
    func testDefaultInitialization() {
        let defaultManager = FuseUserDefaultsManager()
        XCTAssertNotNil(defaultManager)
    }
    
    func testCustomSuiteInitialization() {
        let suiteName = "com.test.customSuite"
        let customManager = FuseUserDefaultsManager(suiteName: suiteName)
        XCTAssertNotNil(customManager)
    }
    
    func testNilSuiteInitialization() {
        let nilSuiteManager = FuseUserDefaultsManager(suiteName: nil)
        XCTAssertNotNil(nilSuiteManager)
    }
    
    // MARK: - String Tests
    
    func testStringSetAndGet() throws {
        let testValue = "Hello, World!"
        let key = "string_key"
        
        try manager.set(testValue, forKey: key)
        let retrievedValue: String? = manager.get(forKey: key)
        
        XCTAssertEqual(retrievedValue, testValue)
        XCTAssertTrue(manager.containsValue(forKey: key))
    }
    
    func testEmptyStringSetAndGet() throws {
        let testValue = ""
        let key = "empty_string_key"
        
        try manager.set(testValue, forKey: key)
        let retrievedValue: String? = manager.get(forKey: key)
        
        XCTAssertEqual(retrievedValue, testValue)
    }
    
    func testUnicodeStringSetAndGet() throws {
        let testValue = "🚀 測試 Тест 🎉"
        let key = "unicode_string_key"
        
        try manager.set(testValue, forKey: key)
        let retrievedValue: String? = manager.get(forKey: key)
        
        XCTAssertEqual(retrievedValue, testValue)
    }
    
    // MARK: - Integer Tests
    
    func testIntSetAndGet() throws {
        let testValue = 42
        let key = "int_key"
        
        try manager.set(testValue, forKey: key)
        let retrievedValue: Int? = manager.get(forKey: key)
        
        XCTAssertEqual(retrievedValue, testValue)
        XCTAssertTrue(manager.containsValue(forKey: key))
    }
    
    func testZeroIntSetAndGet() throws {
        let testValue = 0
        let key = "zero_int_key"
        
        try manager.set(testValue, forKey: key)
        let retrievedValue: Int? = manager.get(forKey: key)
        
        XCTAssertEqual(retrievedValue, testValue)
        XCTAssertTrue(manager.containsValue(forKey: key))
    }
    
    func testNegativeIntSetAndGet() throws {
        let testValue = -123
        let key = "negative_int_key"
        
        try manager.set(testValue, forKey: key)
        let retrievedValue: Int? = manager.get(forKey: key)
        
        XCTAssertEqual(retrievedValue, testValue)
    }
    
    func testLargeIntSetAndGet() throws {
        let testValue = Int.max
        let key = "large_int_key"
        
        try manager.set(testValue, forKey: key)
        let retrievedValue: Int? = manager.get(forKey: key)
        
        XCTAssertEqual(retrievedValue, testValue)
    }
    
    // MARK: - Boolean Tests
    
    func testTrueBoolSetAndGet() throws {
        let testValue = true
        let key = "true_bool_key"
        
        try manager.set(testValue, forKey: key)
        let retrievedValue: Bool? = manager.get(forKey: key)
        
        XCTAssertEqual(retrievedValue, testValue)
        XCTAssertTrue(manager.containsValue(forKey: key))
    }
    
    func testFalseBoolSetAndGet() throws {
        let testValue = false
        let key = "false_bool_key"
        
        try manager.set(testValue, forKey: key)
        let retrievedValue: Bool? = manager.get(forKey: key)
        
        XCTAssertEqual(retrievedValue, testValue)
        XCTAssertTrue(manager.containsValue(forKey: key))
    }
    
    // MARK: - Double Tests
    
    func testDoubleSetAndGet() throws {
        let testValue = 3.14159
        let key = "double_key"
        
        try manager.set(testValue, forKey: key)
        let retrievedValue: Double? = manager.get(forKey: key)
        
        XCTAssertNotNil(retrievedValue)
        XCTAssertEqual(retrievedValue!, testValue, accuracy: 0.00001)
        XCTAssertTrue(manager.containsValue(forKey: key))
    }
    
    func testZeroDoubleSetAndGet() throws {
        let testValue = 0.0
        let key = "zero_double_key"
        
        try manager.set(testValue, forKey: key)
        let retrievedValue: Double? = manager.get(forKey: key)
        
        XCTAssertNotNil(retrievedValue)
        XCTAssertEqual(retrievedValue!, testValue)
    }
    
    func testNegativeDoubleSetAndGet() throws {
        let testValue = -123.456
        let key = "negative_double_key"
        
        try manager.set(testValue, forKey: key)
        let retrievedValue: Double? = manager.get(forKey: key)
        
        XCTAssertNotNil(retrievedValue)
        XCTAssertEqual(retrievedValue!, testValue, accuracy: 0.001)
    }
    
    // MARK: - Float Tests
    
    func testFloatSetAndGet() throws {
        let testValue: Float = 2.71828
        let key = "float_key"
        
        try manager.set(testValue, forKey: key)
        let retrievedValue: Float? = manager.get(forKey: key)
        
        XCTAssertNotNil(retrievedValue)
        XCTAssertEqual(retrievedValue!, testValue, accuracy: 0.00001)
        XCTAssertTrue(manager.containsValue(forKey: key))
    }
    
    // MARK: - Data Tests
    
    func testDataSetAndGet() throws {
        let testValue = "Test data".data(using: .utf8)!
        let key = "data_key"
        
        try manager.set(testValue, forKey: key)
        let retrievedValue: Data? = manager.get(forKey: key)
        
        XCTAssertEqual(retrievedValue, testValue)
        XCTAssertTrue(manager.containsValue(forKey: key))
    }
    
    func testEmptyDataSetAndGet() throws {
        let testValue = Data()
        let key = "empty_data_key"
        
        try manager.set(testValue, forKey: key)
        let retrievedValue: Data? = manager.get(forKey: key)
        
        XCTAssertEqual(retrievedValue, testValue)
    }
    
    // MARK: - URL Tests
    
    func testURLSetAndGet() throws {
        let testValue = URL(string: "https://www.example.com")!
        let key = "url_key"
        
        try manager.set(testValue, forKey: key)
        let retrievedValue: URL? = manager.get(forKey: key)
        
        XCTAssertEqual(retrievedValue, testValue)
        XCTAssertTrue(manager.containsValue(forKey: key))
    }
    
    func testFileURLSetAndGet() throws {
        let testValue = URL(fileURLWithPath: "/tmp/test.txt")
        let key = "file_url_key"
        
        try manager.set(testValue, forKey: key)
        let retrievedValue: URL? = manager.get(forKey: key)
        
        XCTAssertEqual(retrievedValue, testValue)
    }
    
    // MARK: - Date Tests
    
    func testDateSetAndGet() throws {
        let testValue = Date(timeIntervalSince1970: 1609459200) // 2021-01-01 00:00:00 UTC
        let key = "date_key"
        
        try manager.set(testValue, forKey: key)
        let retrievedValue: Date? = manager.get(forKey: key)
        
        XCTAssertNotNil(retrievedValue)
        XCTAssertEqual(retrievedValue!.timeIntervalSince1970, 
                       testValue.timeIntervalSince1970, 
                       accuracy: 0.001)
        XCTAssertTrue(manager.containsValue(forKey: key))
    }
    
    func testCurrentDateSetAndGet() throws {
        let testValue = Date()
        let key = "current_date_key"
        
        try manager.set(testValue, forKey: key)
        let retrievedValue: Date? = manager.get(forKey: key)
        
        XCTAssertNotNil(retrievedValue)
        XCTAssertEqual(retrievedValue!.timeIntervalSince1970, 
                       testValue.timeIntervalSince1970, 
                       accuracy: 0.001)
    }
    
    // MARK: - Custom Codable Type Tests
    
    struct TestPerson: Codable, Equatable {
        let id: Int
        let name: String
        let email: String
        let isActive: Bool
    }
    
    func testCustomCodableTypeSetAndGet() throws {
        let testValue = TestPerson(id: 1, name: "John Doe", email: "john@example.com", isActive: true)
        let key = "custom_key"
        
        try manager.set(testValue, forKey: key)
        let retrievedValue: TestPerson? = manager.get(forKey: key)
        
        XCTAssertEqual(retrievedValue, testValue)
        XCTAssertTrue(manager.containsValue(forKey: key))
    }
    
    enum TestStatus: String, Codable {
        case active = "active"
        case inactive = "inactive"
        case pending = "pending"
    }
    
    func testEnumSetAndGet() throws {
        let testValue = TestStatus.active
        let key = "enum_key"
        
        try manager.set(testValue, forKey: key)
        let retrievedValue: TestStatus? = manager.get(forKey: key)
        
        XCTAssertEqual(retrievedValue, testValue)
    }
    
    // MARK: - Collection Tests
    
    func testArraySetAndGet() throws {
        let testValue = ["apple", "banana", "cherry"]
        let key = "array_key"
        
        try manager.set(testValue, forKey: key)
        let retrievedValue: [String]? = manager.get(forKey: key)
        
        XCTAssertEqual(retrievedValue, testValue)
        XCTAssertTrue(manager.containsValue(forKey: key))
    }
    
    func testDictionarySetAndGet() throws {
        let testValue = ["name": "John", "age": "30", "city": "New York"]
        let key = "dict_key"
        
        try manager.set(testValue, forKey: key)
        let retrievedValue: [String: String]? = manager.get(forKey: key)
        
        XCTAssertEqual(retrievedValue, testValue)
    }
    
    func testComplexObjectSetAndGet() throws {
        struct ComplexObject: Codable, Equatable {
            let users: [TestPerson]
            let metadata: [String: String]
            let timestamp: Date
            let isValid: Bool
        }
        
        let testValue = ComplexObject(
            users: [
                TestPerson(id: 1, name: "Alice", email: "alice@example.com", isActive: true),
                TestPerson(id: 2, name: "Bob", email: "bob@example.com", isActive: false)
            ],
            metadata: ["version": "1.0", "source": "test"],
            timestamp: Date(timeIntervalSince1970: 1609459200),
            isValid: true
        )
        let key = "complex_key"
        
        try manager.set(testValue, forKey: key)
        let retrievedValue: ComplexObject? = manager.get(forKey: key)
        
        XCTAssertEqual(retrievedValue, testValue)
    }
    
    // MARK: - Removal and Existence Tests
    
    func testRemoveValue() throws {
        let testValue = "Test value"
        let key = "remove_test_key"
        
        // Set a value
        try manager.set(testValue, forKey: key)
        XCTAssertTrue(manager.containsValue(forKey: key))
        
        // Remove the value
        manager.removeValue(forKey: key)
        XCTAssertFalse(manager.containsValue(forKey: key))
        
        // Verify it returns nil
        let retrievedValue: String? = manager.get(forKey: key)
        XCTAssertNil(retrievedValue)
    }
    
    func testContainsValueForNonExistentKey() {
        let key = "non_existent_key"
        XCTAssertFalse(manager.containsValue(forKey: key))
    }
    
    func testGetNonExistentKey() {
        let key = "non_existent_key"
        let retrievedValue: String? = manager.get(forKey: key)
        XCTAssertNil(retrievedValue)
    }
    
    func testRemoveNonExistentKey() {
        let key = "non_existent_key"
        // Should not throw or crash
        XCTAssertNoThrow(manager.removeValue(forKey: key))
    }
    
    // MARK: - Suite Isolation Tests
    
    func testSuiteIsolation() throws {
        let key = "isolation_test_key"
        let value1 = "Standard suite value"
        let value2 = "Custom suite value"
        
        // Set different values in different suites
        try manager.set(value1, forKey: key)
        try customSuiteManager.set(value2, forKey: key)
        
        // Verify they don't interfere with each other
        let retrievedValue1: String? = manager.get(forKey: key)
        let retrievedValue2: String? = customSuiteManager.get(forKey: key)
        
        XCTAssertEqual(retrievedValue1, value1)
        XCTAssertEqual(retrievedValue2, value2)
        XCTAssertNotEqual(retrievedValue1, retrievedValue2)
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
        
        // The string retrieval should now return nil
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
    
    // MARK: - Performance Tests
    
    func testPerformanceBulkOperations() {
        measure {
            for i in 0..<100 {
                let key = "perf_key_\(i)"
                let value = "Performance test value \(i)"
                try? manager.set(value, forKey: key)
                let _: String? = manager.get(forKey: key)
            }
        }
    }
} 