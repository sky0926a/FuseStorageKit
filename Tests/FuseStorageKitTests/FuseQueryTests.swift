import XCTest
@testable import FuseStorageKit // Assuming your module is named FuseStorageKit
import GRDB // For DatabaseValueConvertible

// Helper to compare DatabaseValueConvertible arrays
// This is needed because DatabaseValueConvertible is a protocol, and direct comparison of arrays of protocol types might not work as expected.
// We compare the underlying database values.
func XCTAssertEqualDBValues(_ expression1: [DatabaseValueConvertible], _ expression2: [DatabaseValueConvertible], _ message: @autoclosure () -> String = "", file: StaticString = #filePath, line: UInt = #line) {
    XCTAssertEqual(expression1.count, expression2.count, "Array counts differ. \(message())", file: file, line: line)
    for (v1, v2) in zip(expression1, expression2) {
        // Comparing the 'databaseValue' property which gives a storable representation.
        XCTAssertEqual(v1.databaseValue, v2.databaseValue, "Values differ: \(v1.databaseValue) vs \(v2.databaseValue). \(message())", file: file, line: line)
    }
}

class FuseQueryFilterTests: XCTestCase {

    func testBuildEquals() {
        let filter = FuseQueryFilter.equals(field: "name", value: "Alice")
        let (clause, values) = filter.build()
        XCTAssertEqual(clause, "name = ?")
        XCTAssertEqualDBValues(values, ["Alice"])
    }

    func testBuildNotEquals() {
        let filter = FuseQueryFilter.notEquals(field: "age", value: 30)
        let (clause, values) = filter.build()
        XCTAssertEqual(clause, "age != ?")
        XCTAssertEqualDBValues(values, [30])
    }

    func testBuildLike() {
        let filter = FuseQueryFilter.like(field: "email", value: "%example.com%")
        let (clause, values) = filter.build()
        XCTAssertEqual(clause, "email LIKE ?")
        XCTAssertEqualDBValues(values, ["%example.com%"])
    }

    func testBuildGreaterThan() {
        let filter = FuseQueryFilter.greaterThan(field: "score", value: 100.5)
        let (clause, values) = filter.build()
        XCTAssertEqual(clause, "score > ?")
        XCTAssertEqualDBValues(values, [100.5])
    }

    func testBuildLessThan() {
        let dateValue = Date(timeIntervalSince1970: 1678886400) // March 15, 2023
        let filter = FuseQueryFilter.lessThan(field: "createdAt", value: dateValue)
        let (clause, values) = filter.build()
        XCTAssertEqual(clause, "createdAt < ?")
        XCTAssertEqualDBValues(values, [dateValue])
    }

    func testBuildInSet() {
        let filter = FuseQueryFilter.inSet(field: "id", values: [1, 2, 3])
        let (clause, values) = filter.build()
        XCTAssertEqual(clause, "id IN (?, ?, ?)")
        XCTAssertEqualDBValues(values, [1, 2, 3])
    }

    func testBuildInSetEmpty() {
        let filter = FuseQueryFilter.inSet(field: "status", values: [])
        let (clause, values) = filter.build()
        XCTAssertEqual(clause, "1=0") // SQL standard for IN with empty set is to always be false
        XCTAssertTrue(values.isEmpty)
    }
}

class FuseQuerySortTests: XCTestCase {

    func testBuildSingleFieldAscending() {
        let sort = FuseQuerySort(field: "name", order: .ascending)
        let clause = sort.build()
        XCTAssertEqual(clause, "ORDER BY name ASC")
    }

    func testBuildSingleFieldDescending() {
        let sort = FuseQuerySort(field: "age", order: .descending)
        let clause = sort.build()
        XCTAssertEqual(clause, "ORDER BY age DESC")
    }

    func testBuildMultipleFields() {
        let sortFields = [
            FuseSortField(field: "lastName", order: .ascending),
            FuseSortField(field: "firstName", order: .ascending)
        ]
        let sort = FuseQuerySort(sortFields: sortFields)
        let clause = sort.build()
        XCTAssertEqual(clause, "ORDER BY lastName ASC, firstName ASC")
    }

    func testBuildMultipleFieldsMixedOrder() {
        let sortFields = [
            FuseSortField(field: "category", order: .ascending),
            FuseSortField(field: "priority", order: .descending)
        ]
        let sort = FuseQuerySort(sortFields: sortFields)
        let clause = sort.build()
        XCTAssertEqual(clause, "ORDER BY category ASC, priority DESC")
    }
}

// Assuming FuseDatabaseValueConvertible is effectively DatabaseValueConvertible for testing purposes
typealias FuseDatabaseValueConvertible = GRDB.DatabaseValueConvertible 

class FuseQueryTests: XCTestCase {

    func testBuildSelectAll() {
        let query = FuseQuery(table: "users", action: .select(fields: ["*"], filters: [], sort: nil))
        let (sql, args) = query.build()
        XCTAssertEqual(sql, "SELECT * FROM users")
        XCTAssertTrue(args.isEmpty)
    }

    func testBuildSelectSpecificFields() {
        let query = FuseQuery(table: "products", action: .select(fields: ["id", "name", "price"], filters: [], sort: nil))
        let (sql, args) = query.build()
        XCTAssertEqual(sql, "SELECT id, name, price FROM products")
        XCTAssertTrue(args.isEmpty)
    }

    func testBuildSelectWithSingleFilter() {
        let filter = FuseQueryFilter.equals(field: "category", value: "electronics")
        let query = FuseQuery(table: "products", action: .select(fields: ["name"], filters: [filter], sort: nil))
        let (sql, args) = query.build()
        XCTAssertEqual(sql, "SELECT name FROM products WHERE category = ?")
        XCTAssertEqualDBValues(args, ["electronics"])
    }

    func testBuildSelectWithMultipleFilters() {
        let filter1 = FuseQueryFilter.equals(field: "category", value: "books")
        let filter2 = FuseQueryFilter.greaterThan(field: "price", value: 20.0)
        let query = FuseQuery(table: "items", action: .select(fields: ["*"], filters: [filter1, filter2], sort: nil))
        let (sql, args) = query.build()
        XCTAssertEqual(sql, "SELECT * FROM items WHERE category = ? AND price > ?")
        XCTAssertEqualDBValues(args, ["books", 20.0])
    }

    func testBuildSelectWithSort() {
        let sort = FuseQuerySort(field: "name", order: .ascending)
        let query = FuseQuery(table: "customers", action: .select(fields: ["id", "name"], filters: [], sort: sort))
        let (sql, args) = query.build()
        XCTAssertEqual(sql, "SELECT id, name FROM customers ORDER BY name ASC")
        XCTAssertTrue(args.isEmpty)
    }

    func testBuildSelectWithLimit() {
        let query = FuseQuery(table: "logs", action: .select(fields: ["message"], filters: [], sort: nil, limit: 10))
        let (sql, args) = query.build()
        XCTAssertEqual(sql, "SELECT message FROM logs LIMIT 10")
        XCTAssertTrue(args.isEmpty)
    }

    func testBuildSelectWithOffset() {
        let query = FuseQuery(table: "articles", action: .select(fields: ["title"], filters: [], sort: nil, offset: 5))
        let (sql, args) = query.build()
        XCTAssertEqual(sql, "SELECT title FROM articles OFFSET 5")
        XCTAssertTrue(args.isEmpty)
    }

    func testBuildSelectWithLimitAndOffset() {
        let query = FuseQuery(table: "comments", action: .select(fields: ["text"], filters: [], sort: nil, limit: 10, offset: 20))
        let (sql, args) = query.build()
        XCTAssertEqual(sql, "SELECT text FROM comments LIMIT 10 OFFSET 20")
        XCTAssertTrue(args.isEmpty)
    }
    
    func testBuildSelectComplex() {
        let filters = [
            FuseQueryFilter.like(field: "author", value: "%John%"),
            FuseQueryFilter.greaterThan(field: "views", value: 1000)
        ]
        let sort = FuseQuerySort(sortFields: [
            FuseSortField(field: "createdAt", order: .descending),
            FuseSortField(field: "title", order: .ascending)
        ])
        let query = FuseQuery(table: "posts", action: .select(fields: ["title", "author"], filters: filters, sort: sort, limit: 5, offset: 10))
        let (sql, args) = query.build()
        XCTAssertEqual(sql, "SELECT title, author FROM posts WHERE author LIKE ? AND views > ? ORDER BY createdAt DESC, title ASC LIMIT 5 OFFSET 10")
        XCTAssertEqualDBValues(args, ["%John%", 1000])
    }

    func testBuildInsert() {
        // Use the initial, potentially unordered dictionary
        let initialValues: [String: FuseDatabaseValueConvertible?] = ["name": "Bob", "age": 25, "email": "bob@example.com"]
        
        // Pass the initialValues directly to FuseQuery; build() is responsible for internal sorting.
        let query = FuseQuery(table: "users", action: .insert(values: initialValues))
        let (sql, args) = query.build()
        
        // For expectation, sort the keys of the initialValues dictionary.
        let expectedSortedKeys = initialValues.keys.sorted() 
        let expectedSQL = "INSERT INTO users (\(expectedSortedKeys.joined(separator: ", "))) VALUES (?, ?, ?)"
        let expectedArgs: [DatabaseValueConvertible] = expectedSortedKeys.map { (initialValues[$0]!) ?? NSNull() }

        XCTAssertEqual(sql, expectedSQL)
        XCTAssertEqualDBValues(args, expectedArgs)
    }
    
    func testBuildInsertWithNil() {
        // Use the initial, potentially unordered dictionary
        let initialValues: [String: FuseDatabaseValueConvertible?] = ["name": "Charlie", "manager_id": nil]

        // Pass the initialValues directly to FuseQuery; build() is responsible for internal sorting.
        let query = FuseQuery(table: "employees", action: .insert(values: initialValues))
        let (sql, args) = query.build()

        // For expectation, sort the keys of the initialValues dictionary.
        let expectedSortedKeys = initialValues.keys.sorted()
        let expectedSQL = "INSERT INTO employees (\(expectedSortedKeys.joined(separator: ", "))) VALUES (?, ?)"
        let expectedArgs: [DatabaseValueConvertible] = expectedSortedKeys.map { (initialValues[$0]!) ?? NSNull() }
        
        XCTAssertEqual(sql, expectedSQL)
        XCTAssertEqualDBValues(args, expectedArgs)
    }

    func testBuildUpdate() {
        let initialValues: [String: FuseDatabaseValueConvertible?] = ["status": "archived", "updatedAt": Date(timeIntervalSince1970: 1678886400)]
        let filters = [FuseQueryFilter.equals(field: "id", value: "uuid-123")]
                
        let query = FuseQuery(table: "tasks", action: .update(values: initialValues, filters: filters))
        let (sql, args) = query.build()
        
        let expectedSortedKeys = initialValues.keys.sorted()
        let setClauses = expectedSortedKeys.map { "\($0) = ?" }.joined(separator: ", ")
        let expectedSQL = "UPDATE tasks SET \(setClauses) WHERE id = ?"
        
        let expectedArgsPrefix: [DatabaseValueConvertible] = expectedSortedKeys.map { (initialValues[$0]!) ?? NSNull() }
        let expectedArgs = expectedArgsPrefix + ["uuid-123" as DatabaseValueConvertible]

        XCTAssertEqual(sql, expectedSQL)
        XCTAssertEqualDBValues(args, expectedArgs)
    }

    func testBuildUpdateNoFilters() {
        // Update without WHERE is generally dangerous, but the builder should support it.
        // The responsibility for caution lies with the caller.
        let values: [String: FuseDatabaseValueConvertible?] = ["is_active": false] // Dictionary with one item, order is fixed.
        let query = FuseQuery(table: "accounts", action: .update(values: values, filters: []))
        let (sql, args) = query.build()
        XCTAssertEqual(sql, "UPDATE accounts SET is_active = ?")
        XCTAssertEqualDBValues(args, [false])
    }

    func testBuildDelete() {
        let dateValue = Date(timeIntervalSince1970: 1578886400) // Jan 13, 2020
        let filters = [FuseQueryFilter.lessThan(field: "lastLogin", value: dateValue)]
        let query = FuseQuery(table: "sessions", action: .delete(filters: filters))
        let (sql, args) = query.build()
        XCTAssertEqual(sql, "DELETE FROM sessions WHERE lastLogin < ?")
        XCTAssertEqualDBValues(args, [dateValue])
    }

    func testBuildDeleteAll() {
        // Delete without WHERE is generally dangerous, but the builder should support it.
        let query = FuseQuery(table: "temp_data", action: .delete(filters: []))
        let (sql, args) = query.build()
        XCTAssertEqual(sql, "DELETE FROM temp_data")
        XCTAssertTrue(args.isEmpty)
    }
    
    func testBuildUpsertAllFieldsUpdate() {
        let initialValues: [String: FuseDatabaseValueConvertible?] = ["id": 1, "name": "Product A", "stock": 100]
        let conflictCols = ["id"]
        
        let query = FuseQuery(table: "inventory", action: .upsert(values: initialValues, conflict: conflictCols, update: nil))
        let (sql, args) = query.build()

        let expectedSortedValueKeys = initialValues.keys.sorted()
        let cols = expectedSortedValueKeys.joined(separator: ", ")
        let placeholders = Array(repeating: "?", count: initialValues.count).joined(separator: ", ")
        let conflictList = conflictCols.joined(separator: ", ") // Order from array is stable
        
        let expectedUpdateColsKeys = initialValues.keys.filter { !conflictCols.contains($0) }.sorted()
        let expectedUpdateClause = expectedUpdateColsKeys
            .map { "\($0) = excluded.\($0)" }
            .joined(separator: ", ")

        let expectedSQL = "INSERT INTO inventory (\(cols)) VALUES (\(placeholders)) ON CONFLICT(\(conflictList)) DO UPDATE SET \(expectedUpdateClause)"
        let expectedArgs: [DatabaseValueConvertible] = expectedSortedValueKeys.map { (initialValues[$0]!) ?? NSNull() }

        XCTAssertEqual(sql, expectedSQL)
        XCTAssertEqualDBValues(args, expectedArgs)
    }

    func testBuildUpsertSpecificFieldsUpdate() {
        let initialValues: [String: FuseDatabaseValueConvertible?] = ["id": "sku123", "price": 29.99, "last_updated": "2023-03-15"]
        let conflictCols = ["id"]
        let updateCols = ["price"] // User-specified update columns

        let query = FuseQuery(table: "catalog", action: .upsert(values: initialValues, conflict: conflictCols, update: updateCols))
        let (sql, args) = query.build()
        
        let expectedSortedValueKeys = initialValues.keys.sorted()
        let cols = expectedSortedValueKeys.joined(separator: ", ")
        let placeholders = Array(repeating: "?", count: initialValues.count).joined(separator: ", ")
        let conflictList = conflictCols.joined(separator: ", ")
        
        // As per FuseQuery.build(), if updateCols is provided, it's sorted and used.
        let expectedUpdateClause = updateCols.sorted().map { "\($0) = excluded.\($0)" }.joined(separator: ", ")

        let expectedSQL = "INSERT INTO catalog (\(cols)) VALUES (\(placeholders)) ON CONFLICT(\(conflictList)) DO UPDATE SET \(expectedUpdateClause)"
        let expectedArgs: [DatabaseValueConvertible] = expectedSortedValueKeys.map { (initialValues[$0]!) ?? NSNull() }

        XCTAssertEqual(sql, expectedSQL)
        XCTAssertEqualDBValues(args, expectedArgs)
    }
    
    func testBuildUpsertNoSpecificUpdateFieldsProvidedSameAsAllFields() {
        let initialValues: [String: FuseDatabaseValueConvertible?] = ["key": "configA", "value": "true", "description": "Feature flag A"]
        let conflictCols = ["key"]
        
        let query = FuseQuery(table: "settings", action: .upsert(values: initialValues, conflict: conflictCols, update: nil))
        let (sql, args) = query.build()

        let expectedSortedValueKeys = initialValues.keys.sorted()
        let cols = expectedSortedValueKeys.joined(separator: ", ")
        let placeholders = Array(repeating: "?", count: initialValues.count).joined(separator: ", ")
        let conflictList = conflictCols.joined(separator: ", ")
        
        let expectedUpdateColsKeys = initialValues.keys.filter { !conflictCols.contains($0) }.sorted()
        let expectedUpdateClause = expectedUpdateColsKeys
            .map { "\($0) = excluded.\($0)" }
            .joined(separator: ", ")

        let expectedSQL = "INSERT INTO settings (\(cols)) VALUES (\(placeholders)) ON CONFLICT(\(conflictList)) DO UPDATE SET \(expectedUpdateClause)"
        let expectedArgs: [DatabaseValueConvertible] = expectedSortedValueKeys.map { (initialValues[$0]!) ?? NSNull() }

        XCTAssertEqual(sql, expectedSQL)
        XCTAssertEqualDBValues(args, expectedArgs)
    }
} 