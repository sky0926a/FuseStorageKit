import Foundation

// MARK: - Database Connection Protocol
/// A protocol that abstracts database connection operations
public protocol FuseDatabaseConnection {
    func execute(sql: String, arguments: FuseStatementArguments) throws
    func tableExists(_ tableName: String) throws -> Bool
    func create(table: String, options: [String], body: (FuseTableBuilder) throws -> Void) throws
    func fetchAll<T: FuseFetchableRecord>(_ type: T.Type, sql: String, arguments: FuseStatementArguments) throws -> [T]
    func fetchRows(sql: String, arguments: FuseStatementArguments) throws -> [FuseDatabaseRow]
}
