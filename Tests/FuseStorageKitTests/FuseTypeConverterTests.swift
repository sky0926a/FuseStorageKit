import XCTest
@testable import FuseStorageCore

class FuseTypeConverterTests: XCTestCase {
    
    // MARK: - Type Inference Tests
    
    func testArrayTypeInference() throws {
        let stringArray = ["apple", "banana", "cherry"]
        let intArray = [1, 2, 3, 4]
        let emptyArray: [String] = []
        
        // Test basic array inference
        let (stringArrayType, stringArrayOptional) = FuseTypeConverter.inferColumnType(from: stringArray)
        XCTAssertEqual(stringArrayType, .text, "String array should infer as .text")
        XCTAssertFalse(stringArrayOptional, "Non-optional array should not be marked as optional")
        
        let (intArrayType, intArrayOptional) = FuseTypeConverter.inferColumnType(from: intArray)
        XCTAssertEqual(intArrayType, .text, "Int array should infer as .text")
        XCTAssertFalse(intArrayOptional, "Non-optional array should not be marked as optional")
        
        let (emptyArrayType, emptyArrayOptional) = FuseTypeConverter.inferColumnType(from: emptyArray)
        XCTAssertEqual(emptyArrayType, .text, "Empty array should infer as .text")
        XCTAssertFalse(emptyArrayOptional, "Non-optional array should not be marked as optional")
        
        // Test optional array inference
        let optionalArray: [String]? = ["optional"]
        let (optionalType, optionalFlag) = FuseTypeConverter.inferColumnType(from: optionalArray as Any)
        XCTAssertEqual(optionalType, .text, "Optional array should infer as .text")
        XCTAssertTrue(optionalFlag, "Optional array should be marked as optional")
    }
    
    func testDictionaryTypeInference() throws {
        let stringDict = ["key1": "value1", "key2": "value2"]
        let intDict = ["num1": 1, "num2": 2]
        let emptyDict: [String: String] = [:]
        
        // Test basic dictionary inference
        let (stringDictType, stringDictOptional) = FuseTypeConverter.inferColumnType(from: stringDict)
        XCTAssertEqual(stringDictType, .text, "String dictionary should infer as .text")
        XCTAssertFalse(stringDictOptional, "Non-optional dictionary should not be marked as optional")
        
        let (intDictType, intDictOptional) = FuseTypeConverter.inferColumnType(from: intDict)
        XCTAssertEqual(intDictType, .text, "Int dictionary should infer as .text")
        XCTAssertFalse(intDictOptional, "Non-optional dictionary should not be marked as optional")
        
        let (emptyDictType, emptyDictOptional) = FuseTypeConverter.inferColumnType(from: emptyDict)
        XCTAssertEqual(emptyDictType, .text, "Empty dictionary should infer as .text")
        XCTAssertFalse(emptyDictOptional, "Non-optional dictionary should not be marked as optional")
        
        // Test optional dictionary inference
        let optionalDict: [String: String]? = ["opt": "value"]
        let (optionalType, optionalFlag) = FuseTypeConverter.inferColumnType(from: optionalDict as Any)
        XCTAssertEqual(optionalType, .text, "Optional dictionary should infer as .text")
        XCTAssertTrue(optionalFlag, "Optional dictionary should be marked as optional")
    }
    
    func testNestedObjectTypeInference() throws {
        struct TestStruct: Codable {
            let name: String
            let value: Int
        }
        
        let testObject = TestStruct(name: "test", value: 42)
        let (objectType, objectOptional) = FuseTypeConverter.inferColumnType(from: testObject)
        
        XCTAssertEqual(objectType, .text, "Codable object should infer as .text")
        XCTAssertFalse(objectOptional, "Non-optional object should not be marked as optional")
        
        // Test optional object inference
        let optionalObject: TestStruct? = TestStruct(name: "optional", value: 99)
        let (optionalType, optionalFlag) = FuseTypeConverter.inferColumnType(from: optionalObject as Any)
        XCTAssertEqual(optionalType, .text, "Optional Codable object should infer as .text")
        XCTAssertTrue(optionalFlag, "Optional object should be marked as optional")
    }
    
    // MARK: - Swift to Database Conversion Tests
    
    func testSwiftToDatabaseArrayConversion() throws {
        let stringArray = ["apple", "banana", "cherry"]
        let intArray = [10, 20, 30]
        let emptyArray: [String] = []
        
        // Test string array conversion
        let stringResult = FuseTypeConverter.swiftToDatabaseValue(stringArray, columnType: .text, isOptional: false)
        XCTAssertTrue(stringResult is String, "Array should be converted to String")
        let stringJSON = stringResult as! String
        XCTAssertTrue(stringJSON.contains("apple"), "JSON should contain array elements")
        XCTAssertTrue(stringJSON.contains("banana"), "JSON should contain array elements")
        
        // Test int array conversion
        let intResult = FuseTypeConverter.swiftToDatabaseValue(intArray, columnType: .text, isOptional: false)
        XCTAssertTrue(intResult is String, "Array should be converted to String")
        let intJSON = intResult as! String
        XCTAssertTrue(intJSON.contains("10"), "JSON should contain array elements")
        XCTAssertTrue(intJSON.contains("20"), "JSON should contain array elements")
        
        // Test empty array conversion
        let emptyResult = FuseTypeConverter.swiftToDatabaseValue(emptyArray, columnType: .text, isOptional: false)
        XCTAssertEqual(emptyResult as? String, "[]", "Empty array should convert to empty JSON array")
    }
    
    func testSwiftToDatabaseDictionaryConversion() throws {
        let stringDict = ["name": "John", "city": "Taipei"]
        let intDict = ["width": 100, "height": 200]
        let emptyDict: [String: String] = [:]
        
        // Test string dictionary conversion
        let stringResult = FuseTypeConverter.swiftToDatabaseValue(stringDict, columnType: .text, isOptional: false)
        XCTAssertTrue(stringResult is String, "Dictionary should be converted to String")
        let stringJSON = stringResult as! String
        XCTAssertTrue(stringJSON.contains("John"), "JSON should contain dictionary values")
        XCTAssertTrue(stringJSON.contains("Taipei"), "JSON should contain dictionary values")
        
        // Test int dictionary conversion
        let intResult = FuseTypeConverter.swiftToDatabaseValue(intDict, columnType: .text, isOptional: false)
        XCTAssertTrue(intResult is String, "Dictionary should be converted to String")
        let intJSON = intResult as! String
        XCTAssertTrue(intJSON.contains("100"), "JSON should contain dictionary values")
        XCTAssertTrue(intJSON.contains("200"), "JSON should contain dictionary values")
        
        // Test empty dictionary conversion
        let emptyResult = FuseTypeConverter.swiftToDatabaseValue(emptyDict, columnType: .text, isOptional: false)
        XCTAssertEqual(emptyResult as? String, "{}", "Empty dictionary should convert to empty JSON object")
    }
    
    func testSwiftToDatabaseNestedObjectConversion() throws {
        struct Address: Codable {
            let street: String
            let city: String
            let zipCode: String
        }
        
        let address = Address(street: "123 Main St", city: "Taipei", zipCode: "10001")
        
        // Test nested object conversion
        let result = FuseTypeConverter.swiftToDatabaseValue(address, columnType: .text, isOptional: false)
        XCTAssertTrue(result is String, "Codable object should be converted to String")
        let jsonString = result as! String
        XCTAssertTrue(jsonString.contains("123 Main St"), "JSON should contain object properties")
        XCTAssertTrue(jsonString.contains("Taipei"), "JSON should contain object properties")
        XCTAssertTrue(jsonString.contains("10001"), "JSON should contain object properties")
    }
    
    // MARK: - Database to Swift Conversion Tests
    
    func testDatabaseToSwiftArrayConversion() throws {
        let stringArrayJSON = "[\"apple\",\"banana\",\"cherry\"]"
        let intArrayJSON = "[10,20,30]"
        let emptyArrayJSON = "[]"
        
        // Test string array conversion
        let stringArrayResult: [String]? = FuseTypeConverter.databaseToSwiftValue(stringArrayJSON, targetType: [String].self, autoInfer: true)
        XCTAssertNotNil(stringArrayResult, "Should successfully convert JSON to string array")
        XCTAssertEqual(stringArrayResult?.count, 3, "Array should have correct number of elements")
        XCTAssertEqual(stringArrayResult?[0], "apple", "Array elements should be preserved")
        XCTAssertEqual(stringArrayResult?[1], "banana", "Array elements should be preserved")
        XCTAssertEqual(stringArrayResult?[2], "cherry", "Array elements should be preserved")
        
        // Test int array conversion  
        let intArrayResult: [Int]? = FuseTypeConverter.databaseToSwiftValue(intArrayJSON, targetType: [Int].self, autoInfer: true)
        XCTAssertNotNil(intArrayResult, "Should successfully convert JSON to int array")
        XCTAssertEqual(intArrayResult?.count, 3, "Array should have correct number of elements")
        XCTAssertEqual(intArrayResult?[0], 10, "Array elements should be preserved")
        XCTAssertEqual(intArrayResult?[1], 20, "Array elements should be preserved")
        XCTAssertEqual(intArrayResult?[2], 30, "Array elements should be preserved")
        
        // Test empty array conversion
        let emptyArrayResult: [String]? = FuseTypeConverter.databaseToSwiftValue(emptyArrayJSON, targetType: [String].self, autoInfer: true)
        XCTAssertNotNil(emptyArrayResult, "Should successfully convert empty JSON to array")
        XCTAssertEqual(emptyArrayResult?.count, 0, "Empty array should have zero elements")
    }
    
    func testDatabaseToSwiftDictionaryConversion() throws {
        let stringDictJSON = "{\"name\":\"John\",\"city\":\"Taipei\"}"
        let intDictJSON = "{\"width\":100,\"height\":200}"
        let emptyDictJSON = "{}"
        
        // Test string dictionary conversion
        let stringDictResult: [String: String]? = FuseTypeConverter.databaseToSwiftValue(stringDictJSON, targetType: [String: String].self, autoInfer: true)
        XCTAssertNotNil(stringDictResult, "Should successfully convert JSON to string dictionary")
        XCTAssertEqual(stringDictResult?.count, 2, "Dictionary should have correct number of elements")
        XCTAssertEqual(stringDictResult?["name"], "John", "Dictionary values should be preserved")
        XCTAssertEqual(stringDictResult?["city"], "Taipei", "Dictionary values should be preserved")
        
        // Test int dictionary conversion
        let intDictResult: [String: Int]? = FuseTypeConverter.databaseToSwiftValue(intDictJSON, targetType: [String: Int].self, autoInfer: true)
        XCTAssertNotNil(intDictResult, "Should successfully convert JSON to int dictionary")
        XCTAssertEqual(intDictResult?.count, 2, "Dictionary should have correct number of elements")
        XCTAssertEqual(intDictResult?["width"], 100, "Dictionary values should be preserved")
        XCTAssertEqual(intDictResult?["height"], 200, "Dictionary values should be preserved")
        
        // Test empty dictionary conversion
        let emptyDictResult: [String: String]? = FuseTypeConverter.databaseToSwiftValue(emptyDictJSON, targetType: [String: String].self, autoInfer: true)
        XCTAssertNotNil(emptyDictResult, "Should successfully convert empty JSON to dictionary")
        XCTAssertEqual(emptyDictResult?.count, 0, "Empty dictionary should have zero elements")
    }
    
    func testDatabaseToSwiftNestedObjectConversion() throws {
        struct Address: Codable, Equatable {
            let street: String
            let city: String
            let zipCode: String
        }
        
        let addressJSON = "{\"street\":\"123 Main St\",\"city\":\"Taipei\",\"zipCode\":\"10001\"}"
        
        // Test nested object conversion
        let addressResult: Address? = FuseTypeConverter.databaseToSwiftValue(addressJSON, targetType: Address.self, autoInfer: true)
        XCTAssertNotNil(addressResult, "Should successfully convert JSON to Address object")
        XCTAssertEqual(addressResult?.street, "123 Main St", "Object properties should be preserved")
        XCTAssertEqual(addressResult?.city, "Taipei", "Object properties should be preserved")
        XCTAssertEqual(addressResult?.zipCode, "10001", "Object properties should be preserved")
    }
    
    // MARK: - Error Handling Tests
    
    func testInvalidJSONHandling() throws {
        let invalidJSON = "{invalid json}"
        
        // Test that invalid JSON returns nil instead of crashing
        let arrayResult: [String]? = FuseTypeConverter.databaseToSwiftValue(invalidJSON, targetType: [String].self, autoInfer: true)
        XCTAssertNil(arrayResult, "Invalid JSON should return nil for array conversion")
        
        let dictResult: [String: String]? = FuseTypeConverter.databaseToSwiftValue(invalidJSON, targetType: [String: String].self, autoInfer: true)
        XCTAssertNil(dictResult, "Invalid JSON should return nil for dictionary conversion")
        
        struct TestStruct: Codable {
            let name: String
        }
        
        let objectResult: TestStruct? = FuseTypeConverter.databaseToSwiftValue(invalidJSON, targetType: TestStruct.self, autoInfer: true)
        XCTAssertNil(objectResult, "Invalid JSON should return nil for object conversion")
    }
    
    func testNilValueHandling() throws {
        // Test nil values
        let nilArrayResult: [String]? = FuseTypeConverter.databaseToSwiftValue(nil, targetType: [String].self, autoInfer: true)
        XCTAssertNil(nilArrayResult, "Nil value should return nil for array conversion")
        
        let nilDictResult: [String: String]? = FuseTypeConverter.databaseToSwiftValue(nil, targetType: [String: String].self, autoInfer: true)
        XCTAssertNil(nilDictResult, "Nil value should return nil for dictionary conversion")
        
        // Test NSNull values
        let nsNullArrayResult: [String]? = FuseTypeConverter.databaseToSwiftValue(NSNull(), targetType: [String].self, autoInfer: true)
        XCTAssertNil(nsNullArrayResult, "NSNull value should return nil for array conversion")
    }
    
    // MARK: - Round-trip Conversion Tests
    
    func testArrayRoundTripConversion() throws {
        let originalStringArray = ["swift", "ios", "development", "testing"]
        let originalIntArray = [1, 2, 3, 4, 5]
        
        // Round-trip string array
        let stringDBValue = FuseTypeConverter.swiftToDatabaseValue(originalStringArray, columnType: .text, isOptional: false)
        let convertedStringArray: [String]? = FuseTypeConverter.databaseToSwiftValue(stringDBValue, targetType: [String].self, autoInfer: true)
        XCTAssertEqual(convertedStringArray, originalStringArray, "String array should survive round-trip conversion")
        
        // Round-trip int array
        let intDBValue = FuseTypeConverter.swiftToDatabaseValue(originalIntArray, columnType: .text, isOptional: false)
        let convertedIntArray: [Int]? = FuseTypeConverter.databaseToSwiftValue(intDBValue, targetType: [Int].self, autoInfer: true)
        XCTAssertEqual(convertedIntArray, originalIntArray, "Int array should survive round-trip conversion")
    }
    
    func testDictionaryRoundTripConversion() throws {
        let originalStringDict = ["name": "John", "role": "Developer", "location": "Taipei"]
        let originalIntDict = ["width": 100, "height": 200, "depth": 50]
        
        // Round-trip string dictionary
        let stringDBValue = FuseTypeConverter.swiftToDatabaseValue(originalStringDict, columnType: .text, isOptional: false)
        let convertedStringDict: [String: String]? = FuseTypeConverter.databaseToSwiftValue(stringDBValue, targetType: [String: String].self, autoInfer: true)
        XCTAssertEqual(convertedStringDict, originalStringDict, "String dictionary should survive round-trip conversion")
        
        // Round-trip int dictionary
        let intDBValue = FuseTypeConverter.swiftToDatabaseValue(originalIntDict, columnType: .text, isOptional: false)
        let convertedIntDict: [String: Int]? = FuseTypeConverter.databaseToSwiftValue(intDBValue, targetType: [String: Int].self, autoInfer: true)
        XCTAssertEqual(convertedIntDict, originalIntDict, "Int dictionary should survive round-trip conversion")
    }
    
    func testNestedObjectRoundTripConversion() throws {
        struct ContactInfo: Codable, Equatable {
            let email: String
            let phone: String?
        }
        
        let originalContact = ContactInfo(email: "test@example.com", phone: "+886-123-456-789")
        let originalContactWithNilPhone = ContactInfo(email: "nil@example.com", phone: nil)
        
        // Round-trip contact with phone
        let contactDBValue = FuseTypeConverter.swiftToDatabaseValue(originalContact, columnType: .text, isOptional: false)
        let convertedContact: ContactInfo? = FuseTypeConverter.databaseToSwiftValue(contactDBValue, targetType: ContactInfo.self, autoInfer: true)
        XCTAssertEqual(convertedContact, originalContact, "ContactInfo should survive round-trip conversion")
        
        // Round-trip contact with nil phone
        let nilPhoneDBValue = FuseTypeConverter.swiftToDatabaseValue(originalContactWithNilPhone, columnType: .text, isOptional: false)
        let convertedNilPhoneContact: ContactInfo? = FuseTypeConverter.databaseToSwiftValue(nilPhoneDBValue, targetType: ContactInfo.self, autoInfer: true)
        XCTAssertEqual(convertedNilPhoneContact, originalContactWithNilPhone, "ContactInfo with nil phone should survive round-trip conversion")
    }
    
    // MARK: - Complex Nested Structure Tests
    
    func testComplexNestedStructure() throws {
        struct Address: Codable, Equatable {
            let street: String
            let city: String
            let zipCode: String
        }
        
        struct ContactInfo: Codable, Equatable {
            let email: String
            let phone: String?
        }
        
        struct Person: Codable, Equatable {
            let name: String
            let age: Int
            let address: Address
            let contacts: [ContactInfo]
            let metadata: [String: String]
        }
        
        let address = Address(street: "123 Main St", city: "Taipei", zipCode: "10001")
        let contacts = [
            ContactInfo(email: "primary@example.com", phone: "+886-123-456-789"),
            ContactInfo(email: "secondary@example.com", phone: nil)
        ]
        let metadata = ["department": "Engineering", "level": "Senior"]
        
        let originalPerson = Person(
            name: "John Doe",
            age: 30,
            address: address,
            contacts: contacts,
            metadata: metadata
        )
        
        // Round-trip complex nested structure
        let personDBValue = FuseTypeConverter.swiftToDatabaseValue(originalPerson, columnType: .text, isOptional: false)
        let convertedPerson: Person? = FuseTypeConverter.databaseToSwiftValue(personDBValue, targetType: Person.self, autoInfer: true)
        
        XCTAssertNotNil(convertedPerson, "Complex nested structure should be convertible")
        XCTAssertEqual(convertedPerson, originalPerson, "Complex nested structure should survive round-trip conversion")
        
        // Verify individual nested components
        XCTAssertEqual(convertedPerson?.name, "John Doe")
        XCTAssertEqual(convertedPerson?.age, 30)
        XCTAssertEqual(convertedPerson?.address.city, "Taipei")
        XCTAssertEqual(convertedPerson?.contacts.count, 2)
        XCTAssertEqual(convertedPerson?.contacts[0].email, "primary@example.com")
        XCTAssertNil(convertedPerson?.contacts[1].phone)
        XCTAssertEqual(convertedPerson?.metadata["department"], "Engineering")
    }
    
    // MARK: - Performance Tests
    
    func testArrayConversionPerformance() throws {
        let largeArray = Array(0..<1000).map { "item_\($0)" }
        
        measure {
            for _ in 0..<100 {
                let dbValue = FuseTypeConverter.swiftToDatabaseValue(largeArray, columnType: .text, isOptional: false)
                let _: [String]? = FuseTypeConverter.databaseToSwiftValue(dbValue, targetType: [String].self, autoInfer: true)
            }
        }
    }
    
    func testDictionaryConversionPerformance() throws {
        let largeDictionary = Dictionary(uniqueKeysWithValues: (0..<1000).map { ("key_\($0)", "value_\($0)") })
        
        measure {
            for _ in 0..<100 {
                let dbValue = FuseTypeConverter.swiftToDatabaseValue(largeDictionary, columnType: .text, isOptional: false)
                let _: [String: String]? = FuseTypeConverter.databaseToSwiftValue(dbValue, targetType: [String: String].self, autoInfer: true)
            }
        }
    }
} 