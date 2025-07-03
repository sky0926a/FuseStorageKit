import Foundation

// MARK: - Database Row Protocol
/// A protocol that abstracts database row access
public protocol FuseDatabaseRow {
    subscript(columnName: String) -> Any? { get }
    
    /// Get all available column names in this row
    var columnNames: [String] { get }
}
