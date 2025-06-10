import Foundation

/// Represents a field to sort by in database queries
public struct FuseSortField {
    /// The name of the field to sort by
    public let field: String
    /// The sort order to apply
    public let order: FuseQuerySortOrder

    /// Creates a new sort field
    /// - Parameters:
    ///   - field: The name of the field to sort by
    ///   - order: The sort order to apply
    public init(field: String, order: FuseQuerySortOrder) {
        self.field = field
        self.order = order
    }
}
