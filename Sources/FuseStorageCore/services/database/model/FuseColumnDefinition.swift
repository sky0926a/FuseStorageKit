import Foundation

/// Represents a column definition in a database table
public struct FuseColumnDefinition {
    /// The name of the column
    public let name: String
    /// The data type of the column
    public let type: FuseColumnType
    /// Whether this column is a primary key
    public let isPrimaryKey: Bool
    /// Whether this column cannot contain null values
    public let isNotNull: Bool
    /// Whether this column must contain unique values
    public let isUnique: Bool
    /// The default value for this column, if any
    public let defaultValue: FuseDatabaseValueConvertible?
    
    /// Creates a new column definition
    /// - Parameters:
    ///   - name: The name of the column
    ///   - type: The data type of the column
    ///   - isPrimaryKey: Whether this column is a primary key
    ///   - isNotNull: Whether this column cannot contain null values
    ///   - isUnique: Whether this column must contain unique values
    ///   - defaultValue: The default value for this column
    public init(
        name: String,
        type: FuseColumnType,
        isPrimaryKey: Bool = false,
        isNotNull: Bool = false,
        isUnique: Bool = false,
        defaultValue: FuseDatabaseValueConvertible? = nil
    ) {
        self.name        = name
        self.type        = type
        self.isPrimaryKey = isPrimaryKey
        self.isNotNull   = isNotNull
        self.isUnique    = isUnique
        self.defaultValue = defaultValue
    }
}
