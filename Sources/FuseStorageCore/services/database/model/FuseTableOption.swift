import Foundation
import GRDB

/// Defines the available options for table creation
public struct FuseTableOptions: OptionSet {
    /// The raw value of the option set
    public let rawValue: Int
    
    /// Creates a new table options set
    /// - Parameter rawValue: The raw value for the option set
    public init(rawValue: Int) { self.rawValue = rawValue }
    
    /// Create the table only if it doesn't exist
    public static let ifNotExists = FuseTableOptions(rawValue: 1 << 0)
    /// Create a temporary table that exists only for the current session
    public static let temporary   = FuseTableOptions(rawValue: 1 << 1)
    /// Create a table without the rowid column
    public static let withoutRowID = FuseTableOptions(rawValue: 1 << 2)
    /// Create a table with strict type checking (available iOS 15.4+)
    @available(iOS 15.4, macOS 12.4, tvOS 15.4, watchOS 8.5, *)
    public static let strict      = FuseTableOptions(rawValue: 1 << 3)
}

/// Represents a complete table definition for database creation
public struct FuseTableDefinition {
    /// The name of the table
    public let name: String
    /// The columns in the table
    public let columns: [FuseColumnDefinition]
    /// The options to apply when creating the table
    public let options: FuseTableOptions

    /// Creates a new table definition
    /// - Parameters:
    ///   - name: The name of the table
    ///   - columns: The columns to include in the table
    ///   - options: The options to apply when creating the table
    public init(
        name: String,
        columns: [FuseColumnDefinition],
        options: FuseTableOptions = .ifNotExists
    ) {
        self.name    = name
        self.columns = columns
        self.options = options
    }
}
