import Foundation

/// Represents a sorting configuration for database queries
public struct FuseQuerySort {
    private let sortFields: [FuseSortField]
    
    /// Creates a sort configuration with a single field
    /// - Parameters:
    ///   - field: The name of the field to sort by
    ///   - order: The sort order to apply
    public init(field: String, order: FuseQuerySortOrder) {
        self.sortFields = [FuseSortField(field: field, order: order)]
    }
    
    /// Creates a sort configuration with multiple fields
    /// - Parameter sortFields: Array of fields to sort by
    public init(sortFields: [FuseSortField]) {
        self.sortFields = sortFields
    }

    /// Builds the SQL ORDER BY clause
    /// - Returns: The SQL ORDER BY clause
    internal func build() -> String {
        let sortClauses = sortFields.map { field in
            let dir = (field.order == .ascending ? "ASC" : "DESC")
            return "\(field.field) \(dir)"
        }
        return "ORDER BY " + sortClauses.joined(separator: ", ")
    }
}
