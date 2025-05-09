import XCTest
@testable import FuseStorageKit
import GRDB

// Mock record type for testing
struct MockRecord: FuseDatabaseRecord, Equatable {
    static var databaseTableName: String = "mock_records"
    static var _fuseidField: String = "id"

    var id: Int64?
    var name: String
    var value: Int

    init(id: Int64? = nil, name: String, value: Int) {
        self.id = id
        self.name = name
        self.value = value
    }

    func toDatabaseValues() -> [String : (any GRDB.DatabaseValueConvertible)?] {
        return ["id": id, "name": name, "value": value]
    }

    static func fromDatabase(row: Row) throws -> MockRecord {
        return MockRecord(
            id: row["id"],
            name: row["name"],
            value: row["value"]
        )
    }
}

class FuseDatabaseManagerTests: XCTestCase {

    var dbManager: FuseDatabaseManager!
    var dbQueue: DatabaseQueue!

    override func setUpWithError() throws {
        try super.setUpWithError()
        // Use an in-memory database for testing
        dbQueue = try DatabaseQueue()
        dbManager = FuseDatabaseManager(dbQueue: dbQueue)

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
        dbManager = nil
        dbQueue = nil
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
        let record = MockRecord(name: "Test Record 1", value: 100)
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
        let record1 = MockRecord(name: "Fetch Record 1", value: 10)
        let record2 = MockRecord(name: "Fetch Record 2", value: 20)
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
        var recordToDelete = MockRecord(name: "Delete Me", value: 555)
        try dbManager.add(recordToDelete)

        // Fetch to get the ID assigned by the database
        let recordsBeforeDelete: [MockRecord] = try dbManager.fetch(of: MockRecord.self, filters: [
            FuseQueryFilter.equals(field: "name", value: "Delete Me")
        ])
        XCTAssertEqual(recordsBeforeDelete.count, 1)
        recordToDelete.id = recordsBeforeDelete.first?.id // Assign the database-generated ID

        XCTAssertNotNil(recordToDelete.id, "Record ID should be set after fetching.")

        try dbManager.delete(recordToDelete)

        let recordsAfterDelete: [MockRecord] = try dbManager.fetch(of: MockRecord.self, filters: [
            FuseQueryFilter.equals(field: "name", value: "Delete Me")
        ])
        XCTAssertEqual(recordsAfterDelete.count, 0, "Record should be deleted.")
    }
    
    func testReadQuery() throws {
        let record1 = MockRecord(name: "Read Query 1", value: 101)
        let record2 = MockRecord(name: "Read Query 2", value: 102)
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
        guard let recordToUpdate = fetchedInsert.first, let recordId = recordToUpdate.id else {
            XCTFail("Failed to fetch record for update test")
            return
        }
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
} 
