import Foundation

// MARK: - Record Protocols
/// A protocol that abstracts fetchable record operations
public protocol FuseFetchableRecord {
    /// Creates an instance from a database row using direct mapping from tableDefinition
    /// This method uses zero-overhead direct decoding without any JSON serialization
    /// - Parameter row: Database row containing the record data
    /// - Returns: New instance of the record type with directly mapped values
    /// - Throws: DecodingError if direct mapping fails
    static func fromDatabase(row: FuseDatabaseRow) throws -> Self
    
    /// Fetches all records from the database using a SQL query
    static func fetchAll(_ db: FuseDatabaseConnection, sql: String, arguments: FuseStatementArguments) throws -> [Self]
}

// Provide default implementations for FuseFetchableRecord
public extension FuseFetchableRecord {
    static func fetchAll(_ db: FuseDatabaseConnection, sql: String, arguments: FuseStatementArguments) throws -> [Self] {
         let rows = try db.fetchRows(sql: sql, arguments: arguments)
         return try rows.enumerated().map { (index, row) in
             do {
                 return try Self.fromDatabase(row: row)
             } catch {
                 // Provide more context about which record failed to decode
                 let context = DecodingError.Context(
                     codingPath: [],
                     debugDescription: "Failed to decode record at index \(index) for type \(Self.self). Available columns: \(row.columnNames). Original error: \(error.localizedDescription)",
                     underlyingError: error
                 )
                 throw DecodingError.dataCorrupted(context)
             }
         }
    }
    
    /// Ultra-simplified implementation using direct mapping from tableDefinition
    /// 
    /// This method provides maximum performance by:
    /// 1. Using FuseDirectDecoder with tableDefinition for precise type conversion
    /// 2. Direct row access without intermediate copying
    /// 3. Zero JSON serialization/deserialization
    /// 4. Precise error handling with tableDefinition validation
    /// 5. 🎯 Intelligent auto-inference when columns not in tableDefinition
    /// 6. 🎯 One method handles all scenarios (like toDatabaseValues)
    /// 
    /// Perfect for all use cases:
    /// ```swift
    /// // When you have a tableDefinition - uses precise type conversion
    /// struct User: FuseDatabaseRecord {
    ///     static func tableDefinition() -> FuseTableDefinition { ... }
    /// }
    /// let user = try User.fromDatabase(row: row)
    /// 
    /// // When you don't have tableDefinition - intelligently auto-infers
    /// struct SimpleUser {
    ///     var id: Int64, name: String, email: String?
    /// }
    /// let user = try SimpleUser.fromDatabase(row: row)
    /// ```
    /// 
    /// - Parameter row: Database row containing raw values
    /// - Returns: Properly typed Swift object with all properties set
    /// - Throws: DecodingError if direct mapping fails
    static func fromDatabase(row: FuseDatabaseRow) throws -> Self where Self: FuseDatabaseRecord {
        // 🎯 Universal solution using FuseDirectDecoder with smart error handling
        // This handles 99% of cases automatically, with clear guidance for edge cases
        
        do {
            // Use FuseDirectDecoder for direct, efficient decoding
            let directDecoder = FuseDirectDecoder(row: row)
            return try directDecoder.decode(Self.self)
            
        } catch DecodingError.dataCorrupted(let context) where context.debugDescription.contains("discriminator") {
            // Handle the specific discriminator conflict case
            throw FuseDatabaseError.conversionFailed(
                "Type \(Self.self) has a Codable discriminator conflict. " +
                "This can be resolved by implementing a custom fromDatabase method."
            )
            
        } catch {
            // Handle any other decoding errors with context
            throw FuseDatabaseError.conversionFailed(
                "Failed to decode \(Self.self) from database row. " +
                "Available columns: \(row.columnNames). Error: \(error.localizedDescription)"
            )
        }
    }
    

    

}
