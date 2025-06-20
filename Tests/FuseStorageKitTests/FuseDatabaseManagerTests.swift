import XCTest
@testable import FuseStorageKit
import GRDB

// Mock record type for testing - using the new simplified approach
struct MockRecord: FuseDatabaseRecord, Equatable {
    static var _fuseidField: String = "id"

    var id: Int64
    var name: String
    var value: Int64

    init(id: Int64, name: String, value: Int64) {
        self.id = id
        self.name = name
        self.value = value
    }
    
    /// Table definition for this record type
    var tableDefinition: FuseTableDefinition {
        return FuseTableDefinition(
            name: Self.databaseTableName,
            columns: [
                FuseColumnDefinition(name: "id", type: .integer, isPrimaryKey: true),
                FuseColumnDefinition(name: "name", type: .text, isNotNull: true),
                FuseColumnDefinition(name: "value", type: .integer, isNotNull: true)
            ],
            options: [.ifNotExists]
        )
    }
}

// Explicitly define databaseTableName outside the struct to ensure it overrides the default
extension MockRecord {
    static var databaseTableName: String { 
        return "mock_records" 
    }
}

class FuseDatabaseManagerTests: XCTestCase {

    var dbManager: FuseDatabaseManager!
    var tempDBPath: String!

    override func setUpWithError() throws {
        try super.setUpWithError()
        
        // Create a unique temporary database file name for each test
        tempDBPath = "test_\(UUID().uuidString).sqlite"
        
        let manager = try FuseDatabaseManager(path: tempDBPath)
        self.dbManager = manager
        
        // Define and create a table for MockRecord
        let tableDefinition = FuseTableDefinition(
            name: MockRecord.databaseTableName,
            columns: [
                FuseColumnDefinition(name: "id", type: .integer, isPrimaryKey: true),
                FuseColumnDefinition(name: "name", type: .text, isNotNull: true),
                FuseColumnDefinition(name: "value", type: .integer, isNotNull: true)
            ],
            options: [.ifNotExists]
        )
        try dbManager.createTable(tableDefinition)
    }

    override func tearDownWithError() throws {
        // Clean up the temporary database file
        dbManager = nil
        
        if let tempDBPath = tempDBPath {
            let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let dbURL = docs.appendingPathComponent(tempDBPath)
            try? FileManager.default.removeItem(at: dbURL)
        }
        
        try super.tearDownWithError()
    }

    func testDatabaseInitialization() throws {
        // Test in-memory initialization (already done in setUp)
        XCTAssertNotNil(dbManager, "DatabaseManager should be initialized.")

        // Test file-based initialization
        let fileManager = FileManager.default
        let docsDir = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let dbPath = "test_fuse.sqlite"
        let dbURL = docsDir.appendingPathComponent(dbPath)

        // Clean up any existing test database file
        if fileManager.fileExists(atPath: dbURL.path) {
            try fileManager.removeItem(at: dbURL)
        }

        let fileDBManager = try FuseDatabaseManager(path: dbPath)
        XCTAssertNotNil(fileDBManager, "File-based DatabaseManager should be initialized.")
        XCTAssertTrue(fileManager.fileExists(atPath: dbURL.path), "Database file should be created.")

        // Clean up the created database file
        try fileManager.removeItem(at: dbURL)
    }

    func testTableExists() throws {
        let exists = try dbManager.tableExists(MockRecord.databaseTableName)
        XCTAssertTrue(exists, "Table '\(MockRecord.databaseTableName)' should exist after creation.")

        let nonExistentTable = "non_existent_table"
        let notExists = try dbManager.tableExists(nonExistentTable)
        XCTAssertFalse(notExists, "Table '\(nonExistentTable)' should not exist.")
    }

    func testCreateTable() throws {
        let newTableName = "new_test_table"
        let tableDefinition = FuseTableDefinition(
            name: newTableName,
            columns: [
                FuseColumnDefinition(name: "column1", type: .text)
            ],
            options: [.ifNotExists]
        )
        try dbManager.createTable(tableDefinition)
        let exists = try dbManager.tableExists(newTableName)
        XCTAssertTrue(exists, "Table '\(newTableName)' should be created and exist.")
    }

    func testAddRecord() throws {
        let record = MockRecord(id: 1, name: "Test Record 1", value: 100)
        try dbManager.add(record)

        // Fetch to verify
        let fetchedRecords: [MockRecord] = try dbManager.fetch(of: MockRecord.self, filters: [
            FuseQueryFilter.equals(field: "name", value: "Test Record 1")
        ])
        
        XCTAssertEqual(fetchedRecords.count, 1, "Should fetch one record after adding.")
        XCTAssertEqual(fetchedRecords.first?.name, "Test Record 1")
        XCTAssertEqual(fetchedRecords.first?.value, 100)
    }

    func testFetchRecords() throws {
        let record1 = MockRecord(id: 10, name: "Fetch Record 1", value: 10)
        let record2 = MockRecord(id: 11, name: "Fetch Record 2", value: 20)
        try dbManager.add(record1)
        try dbManager.add(record2)

        let allRecords: [MockRecord] = try dbManager.fetch(of: MockRecord.self)
        XCTAssertGreaterThanOrEqual(allRecords.count, 2, "Should fetch at least two records.")

        // Test filtering
        let filteredRecords: [MockRecord] = try dbManager.fetch(of: MockRecord.self, filters: [
            FuseQueryFilter.greaterThan(field: "value", value: 15)
        ])
        XCTAssertEqual(filteredRecords.count, 1, "Should fetch one record with value > 15.")
        XCTAssertEqual(filteredRecords.first?.name, "Fetch Record 2")

        // Test sorting
        let sortedRecords: [MockRecord] = try dbManager.fetch(of: MockRecord.self, sort: FuseQuerySort(field: "value", order: .ascending))
        XCTAssertEqual(sortedRecords.first?.value, 10)
        XCTAssertEqual(sortedRecords.last?.value, 20)
        
        // Test limit
        let limitedRecords: [MockRecord] = try dbManager.fetch(of: MockRecord.self, sort: FuseQuerySort(field: "value", order: .ascending), limit: 1)
        XCTAssertEqual(limitedRecords.count, 1)
        XCTAssertEqual(limitedRecords.first?.value, 10)

        // Test offset
        let offsetRecords: [MockRecord] = try dbManager.fetch(of: MockRecord.self, sort: FuseQuerySort(field: "value", order: .ascending), limit: 1, offset: 1)
        XCTAssertEqual(offsetRecords.count, 1)
        XCTAssertEqual(offsetRecords.first?.value, 20)
    }

    func testDeleteRecord() throws {
        var recordToDelete = MockRecord(id: 20, name: "Delete Me", value: 555)
        try dbManager.add(recordToDelete)

        // Fetch to get the ID assigned by the database
        let recordsBeforeDelete: [MockRecord] = try dbManager.fetch(of: MockRecord.self, filters: [
            FuseQueryFilter.equals(field: "name", value: "Delete Me")
        ])
        XCTAssertEqual(recordsBeforeDelete.count, 1)
        recordToDelete.id = recordsBeforeDelete.first?.id ?? recordToDelete.id // Use the original ID if fetch fails

        XCTAssertNotNil(recordToDelete.id, "Record ID should be set after fetching.")

        try dbManager.delete(recordToDelete)

        let recordsAfterDelete: [MockRecord] = try dbManager.fetch(of: MockRecord.self, filters: [
            FuseQueryFilter.equals(field: "name", value: "Delete Me")
        ])
        XCTAssertEqual(recordsAfterDelete.count, 0, "Record should be deleted.")
    }
    
    func testReadQuery() throws {
        let record1 = MockRecord(id: 30, name: "Read Query 1", value: 101)
        let record2 = MockRecord(id: 31, name: "Read Query 2", value: 102)
        try dbManager.add(record1)
        try dbManager.add(record2)

        let query = FuseQuery(
            table: MockRecord.databaseTableName,
            action: .select(fields: ["*"], filters: [FuseQueryFilter.equals(field: "value", value: 101)], sort: nil)
        )
        let results: [MockRecord] = try dbManager.read(query)
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.name, "Read Query 1")
    }

    func testWriteQuery() throws {
        // Test INSERT via write
        let insertQuery = FuseQuery(
            table: MockRecord.databaseTableName,
            action: .insert(values: ["name": "Write Insert", "value": 201])
        )
        try dbManager.write(insertQuery)
        let fetchedInsert: [MockRecord] = try dbManager.fetch(of: MockRecord.self, filters: [FuseQueryFilter.equals(field: "name", value: "Write Insert")])
        XCTAssertEqual(fetchedInsert.count, 1)
        XCTAssertEqual(fetchedInsert.first?.value, 201)

        // Test UPDATE via write (assuming the record "Write Insert" now has an ID)
        guard let recordToUpdate = fetchedInsert.first else {
            XCTFail("Failed to fetch record for update test")
            return
        }
        let recordId = recordToUpdate.id
        let updateQuery = FuseQuery(
            table: MockRecord.databaseTableName,
            action: .update(values: ["value": 202], filters: [FuseQueryFilter.equals(field: "id", value: recordId)])
        )
        try dbManager.write(updateQuery)
        let fetchedUpdate: [MockRecord] = try dbManager.fetch(of: MockRecord.self, filters: [FuseQueryFilter.equals(field: "id", value: recordId)])
        XCTAssertEqual(fetchedUpdate.count, 1)
        XCTAssertEqual(fetchedUpdate.first?.value, 202)

        // Test DELETE via write
        let deleteQuery = FuseQuery(
            table: MockRecord.databaseTableName,
            action: .delete(filters: [FuseQueryFilter.equals(field: "id", value: recordId)])
        )
        try dbManager.write(deleteQuery)
        let fetchedDelete: [MockRecord] = try dbManager.fetch(of: MockRecord.self, filters: [FuseQueryFilter.equals(field: "id", value: recordId)])
        XCTAssertEqual(fetchedDelete.count, 0)
    }

    func testDatabaseEncryption() throws {
        // 設定測試用的加密資料庫路徑
        let fileManager = FileManager.default
        let docsDir = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let encryptedDBPath = "encrypted_test.sqlite"
        let encryptedDBURL = docsDir.appendingPathComponent(encryptedDBPath)
        let passphrase = "TestEncryptionKey123"
        
        // 清理之前可能存在的測試檔案
        if fileManager.fileExists(atPath: encryptedDBURL.path) {
            try fileManager.removeItem(at: encryptedDBURL)
        }
        
        // 1. 建立加密資料庫並寫入資料
        do {
            // 使用標準安全級別的加密選項
            let encryptionOptions = EncryptionOptions.standard(passphrase: passphrase)
            
            let encryptedDBManager = try FuseDatabaseManager(
                path: encryptedDBPath, 
                encryptions: encryptionOptions
            )
            
            // 建立測試表格
            let tableDefinition = FuseTableDefinition(
                name: "encrypted_test_table",
                columns: [
                    FuseColumnDefinition(name: "id", type: .integer, isPrimaryKey: true, isNotNull: true),
                    FuseColumnDefinition(name: "secret_data", type: .text, isNotNull: true)
                ],
                options: [.ifNotExists]
            )
            try encryptedDBManager.createTable(tableDefinition)
            
            // 寫入機密資料
            let insertQuery = FuseQuery(
                table: "encrypted_test_table",
                action: .insert(values: ["id": 1, "secret_data": "This is sensitive information"])
            )
            try encryptedDBManager.write(insertQuery)
            
            // 使用 read 方法讀取資料
            let selectQuery = FuseQuery(
                table: "encrypted_test_table",
                action: .select(fields: ["id", "secret_data"], filters: [], sort: nil)
            )
            
            // 使用 MockSecretData 讀取結果
            struct MockSecretData: FuseDatabaseRecord {
                static var databaseTableName: String = "encrypted_test_table"
                static var _fuseidField: String = "id"
                
                var id: Int64
                var secret_data: String
                
                /// Table definition for this record type
                var tableDefinition: FuseTableDefinition {
                    return FuseTableDefinition(
                        name: Self.databaseTableName,
                        columns: [
                            FuseColumnDefinition(name: "id", type: .integer, isPrimaryKey: true),
                            FuseColumnDefinition(name: "secret_data", type: .text, isNotNull: true)
                        ],
                        options: [.ifNotExists]
                    )
                }
            }
            
            let results: [MockSecretData] = try encryptedDBManager.read(selectQuery)
            
            XCTAssertEqual(results.count, 1)
            XCTAssertEqual(results.first?.secret_data, "This is sensitive information")
        }
        
        // 測試不同安全級別
        do {
            // 使用高安全級別加密選項
            let highSecurityEncryption = EncryptionOptions.high(passphrase: passphrase)
            XCTAssertNoThrow(try FuseDatabaseManager(
                path: "high_security_test.sqlite",
                encryptions: highSecurityEncryption
            ))
            
            // 使用性能優先的加密選項
            let performanceEncryption = EncryptionOptions.performance(passphrase: passphrase)
            XCTAssertNoThrow(try FuseDatabaseManager(
                path: "performance_test.sqlite",
                encryptions: performanceEncryption
            ))
            
            // 測試自訂加密選項
            let customEncryption = EncryptionOptions(passphrase)
                .pageSize(4096)
                .kdfIter(50_000)
                .memorySecurity(true)
                .defaultPageSize(4096)
                .defaultKdfIter(50_000)
            
            XCTAssertNoThrow(try FuseDatabaseManager(
                path: "custom_test.sqlite",
                encryptions: customEncryption
            ))
        }
        
        // 2. 嘗試使用錯誤的金鑰開啟資料庫 (這應該會失敗)
        XCTAssertThrowsError(try FuseDatabaseManager(
            path: encryptedDBPath, 
            encryptions: EncryptionOptions.standard(passphrase: "WrongKey")
        )) { error in
            // 注意：在實際場景中，SQLCipher 會拋出不同的錯誤，這裡我們只是確保它失敗了
            print("Expected error when opening with wrong key: \(error)")
        }
        
        // 3. 使用正確金鑰開啟資料庫並驗證資料
        do {
            let reopenedDBManager = try FuseDatabaseManager(
                path: encryptedDBPath, 
                encryptions: EncryptionOptions.standard(passphrase: passphrase)
            )
            
            // 再次定義用於讀取的結構
            struct MockSecretData: FuseDatabaseRecord {
                static var databaseTableName: String = "encrypted_test_table"
                static var _fuseidField: String = "id"
                
                var id: Int64
                var secret_data: String
                
                /// Table definition for this record type
                var tableDefinition: FuseTableDefinition {
                    return FuseTableDefinition(
                        name: Self.databaseTableName,
                        columns: [
                            FuseColumnDefinition(name: "id", type: .integer, isPrimaryKey: true),
                            FuseColumnDefinition(name: "secret_data", type: .text, isNotNull: true)
                        ],
                        options: [.ifNotExists]
                    )
                }
            }
            
            // 使用 FuseDatabaseManageable 提供的 fetch 方法
            let results: [MockSecretData] = try reopenedDBManager.fetch(of: MockSecretData.self)
            
            XCTAssertEqual(results.count, 1)
            XCTAssertEqual(results.first?.secret_data, "This is sensitive information")
        }
        
        // 清理測試資料庫檔案
        if fileManager.fileExists(atPath: encryptedDBURL.path) {
            try fileManager.removeItem(at: encryptedDBURL)
        }
        
        // 清理其他測試檔案
        ["high_security_test.sqlite", "performance_test.sqlite", "custom_test.sqlite"].forEach { path in
            let url = docsDir.appendingPathComponent(path)
            if fileManager.fileExists(atPath: url.path) {
                try? fileManager.removeItem(at: url)
            }
        }
    }

    func testCreateTableWithMultipleColumnsAndTypes() throws {
        let newTableName = "multi_column_table"
        let tableDefinition = FuseTableDefinition(
            name: newTableName,
            columns: [
                FuseColumnDefinition(name: "id", type: .integer, isPrimaryKey: true),
                FuseColumnDefinition(name: "name", type: .text),
                FuseColumnDefinition(name: "value", type: .real),
                FuseColumnDefinition(name: "is_active", type: .boolean),
                FuseColumnDefinition(name: "created_at", type: .date),
                FuseColumnDefinition(name: "data", type: .blob)
            ]
        )
        try dbManager.createTable(tableDefinition)
        let exists = try dbManager.tableExists(newTableName)
        XCTAssertTrue(exists, "Table '\(newTableName)' with multiple columns and types should be created and exist.")
    }

    func testCreateTableWithNewColumnTypes() throws {
        let newTableName = "new_types_table"
        let tableDefinition = FuseTableDefinition(
            name: newTableName,
            columns: [
                FuseColumnDefinition(name: "id", type: .integer, isPrimaryKey: true),
                FuseColumnDefinition(name: "double_value", type: .double),
                FuseColumnDefinition(name: "numeric_value", type: .numeric),
                FuseColumnDefinition(name: "any_value", type: .any)
            ]
        )
        try dbManager.createTable(tableDefinition)
        let exists = try dbManager.tableExists(newTableName)
        XCTAssertTrue(exists, "Table '\(newTableName)' with new column types should be created and exist.")
        
        // Optional: Further checks can be added here to inspect table schema
    }

    func testCreateTableWithConstraints() throws {
        let newTableName = "constrained_table"
        let tableDefinition = FuseTableDefinition(
            name: newTableName,
            columns: [
                FuseColumnDefinition(name: "id", type: .integer, isPrimaryKey: true),
                FuseColumnDefinition(name: "name", type: .text, isNotNull: true, isUnique: true),
                FuseColumnDefinition(name: "status", type: .text, defaultValue: "active")
            ]
        )
        try dbManager.createTable(tableDefinition)
        let exists = try dbManager.tableExists(newTableName)
        XCTAssertTrue(exists, "Table '\(newTableName)' with constraints should be created and exist.")

        // Optional: Verify constraints by trying to insert invalid data (requires more complex setup)
    }

    func testCreateTableWithOptions() throws {
        let newTableNameTemporary = "temporary_table"
        let tableDefinitionTemporary = FuseTableDefinition(
            name: newTableNameTemporary,
            columns: [
                FuseColumnDefinition(name: "id", type: .integer)
            ],
            options: [.temporary]
        )
        try dbManager.createTable(tableDefinitionTemporary)
        let existsTemporary = try dbManager.tableExists(newTableNameTemporary)
        XCTAssertTrue(existsTemporary, "Temporary table '\(newTableNameTemporary)' should be created and exist within the session.")

        let newTableNameWithoutRowID = "without_rowid_table"
        let tableDefinitionWithoutRowID = FuseTableDefinition(
            name: newTableNameWithoutRowID,
            columns: [
                FuseColumnDefinition(name: "id", type: .integer, isPrimaryKey: true)
            ],
            options: [.withoutRowID]
        )
        try dbManager.createTable(tableDefinitionWithoutRowID)
        let existsWithoutRowID = try dbManager.tableExists(newTableNameWithoutRowID)
        XCTAssertTrue(existsWithoutRowID, "Table '\(newTableNameWithoutRowID)' without rowid should be created and exist.")

        // Strict option requires iOS 15.4+, test conditionally or in a separate test suite if needed
        // let newTableNameStrict = "strict_table"
        // if #available(iOS 15.4, macOS 12.4, tvOS 15.4, watchOS 8.5, *) {
        //     let tableDefinitionStrict = FuseTableDefinition(
        //         name: newTableNameStrict,
        //         columns: [
        //             FuseColumnDefinition(name: "id", type: .integer)
        //         ],
        //         options: [.strict]
        //     )
        //     try dbManager.createTable(tableDefinitionStrict)
        //     let existsStrict = try dbManager.tableExists(newTableNameStrict)
        //     XCTAssertTrue(existsStrict, "Table '\(newTableNameStrict)' with strict option should be created and exist (on supported platforms).")
        // }
    }

    func testCreateTableIfExists() throws {
        let newTableName = "if_not_exists_table"
        let tableDefinition = FuseTableDefinition(
            name: newTableName,
            columns: [
                FuseColumnDefinition(name: "id", type: .integer)
            ],
            options: [.ifNotExists]
        )

        // First creation
        try dbManager.createTable(tableDefinition)
        let existsAfterFirst = try dbManager.tableExists(newTableName)
        XCTAssertTrue(existsAfterFirst, "Table '\(newTableName)' should exist after first creation.")

        // Second creation with .ifNotExists - should not throw
        XCTAssertNoThrow(try dbManager.createTable(tableDefinition), "Creating table with .ifNotExists option when table already exists should not throw an error.")
        let existsAfterSecond = try dbManager.tableExists(newTableName)
        XCTAssertTrue(existsAfterSecond, "Table '\(newTableName)' should still exist after second creation with .ifNotExists.")
    }

    func testCreateTableWithoutIfExists() throws {
        let newTableName = "no_if_not_exists_table"
        let tableDefinition = FuseTableDefinition(
            name: newTableName,
            columns: [
                FuseColumnDefinition(name: "id", type: .integer)
            ],
            options: []  // make sure it's not .ifNotExists
        )

        // First creation
        try dbManager.createTable(tableDefinition)
        let existsAfterFirst = try dbManager.tableExists(newTableName)
        XCTAssertTrue(existsAfterFirst, "Table '\(newTableName)' should exist after first creation.")

        // Second creation without .ifNotExists - should throw an error
        XCTAssertThrowsError(try dbManager.createTable(tableDefinition), "Creating table without .ifNotExists option when table already exists should throw an error.") { error in
            // check if the error type is DatabaseError.tableAlreadyExists
            guard let dbError = error as? FuseDatabaseError else {
                XCTFail("Expected a DatabaseError")
                return
            }
            
            if case .tableAlreadyExists(let tableName) = dbError {
                XCTAssertEqual(tableName, newTableName, "Error should contain the correct table name")
            } else {
                XCTFail("Expected DatabaseError.tableAlreadyExists, but got \(dbError)")
            }
        }
        let existsAfterSecond = try dbManager.tableExists(newTableName)
        XCTAssertTrue(existsAfterSecond, "Table '\(newTableName)' should still exist after attempted second creation.")
    }

    // Test adding a single record
    func testAddSingleRecord() throws {
        let record = MockRecord(id: 1, name: "Test1", value: 100)
        try dbManager.add(record)

        let fetchedRecords: [MockRecord] = try dbManager.fetch(of: MockRecord.self)
        XCTAssertEqual(fetchedRecords.count, 1)
        XCTAssertEqual(fetchedRecords.first?.id, 1)
        XCTAssertEqual(fetchedRecords.first?.name, "Test1")
        XCTAssertEqual(fetchedRecords.first?.value, 100)
    }
    
    // Test batch adding records
    func testBatchAddRecords() throws {
        let records = [
            MockRecord(id: 4, name: "Test4", value: 400),
            MockRecord(id: 5, name: "Test5", value: 500),
            MockRecord(id: 6, name: "Test6", value: 600)
        ]
        try dbManager.add(records)
        
        let fetchedRecords: [MockRecord] = try dbManager.fetch(of: MockRecord.self)
        XCTAssertEqual(fetchedRecords.count, 3) // Only the newly added records
        XCTAssertEqual(fetchedRecords[0].id, 4)
        XCTAssertEqual(fetchedRecords[1].id, 5)
        XCTAssertEqual(fetchedRecords[2].id, 6)
    }
    
    // Test batch adding records with existing data
    func testBatchAddRecordsWithExistingData() throws {
        // Add some initial data
        try dbManager.add(MockRecord(id: 1, name: "Test1", value: 100))
        
        let recordsToAdd = [
            MockRecord(id: 7, name: "Test7", value: 700),
            MockRecord(id: 8, name: "Test8", value: 800)
        ]
        try dbManager.add(recordsToAdd)
        
        let fetchedRecords: [MockRecord] = try dbManager.fetch(of: MockRecord.self)
        XCTAssertEqual(fetchedRecords.count, 3) // Initial record + 2 new records
        
        let sortedRecords = fetchedRecords.sorted { $0.id < $1.id }
        XCTAssertEqual(sortedRecords[0].id, 1)
        XCTAssertEqual(sortedRecords[1].id, 7)
        XCTAssertEqual(sortedRecords[2].id, 8)
    }
    
    // Test batch deleting records
    func testBatchDeleteRecords() throws {
        // Add some records first
        let records = [
            MockRecord(id: 10, name: "BatchDelete1", value: 1000),
            MockRecord(id: 11, name: "BatchDelete2", value: 1100),
            MockRecord(id: 12, name: "BatchDelete3", value: 1200)
        ]
        try dbManager.add(records)
        
        // Verify records were added
        let fetchedBeforeDelete: [MockRecord] = try dbManager.fetch(of: MockRecord.self, filters: [
            FuseQueryFilter.greaterThan(field: "id", value: 9)
        ])
        XCTAssertEqual(fetchedBeforeDelete.count, 3, "Should have 3 records before batch delete")
        
        // Delete records in batch
        try dbManager.delete(records)
        
        // Verify records were deleted
        let fetchedAfterDelete: [MockRecord] = try dbManager.fetch(of: MockRecord.self, filters: [
            FuseQueryFilter.greaterThan(field: "id", value: 9)
        ])
        XCTAssertEqual(fetchedAfterDelete.count, 0, "All records should be deleted after batch delete")
    }
    
    // Test batch deleting with empty array
    func testBatchDeleteEmptyArray() throws {
        // Add a record to verify it's not affected
        try dbManager.add(MockRecord(id: 20, name: "NotDeleted", value: 2000))
        
        // Call batch delete with empty array
        let emptyArray: [MockRecord] = []
        XCTAssertNoThrow(try dbManager.delete(emptyArray), "Batch delete with empty array should not throw")
        
        // Verify the existing record is not affected
        let fetchedRecords: [MockRecord] = try dbManager.fetch(of: MockRecord.self, filters: [
            FuseQueryFilter.equals(field: "id", value: 20)
        ])
        XCTAssertEqual(fetchedRecords.count, 1, "Existing record should not be affected by empty batch delete")
    }
    
    // Test batch deleting a subset of records
    func testBatchDeleteSubset() throws {
        // Add several records
        try dbManager.add([
            MockRecord(id: 30, name: "Keep", value: 3000),
            MockRecord(id: 31, name: "Delete1", value: 3100),
            MockRecord(id: 32, name: "Delete2", value: 3200),
            MockRecord(id: 33, name: "Keep", value: 3300)
        ])
        
        // Delete only a subset
        let recordsToDelete = [
            MockRecord(id: 31, name: "Delete1", value: 3100),
            MockRecord(id: 32, name: "Delete2", value: 3200)
        ]
        try dbManager.delete(recordsToDelete)
        
        // Verify only the subset was deleted
        let remainingRecords: [MockRecord] = try dbManager.fetch(of: MockRecord.self, filters: [
            FuseQueryFilter.greaterThan(field: "id", value: 29)
        ])
        XCTAssertEqual(remainingRecords.count, 2, "Should have 2 remaining records")
        
        // Verify the correct records remain
        let remainingIds = remainingRecords.map { $0.id }
        XCTAssertTrue(remainingIds.contains(30), "Record with ID 30 should remain")
        XCTAssertTrue(remainingIds.contains(33), "Record with ID 33 should remain")
        XCTAssertFalse(remainingIds.contains(31), "Record with ID 31 should be deleted")
        XCTAssertFalse(remainingIds.contains(32), "Record with ID 32 should be deleted")
    }

    // Test encryption with empty passphrase should fail
    func testEncryptionWithEmptyPassphrase() throws {
        XCTAssertThrowsError(try FuseDatabaseManager(
            path: "empty_passphrase_test.sqlite",
            encryptions: EncryptionOptions("")
        )) { error in
            guard let dbError = error as? FuseDatabaseError else {
                XCTFail("Expected FuseDatabaseError")
                return
            }
            if case .missingPassphrase = dbError {
                // This is the expected error
            } else {
                XCTFail("Expected FuseDatabaseError.missingPassphrase, but got \(dbError)")
            }
        }
    }
    
    // Test encryption passphrase validation
    func testEncryptionPassphraseValidation() throws {
        let validPassphrase = "ValidPassphrase123"
        let invalidPassphrase = ""
        
        // Valid passphrase should work
        let validEncryption = EncryptionOptions.standard(passphrase: validPassphrase)
        XCTAssertNoThrow(try FuseDatabaseManager(
            path: "valid_passphrase_test.sqlite",
            encryptions: validEncryption
        ))
        
        // Invalid (empty) passphrase should fail
        XCTAssertThrowsError(try FuseDatabaseManager(
            path: "invalid_passphrase_test.sqlite",
            encryptions: EncryptionOptions(invalidPassphrase)
        )) { error in
            guard let dbError = error as? FuseDatabaseError else {
                XCTFail("Expected FuseDatabaseError for empty passphrase")
                return
            }
            if case .missingPassphrase = dbError {
                // Expected error
            } else {
                XCTFail("Expected FuseDatabaseError.missingPassphrase, but got \(dbError)")
            }
        }
        
        // Clean up
        let fileManager = FileManager.default
        let docsDir = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        ["valid_passphrase_test.sqlite", "invalid_passphrase_test.sqlite"].forEach { path in
            let url = docsDir.appendingPathComponent(path)
            if fileManager.fileExists(atPath: url.path) {
                try? fileManager.removeItem(at: url)
            }
        }
    }
    
    // Test full CRUD operations on encrypted database
    func testEncryptedDatabaseCRUDOperations() throws {
        let fileManager = FileManager.default
        let docsDir = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let encryptedDBPath = "crud_encrypted_test.sqlite"
        let encryptedDBURL = docsDir.appendingPathComponent(encryptedDBPath)
        let passphrase = "CRUDTestPassphrase456"
        
        // Clean up any existing test file
        if fileManager.fileExists(atPath: encryptedDBURL.path) {
            try fileManager.removeItem(at: encryptedDBURL)
        }
        
        // Create encrypted database manager
        let encryptionOptions = EncryptionOptions.standard(passphrase: passphrase)
        let encryptedDBManager = try FuseDatabaseManager(
            path: encryptedDBPath,
            encryptions: encryptionOptions
        )
        
        // Create MockRecord table in the encrypted database
        let tableDefinition = FuseTableDefinition(
            name: MockRecord.databaseTableName,
            columns: [
                FuseColumnDefinition(name: "id", type: .integer, isPrimaryKey: true),
                FuseColumnDefinition(name: "name", type: .text, isNotNull: true),
                FuseColumnDefinition(name: "value", type: .integer, isNotNull: true)
            ],
            options: [.ifNotExists]
        )
        try encryptedDBManager.createTable(tableDefinition)
        
        // Test CREATE (Add records)
        let testRecord1 = MockRecord(id: 1, name: "Encrypted Record 1", value: 1001)
        let testRecord2 = MockRecord(id: 2, name: "Encrypted Record 2", value: 1002)
        try encryptedDBManager.add(testRecord1)
        try encryptedDBManager.add([testRecord2])
        
        // Test READ (Fetch records)
        let allRecords: [MockRecord] = try encryptedDBManager.fetch(of: MockRecord.self)
        XCTAssertEqual(allRecords.count, 2, "Should have 2 records in encrypted database")
        XCTAssertTrue(allRecords.contains { $0.name == "Encrypted Record 1" })
        XCTAssertTrue(allRecords.contains { $0.name == "Encrypted Record 2" })
        
        // Test filtered fetch
        let filteredRecords: [MockRecord] = try encryptedDBManager.fetch(
            of: MockRecord.self,
            filters: [FuseQueryFilter.equals(field: "value", value: 1001)]
        )
        XCTAssertEqual(filteredRecords.count, 1)
        XCTAssertEqual(filteredRecords.first?.name, "Encrypted Record 1")
        
        // Test UPDATE via write query
        let updateQuery = FuseQuery(
            table: MockRecord.databaseTableName,
            action: .update(
                values: ["name": "Updated Encrypted Record 1"],
                filters: [FuseQueryFilter.equals(field: "id", value: 1)]
            )
        )
        try encryptedDBManager.write(updateQuery)
        
        // Verify update
        let updatedRecords: [MockRecord] = try encryptedDBManager.fetch(
            of: MockRecord.self,
            filters: [FuseQueryFilter.equals(field: "id", value: 1)]
        )
        XCTAssertEqual(updatedRecords.count, 1)
        XCTAssertEqual(updatedRecords.first?.name, "Updated Encrypted Record 1")
        
        // Test DELETE
        let recordToDelete = MockRecord(id: 2, name: "Encrypted Record 2", value: 1002)
        try encryptedDBManager.delete(recordToDelete)
        
        // Verify deletion
        let remainingRecords: [MockRecord] = try encryptedDBManager.fetch(of: MockRecord.self)
        XCTAssertEqual(remainingRecords.count, 1)
        XCTAssertEqual(remainingRecords.first?.name, "Updated Encrypted Record 1")
        
        // Clean up
        if fileManager.fileExists(atPath: encryptedDBURL.path) {
            try fileManager.removeItem(at: encryptedDBURL)
        }
    }
    
    // Test encrypted database with complex queries
    func testEncryptedDatabaseComplexQueries() throws {
        let fileManager = FileManager.default
        let docsDir = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let encryptedDBPath = "complex_query_encrypted_test.sqlite"
        let encryptedDBURL = docsDir.appendingPathComponent(encryptedDBPath)
        let passphrase = "ComplexQueryTestPassphrase789"
        
        // Clean up any existing test file
        if fileManager.fileExists(atPath: encryptedDBURL.path) {
            try fileManager.removeItem(at: encryptedDBURL)
        }
        
        // Create encrypted database manager with high security
        let encryptionOptions = EncryptionOptions.high(passphrase: passphrase)
        let encryptedDBManager = try FuseDatabaseManager(
            path: encryptedDBPath,
            encryptions: encryptionOptions
        )
        
        // Create MockRecord table
        let tableDefinition = FuseTableDefinition(
            name: MockRecord.databaseTableName,
            columns: [
                FuseColumnDefinition(name: "id", type: .integer, isPrimaryKey: true),
                FuseColumnDefinition(name: "name", type: .text, isNotNull: true),
                FuseColumnDefinition(name: "value", type: .integer, isNotNull: true)
            ],
            options: [.ifNotExists]
        )
        try encryptedDBManager.createTable(tableDefinition)
        
        // Add test data
        let testRecords = [
            MockRecord(id: 10, name: "Alpha", value: 100),
            MockRecord(id: 20, name: "Beta", value: 200),
            MockRecord(id: 30, name: "Gamma", value: 300),
            MockRecord(id: 40, name: "Delta", value: 150),
            MockRecord(id: 50, name: "Epsilon", value: 250)
        ]
        try encryptedDBManager.add(testRecords)
        
        // Test complex filtering
        let complexFilters = [
            FuseQueryFilter.greaterThan(field: "value", value: 150),
            FuseQueryFilter.lessThan(field: "value", value: 300)
        ]
        let filteredRecords: [MockRecord] = try encryptedDBManager.fetch(
            of: MockRecord.self,
            filters: complexFilters
        )
        XCTAssertEqual(filteredRecords.count, 2) // Beta (200) and Epsilon (250)
        
        // Test sorting with limit and offset
        let sortedRecords: [MockRecord] = try encryptedDBManager.fetch(
            of: MockRecord.self,
            sort: FuseQuerySort(field: "value", order: .ascending),
            limit: 3,
            offset: 1
        )
        XCTAssertEqual(sortedRecords.count, 3)
        XCTAssertEqual(sortedRecords[0].value, 150) // Delta (skip Alpha with 100)
        XCTAssertEqual(sortedRecords[1].value, 200) // Beta
        XCTAssertEqual(sortedRecords[2].value, 250) // Epsilon
        
        // Test batch operations
        let recordsToDelete = [
            MockRecord(id: 10, name: "Alpha", value: 100),
            MockRecord(id: 30, name: "Gamma", value: 300)
        ]
        try encryptedDBManager.delete(recordsToDelete)
        
        // Verify batch deletion
        let remainingRecords: [MockRecord] = try encryptedDBManager.fetch(of: MockRecord.self)
        XCTAssertEqual(remainingRecords.count, 3) // Should have Beta, Delta, Epsilon
        
        // Clean up
        if fileManager.fileExists(atPath: encryptedDBURL.path) {
            try fileManager.removeItem(at: encryptedDBURL)
        }
    }
    
    // Test encryption options configuration
    func testEncryptionOptionsConfiguration() throws {
        let passphrase = "ConfigTestPassphrase"
        let fileManager = FileManager.default
        let docsDir = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        
        // Test various encryption configurations
        let configurations = [
            ("standard", EncryptionOptions.standard(passphrase: passphrase)),
            ("high", EncryptionOptions.high(passphrase: passphrase)),
            ("performance", EncryptionOptions.performance(passphrase: passphrase)),
            ("custom", EncryptionOptions(passphrase)
                .pageSize(8192)
                .kdfIter(100_000)
                .memorySecurity(true)
                .defaultPageSize(8192)
                .defaultKdfIter(100_000)
            )
        ]
        
        for (configName, encryptionOptions) in configurations {
            let dbPath = "config_test_\(configName).sqlite"
            let dbURL = docsDir.appendingPathComponent(dbPath)
            
            // Clean up any existing file
            if fileManager.fileExists(atPath: dbURL.path) {
                try fileManager.removeItem(at: dbURL)
            }
            
            // Test database creation with each configuration
            XCTAssertNoThrow(try FuseDatabaseManager(
                path: dbPath,
                encryptions: encryptionOptions
            ), "Failed to create encrypted database with \(configName) configuration")
            
            // Verify file was created
            XCTAssertTrue(fileManager.fileExists(atPath: dbURL.path), 
                         "Database file should exist for \(configName) configuration")
            
            // Clean up
            if fileManager.fileExists(atPath: dbURL.path) {
                try fileManager.removeItem(at: dbURL)
            }
        }
    }
    
    // Test database reopening with different passphrases
    func testEncryptedDatabaseReopeningWithDifferentPassphrases() throws {
        let fileManager = FileManager.default
        let docsDir = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let encryptedDBPath = "reopen_test.sqlite"
        let encryptedDBURL = docsDir.appendingPathComponent(encryptedDBPath)
        let correctPassphrase = "CorrectPassphrase123"
        let wrongPassphrase = "WrongPassphrase456"
        
        // Clean up any existing test file
        if fileManager.fileExists(atPath: encryptedDBURL.path) {
            try fileManager.removeItem(at: encryptedDBURL)
        }
        
        // 1. Create encrypted database with correct passphrase
        do {
            let encryptionOptions = EncryptionOptions.standard(passphrase: correctPassphrase)
            let encryptedDBManager = try FuseDatabaseManager(
                path: encryptedDBPath,
                encryptions: encryptionOptions
            )
            
            // Create table and add data
            let tableDefinition = FuseTableDefinition(
                name: "test_table",
                columns: [
                    FuseColumnDefinition(name: "id", type: .integer, isPrimaryKey: true),
                    FuseColumnDefinition(name: "data", type: .text, isNotNull: true)
                ],
                options: [.ifNotExists]
            )
            try encryptedDBManager.createTable(tableDefinition)
            
            let insertQuery = FuseQuery(
                table: "test_table",
                action: .insert(values: ["id": 1, "data": "secret_data"])
            )
            try encryptedDBManager.write(insertQuery)
        }
        
        // 2. Try to open with wrong passphrase (should fail)
        XCTAssertThrowsError(try FuseDatabaseManager(
            path: encryptedDBPath,
            encryptions: EncryptionOptions.standard(passphrase: wrongPassphrase)
        ), "Opening encrypted database with wrong passphrase should fail")
        
        // 3. Open with correct passphrase and verify data integrity
        do {
            let reopenedDBManager = try FuseDatabaseManager(
                path: encryptedDBPath,
                encryptions: EncryptionOptions.standard(passphrase: correctPassphrase)
            )
            
            // Verify table exists
            let tableExists = try reopenedDBManager.tableExists("test_table")
            XCTAssertTrue(tableExists, "Table should exist in reopened encrypted database")
            
            // Verify data exists
            struct TestRecord: FuseDatabaseRecord {
                static var databaseTableName: String = "test_table"
                static var _fuseidField: String = "id"
                
                var id: Int64
                var data: String
                
                /// Table definition for this record type
                var tableDefinition: FuseTableDefinition {
                    return FuseTableDefinition(
                        name: Self.databaseTableName,
                        columns: [
                            FuseColumnDefinition(name: "id", type: .integer, isPrimaryKey: true),
                            FuseColumnDefinition(name: "data", type: .text, isNotNull: true)
                        ],
                        options: [.ifNotExists]
                    )
                }
            }
            
            let records: [TestRecord] = try reopenedDBManager.fetch(of: TestRecord.self)
            XCTAssertEqual(records.count, 1, "Should have one record in reopened database")
            XCTAssertEqual(records.first?.data, "secret_data", "Data should be intact after reopening")
        }
        
        // Clean up
        if fileManager.fileExists(atPath: encryptedDBURL.path) {
            try fileManager.removeItem(at: encryptedDBURL)
        }
    }

    func testValueFieldTypeConversion() throws {
        // Test that Int64 values are correctly stored and retrieved
        let record = MockRecord(id: 999, name: "Type Test", value: 12345)
        
        // Debug the default toDatabaseValues implementation
        let dbValues = record.toDatabaseValues()
        print("DEBUG: toDatabaseValues result: \(dbValues)")
        for (key, value) in dbValues {
            print("DEBUG: \(key) = \(value ?? "nil") (type: \(type(of: value)))")
        }
        
        XCTAssertEqual(dbValues["value"] as? Int64, 12345, "toDatabaseValues should preserve Int64 value")
        
        // Add to database
        try dbManager.add(record)
        
        // Fetch back
        let fetchedRecords: [MockRecord] = try dbManager.fetch(of: MockRecord.self, filters: [
            FuseQueryFilter.equals(field: "name", value: "Type Test")
        ])
        
        XCTAssertEqual(fetchedRecords.count, 1, "Should fetch exactly one record")
        XCTAssertEqual(fetchedRecords.first?.value, 12345, "Value should be preserved correctly")
        XCTAssertEqual(fetchedRecords.first?.name, "Type Test", "Name should be preserved correctly")
    }

    func testDefaultToDatabaseValuesImplementation() throws {
        // Test the default toDatabaseValues implementation
        let record = MockRecord(id: 1, name: "Test", value: 100)
        
        // This should work with the default implementation
        let dbValues = record.toDatabaseValues()
        
        // Check if all fields are present and have correct types
        XCTAssertNotNil(dbValues["id"] as Any?, "id field should be present")
        XCTAssertNotNil(dbValues["name"] as Any?, "name field should be present") 
        XCTAssertNotNil(dbValues["value"] as Any?, "value field should be present")
        
        // Check types
        XCTAssertTrue(dbValues["id"] is Int64, "id should be Int64")
        XCTAssertTrue(dbValues["name"] is String, "name should be String")
        XCTAssertTrue(dbValues["value"] is Int64, "value should be Int64")
        
        // Check values
        XCTAssertEqual(dbValues["id"] as? Int64, 1)
        XCTAssertEqual(dbValues["name"] as? String, "Test")
        XCTAssertEqual(dbValues["value"] as? Int64, 100)
    }

    func testDefaultFromDatabaseImplementation() throws {
        // Test that the default fromDatabase implementation works
        let record = MockRecord(id: 42, name: "Default Test", value: 999)
        
        // Add to database
        try dbManager.add(record)
        
        // Fetch back using the default implementation
        let fetchedRecords: [MockRecord] = try dbManager.fetch(of: MockRecord.self, filters: [
            FuseQueryFilter.equals(field: "name", value: "Default Test")
        ])
        
        XCTAssertEqual(fetchedRecords.count, 1, "Should fetch exactly one record")
        XCTAssertEqual(fetchedRecords.first?.id, 42, "ID should be preserved")
        XCTAssertEqual(fetchedRecords.first?.name, "Default Test", "Name should be preserved")
        XCTAssertEqual(fetchedRecords.first?.value, 999, "Value should be preserved")
    }

    func testDateDecodingIssue() throws {
        // Create a test record that mimics the Note structure to reproduce the date decoding issue
        struct NoteTestRecord: FuseDatabaseRecord {
            static var _fuseidField: String = "id"
            static var databaseTableName: String = "note_test_records"
            
            let id: String
            let title: String
            let content: String
            let createdAt: Date
            let hasAttachment: Bool
            let attachmentPath: String?
            
            init(id: String = UUID().uuidString, title: String, content: String, createdAt: Date = Date(), hasAttachment: Bool = false, attachmentPath: String? = nil) {
                self.id = id
                self.title = title
                self.content = content
                self.createdAt = createdAt
                self.hasAttachment = hasAttachment
                self.attachmentPath = attachmentPath
            }
            
            /// Table definition for this record type
            var tableDefinition: FuseTableDefinition {
                return FuseTableDefinition(
                    name: Self.databaseTableName,
                    columns: [
                        FuseColumnDefinition(name: "id", type: .text, isPrimaryKey: true, isNotNull: true),
                        FuseColumnDefinition(name: "title", type: .text, isNotNull: true),
                        FuseColumnDefinition(name: "content", type: .text, isNotNull: true),
                        FuseColumnDefinition(name: "createdAt", type: .date, isNotNull: true),
                        FuseColumnDefinition(name: "hasAttachment", type: .boolean, isNotNull: true),
                        FuseColumnDefinition(name: "attachmentPath", type: .text)
                    ],
                    options: [.ifNotExists]
                )
            }
        }
        
        // Create table for NoteTestRecord
        let noteTableDefinition = FuseTableDefinition(
            name: NoteTestRecord.databaseTableName,
            columns: [
                FuseColumnDefinition(name: "id", type: .text, isPrimaryKey: true, isNotNull: true),
                FuseColumnDefinition(name: "title", type: .text, isNotNull: true),
                FuseColumnDefinition(name: "content", type: .text, isNotNull: true),
                FuseColumnDefinition(name: "createdAt", type: .date, isNotNull: true),
                FuseColumnDefinition(name: "hasAttachment", type: .boolean, isNotNull: true),
                FuseColumnDefinition(name: "attachmentPath", type: .text)
            ],
            options: [.ifNotExists]
        )
        try dbManager.createTable(noteTableDefinition)
        
        // Create and add a test record with a specific date
        let testDate = Date(timeIntervalSince1970: 1678886400) // March 15, 2023, 8:00:00 AM UTC
        let testRecord = NoteTestRecord(
            id: "test-note-1",
            title: "Test Note",
            content: "This is a test note with a date",
            createdAt: testDate,
            hasAttachment: false,
            attachmentPath: nil
        )
        
        print("📝 Adding record with date: \(testDate)")
        print("   Timestamp: \(testDate.timeIntervalSince1970)")
        
        // This should use the default Codable implementation and might fail
        try dbManager.add(testRecord)
        print("✅ Record added successfully")
        
        // Try to fetch the record - this is where the "Cannot decode date" error should occur
        print("🔍 Attempting to fetch records...")
        let fetchedRecords: [NoteTestRecord] = try dbManager.fetch(of: NoteTestRecord.self)
        
        XCTAssertEqual(fetchedRecords.count, 1, "Should fetch one record")
        
        if let fetchedRecord = fetchedRecords.first {
            print("📖 Successfully fetched record:")
            print("   ID: \(fetchedRecord.id)")
            print("   Title: \(fetchedRecord.title)")
            print("   Created: \(fetchedRecord.createdAt)")
            print("   Timestamp: \(fetchedRecord.createdAt.timeIntervalSince1970)")
            
            // Verify the date is preserved correctly
            let timeDifference = abs(fetchedRecord.createdAt.timeIntervalSince1970 - testDate.timeIntervalSince1970)
            XCTAssertLessThan(timeDifference, 1.0, "Date should be preserved with reasonable precision")
            
            XCTAssertEqual(fetchedRecord.id, testRecord.id)
            XCTAssertEqual(fetchedRecord.title, testRecord.title)
            XCTAssertEqual(fetchedRecord.content, testRecord.content)
            XCTAssertEqual(fetchedRecord.hasAttachment, testRecord.hasAttachment)
            XCTAssertEqual(fetchedRecord.attachmentPath, testRecord.attachmentPath)
        }
    }

    func testSimpleDateHandling() throws {
        // Very simple test record with just a date
        struct SimpleDateRecord: FuseDatabaseRecord {
            static var _fuseidField: String = "id"
            static var databaseTableName: String = "simple_date_test"
            
            let id: String
            let testDate: Date
            
            init(id: String = UUID().uuidString, testDate: Date = Date()) {
                self.id = id
                self.testDate = testDate
            }
            
            /// Table definition for this record type
            var tableDefinition: FuseTableDefinition {
                return FuseTableDefinition(
                    name: Self.databaseTableName,
                    columns: [
                        FuseColumnDefinition(name: "id", type: .text, isPrimaryKey: true, isNotNull: true),
                        FuseColumnDefinition(name: "testDate", type: .date, isNotNull: true)
                    ],
                    options: [.ifNotExists]
                )
            }
        }
        
        // Create table
        let tableDefinition = FuseTableDefinition(
            name: SimpleDateRecord.databaseTableName,
            columns: [
                FuseColumnDefinition(name: "id", type: .text, isPrimaryKey: true, isNotNull: true),
                FuseColumnDefinition(name: "testDate", type: .date, isNotNull: true)
            ],
            options: [.ifNotExists]
        )
        try dbManager.createTable(tableDefinition)
        
        // Test with a known date
        let knownDate = Date(timeIntervalSince1970: 1678886400) // March 15, 2023
        let record = SimpleDateRecord(id: "test1", testDate: knownDate)
        
        print("🧪 Testing simple date handling...")
        print("   Original date: \(knownDate)")
        print("   Timestamp: \(knownDate.timeIntervalSince1970)")
        
        // Add record (this tests toDatabaseValues)
        try dbManager.add(record)
        print("✅ Record added successfully")
        
        // Fetch record (this tests fromDatabase)
        let fetchedRecords: [SimpleDateRecord] = try dbManager.fetch(of: SimpleDateRecord.self)
        print("✅ Records fetched: \(fetchedRecords.count)")
        
        XCTAssertEqual(fetchedRecords.count, 1, "Should have exactly one record")
        
        if let fetchedRecord = fetchedRecords.first {
            print("   Fetched date: \(fetchedRecord.testDate)")
            print("   Fetched timestamp: \(fetchedRecord.testDate.timeIntervalSince1970)")
            
            let timeDiff = abs(fetchedRecord.testDate.timeIntervalSince1970 - knownDate.timeIntervalSince1970)
            print("   Time difference: \(timeDiff) seconds")
            
            XCTAssertEqual(fetchedRecord.id, record.id, "ID should match")
            XCTAssertLessThan(timeDiff, 1.0, "Date should be preserved within 1 second precision")
        } else {
            XCTFail("Should have fetched a record")
        }
    }

    func testRealNoteModelDateHandling() throws {
        // Replicate the exact Note model structure from the example app
        struct TestNote: FuseDatabaseRecord {
            static var _fuseidField: String = "id"
            static var databaseTableName: String = "test_notes"
            
            var id: String
            var title: String
            var content: String
            var createdAt: Date
            var hasAttachment: Bool
            var attachmentPath: String?
            
            init(id: String = UUID().uuidString, 
                 title: String, 
                 content: String, 
                 createdAt: Date = Date(),
                 hasAttachment: Bool = false, 
                 attachmentPath: String? = nil) {
                self.id = id
                self.title = title
                self.content = content
                self.createdAt = createdAt
                self.hasAttachment = hasAttachment
                self.attachmentPath = attachmentPath
            }
            
            /// Table definition for this record type
            var tableDefinition: FuseTableDefinition {
                return FuseTableDefinition(
                    name: Self.databaseTableName,
                    columns: [
                        FuseColumnDefinition(name: "id", type: .text, isPrimaryKey: true, isNotNull: true),
                        FuseColumnDefinition(name: "title", type: .text, isNotNull: true),
                        FuseColumnDefinition(name: "content", type: .text, isNotNull: true),
                        FuseColumnDefinition(name: "createdAt", type: .date, isNotNull: true),
                        FuseColumnDefinition(name: "hasAttachment", type: .boolean, isNotNull: true, defaultValue: "0"),
                        FuseColumnDefinition(name: "attachmentPath", type: .text)
                    ]
                )
            }
        }
        
        // Create the exact table structure as the Note model
        let noteTableDefinition = FuseTableDefinition(
            name: TestNote.databaseTableName,
            columns: [
                FuseColumnDefinition(name: "id", type: .text, isPrimaryKey: true, isNotNull: true),
                FuseColumnDefinition(name: "title", type: .text, isNotNull: true),
                FuseColumnDefinition(name: "content", type: .text, isNotNull: true),
                FuseColumnDefinition(name: "createdAt", type: .date, isNotNull: true),
                FuseColumnDefinition(name: "hasAttachment", type: .boolean, isNotNull: true, defaultValue: "0"),
                FuseColumnDefinition(name: "attachmentPath", type: .text)
            ]
        )
        try dbManager.createTable(noteTableDefinition)
        
        // Create test data that mimics real app usage
        let testDate = Date() // Use current date like the real app
        let testNote = TestNote(
            id: "test-note-real",
            title: "真實測試筆記",
            content: "這是一個測試筆記，用來重現日期解碼問題",
            createdAt: testDate,
            hasAttachment: false,
            attachmentPath: nil
        )
        
        print("\n🧪 Testing real Note model structure...")
        print("   Note ID: \(testNote.id)")
        print("   Created At: \(testNote.createdAt)")
        print("   Timestamp: \(testNote.createdAt.timeIntervalSince1970)")
        
        // Step 1: Add the note (this tests toDatabaseValues)
        print("\n📝 Adding note to database...")
        try dbManager.add(testNote)
        print("✅ Note added successfully")
        
        // Step 2: Fetch the note (this tests fromDatabase - where the error occurs)
        print("\n🔍 Fetching notes from database...")
        let fetchedNotes: [TestNote] = try dbManager.fetch(of: TestNote.self)
        print("✅ Notes fetched successfully: \(fetchedNotes.count)")
        
        XCTAssertEqual(fetchedNotes.count, 1, "Should have exactly one note")
        
        if let fetchedNote = fetchedNotes.first {
            print("\n📖 Fetched note details:")
            print("   ID: \(fetchedNote.id)")
            print("   Title: \(fetchedNote.title)")
            print("   Content: \(fetchedNote.content)")
            print("   Created At: \(fetchedNote.createdAt)")
            print("   Has Attachment: \(fetchedNote.hasAttachment)")
            print("   Attachment Path: \(fetchedNote.attachmentPath ?? "nil")")
            
            // Verify all fields
            XCTAssertEqual(fetchedNote.id, testNote.id, "ID should match")
            XCTAssertEqual(fetchedNote.title, testNote.title, "Title should match")
            XCTAssertEqual(fetchedNote.content, testNote.content, "Content should match")
            XCTAssertEqual(fetchedNote.hasAttachment, testNote.hasAttachment, "HasAttachment should match")
            XCTAssertEqual(fetchedNote.attachmentPath, testNote.attachmentPath, "AttachmentPath should match")
            
            // Check date precision
            let timeDiff = abs(fetchedNote.createdAt.timeIntervalSince1970 - testNote.createdAt.timeIntervalSince1970)
            XCTAssertLessThan(timeDiff, 1.0, "Date should be preserved within 1 second precision")
        } else {
            XCTFail("Should have fetched a note")
        }
    }

    func testDebugGRDBDateStorage() throws {
        // Simple test record with just essential fields to isolate the problem
        struct DebugRecord: FuseDatabaseRecord {
            static var _fuseidField: String = "id"
            static var databaseTableName: String = "debug_records"
            
            let id: String
            let createdAt: Date
            
            init(id: String = UUID().uuidString, createdAt: Date = Date()) {
                self.id = id
                self.createdAt = createdAt
            }
            
            /// Table definition for this record type
            var tableDefinition: FuseTableDefinition {
                return FuseTableDefinition(
                    name: Self.databaseTableName,
                    columns: [
                        FuseColumnDefinition(name: "id", type: .text, isPrimaryKey: true, isNotNull: true),
                        FuseColumnDefinition(name: "createdAt", type: .date, isNotNull: true)
                    ],
                    options: [.ifNotExists]
                )
            }
        }
        
        // Create table
        let tableDefinition = FuseTableDefinition(
            name: DebugRecord.databaseTableName,
            columns: [
                FuseColumnDefinition(name: "id", type: .text, isPrimaryKey: true, isNotNull: true),
                FuseColumnDefinition(name: "createdAt", type: .date, isNotNull: true)
            ],
            options: [.ifNotExists]
        )
        try dbManager.createTable(tableDefinition)
        
        // Test with a specific known date
        let testDate = Date(timeIntervalSince1970: 1640995200) // Jan 1, 2022, 00:00:00 UTC
        let record = DebugRecord(id: "debug-1", createdAt: testDate)
        
        print("\n🔍 === DEBUGGING GRDB DATE STORAGE ===")
        print("Original record:")
        print("  ID: \(record.id)")
        print("  Date: \(record.createdAt)")
        print("  Timestamp: \(record.createdAt.timeIntervalSince1970)")
        
        // Test toDatabaseValues first
        let dbValues = record.toDatabaseValues()
        print("\ntoDatabaseValues result:")
        for (key, value) in dbValues {
            print("  \(key): \(value ?? "nil") (type: \(type(of: value)))")
        }
        
        // Add record to database
        try dbManager.add(record)
        print("\n✅ Record added to database")
        
        // Now let's manually inspect what's actually in the database
        print("\n🔍 Manually inspecting database content...")
        
        // Use the low-level read method to see raw data
        let rawRows = try dbManager.debugFetchRows("SELECT id, createdAt FROM \(DebugRecord.databaseTableName)")
        
        print("Raw database rows: \(rawRows.count)")
        for (index, row) in rawRows.enumerated() {
            print("  Row \(index):")
            print("    id: \(row["id"] ?? "nil")")
            print("    createdAt: \(row["createdAt"] ?? "nil")")
        }
        
        // Now try to fetch using our high-level method
        print("\n🔍 Attempting high-level fetch...")
        do {
            let fetchedRecords: [DebugRecord] = try dbManager.fetch(of: DebugRecord.self)
            print("✅ Successfully fetched \(fetchedRecords.count) records")
            
            for record in fetchedRecords {
                print("  Fetched record:")
                print("    ID: \(record.id)")
                print("    Date: \(record.createdAt)")
                print("    Timestamp: \(record.createdAt.timeIntervalSince1970)")
            }
        } catch {
            print("❌ High-level fetch failed: \(error)")
            
            // Let's see the detailed error
            if let decodingError = error as? DecodingError {
                switch decodingError {
                case .dataCorrupted(let context):
                    print("  Data corrupted: \(context.debugDescription)")
                    print("  Coding path: \(context.codingPath)")
                case .keyNotFound(let key, let context):
                    print("  Key not found: \(key)")
                    print("  Context: \(context.debugDescription)")
                case .typeMismatch(let type, let context):
                    print("  Type mismatch: expected \(type)")
                    print("  Context: \(context.debugDescription)")
                case .valueNotFound(let type, let context):
                    print("  Value not found: expected \(type)")
                    print("  Context: \(context.debugDescription)")
                @unknown default:
                    print("  Unknown decoding error: \(decodingError)")
                }
            }
            
            throw error
        }
    }

    func testGRDBNativeCodableSupport() throws {
        // Test record that uses GRDB's native Codable support directly
        struct NativeCodableRecord: FuseDatabaseRecord {
            static var _fuseidField: String = "id"
            static var databaseTableName: String = "native_codable_test"
            
            let id: String
            let title: String
            let content: String
            let createdAt: Date
            let hasAttachment: Bool
            let attachmentPath: String?
            
            init(id: String = UUID().uuidString, title: String, content: String, createdAt: Date = Date(), hasAttachment: Bool = false, attachmentPath: String? = nil) {
                self.id = id
                self.title = title
                self.content = content
                self.createdAt = createdAt
                self.hasAttachment = hasAttachment
                self.attachmentPath = attachmentPath
            }
            
            /// Table definition for this record type
            var tableDefinition: FuseTableDefinition {
                return FuseTableDefinition(
                    name: Self.databaseTableName,
                    columns: [
                        FuseColumnDefinition(name: "id", type: .text, isPrimaryKey: true, isNotNull: true),
                        FuseColumnDefinition(name: "title", type: .text, isNotNull: true),
                        FuseColumnDefinition(name: "content", type: .text, isNotNull: true),
                        FuseColumnDefinition(name: "createdAt", type: .date, isNotNull: true),
                        FuseColumnDefinition(name: "hasAttachment", type: .boolean, isNotNull: true),
                        FuseColumnDefinition(name: "attachmentPath", type: .text)
                    ],
                    options: [.ifNotExists]
                )
            }
        }
        
        // Create table
        let tableDefinition = FuseTableDefinition(
            name: NativeCodableRecord.databaseTableName,
            columns: [
                FuseColumnDefinition(name: "id", type: .text, isPrimaryKey: true, isNotNull: true),
                FuseColumnDefinition(name: "title", type: .text, isNotNull: true),
                FuseColumnDefinition(name: "content", type: .text, isNotNull: true),
                FuseColumnDefinition(name: "createdAt", type: .date, isNotNull: true),
                FuseColumnDefinition(name: "hasAttachment", type: .boolean, isNotNull: true),
                FuseColumnDefinition(name: "attachmentPath", type: .text)
            ],
            options: [.ifNotExists]
        )
        try dbManager.createTable(tableDefinition)
        
        // Create test record
        let testDate = Date(timeIntervalSince1970: 1678886400) // March 15, 2023
        let testRecord = NativeCodableRecord(
            id: "native-test-1",
            title: "Native GRDB Test",
            content: "Testing GRDB's native Codable support",
            createdAt: testDate,
            hasAttachment: true,
            attachmentPath: "/path/to/attachment"
        )
        
        print("\n🧪 Testing GRDB Native Codable Support...")
        print("   Original record:")
        print("     ID: \(testRecord.id)")
        print("     Title: \(testRecord.title)")
        print("     Created: \(testRecord.createdAt)")
        print("     Timestamp: \(testRecord.createdAt.timeIntervalSince1970)")
        print("     Has Attachment: \(testRecord.hasAttachment)")
        print("     Attachment Path: \(testRecord.attachmentPath ?? "nil")")
        
        // Add record using our SDK
        try dbManager.add(testRecord)
        print("✅ Record added successfully")
        
        // Fetch record using our SDK (this should use GRDB's native decoding)
        let fetchedRecords: [NativeCodableRecord] = try dbManager.fetch(of: NativeCodableRecord.self)
        print("✅ Records fetched: \(fetchedRecords.count)")
        
        XCTAssertEqual(fetchedRecords.count, 1, "Should have exactly one record")
        
        if let fetchedRecord = fetchedRecords.first {
            print("   Fetched record:")
            print("     ID: \(fetchedRecord.id)")
            print("     Title: \(fetchedRecord.title)")
            print("     Content: \(fetchedRecord.content)")
            print("     Created: \(fetchedRecord.createdAt)")
            print("     Timestamp: \(fetchedRecord.createdAt.timeIntervalSince1970)")
            print("     Has Attachment: \(fetchedRecord.hasAttachment)")
            print("     Attachment Path: \(fetchedRecord.attachmentPath ?? "nil")")
            
            // Verify all fields
            XCTAssertEqual(fetchedRecord.id, testRecord.id)
            XCTAssertEqual(fetchedRecord.title, testRecord.title)
            XCTAssertEqual(fetchedRecord.content, testRecord.content)
            XCTAssertEqual(fetchedRecord.hasAttachment, testRecord.hasAttachment)
            XCTAssertEqual(fetchedRecord.attachmentPath, testRecord.attachmentPath)
            
            // Verify date precision
            let timeDiff = abs(fetchedRecord.createdAt.timeIntervalSince1970 - testRecord.createdAt.timeIntervalSince1970)
            XCTAssertLessThan(timeDiff, 1.0, "Date should be preserved correctly with GRDB native support")
        } else {
            XCTFail("Should have fetched a record")
        }
    }
} 
