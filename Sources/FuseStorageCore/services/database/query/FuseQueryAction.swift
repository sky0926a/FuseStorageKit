import Foundation

/// Defines the available query actions for database operations
public enum FuseQueryAction {
    /// Select records with optional filtering, sorting, and pagination
    case select(fields: [String], filters: [FuseQueryFilter], sort: FuseQuerySort?, limit: Int? = nil, offset: Int? = nil)
    /// Insert new records
    case insert(values: [String: FuseDatabaseValueConvertible?])
    /// Insert multiple records at once
    case insertMany(values: [[String: FuseDatabaseValueConvertible?]])
    /// Update existing records
    case update(values: [String: FuseDatabaseValueConvertible?], filters: [FuseQueryFilter])
    /// Delete records
    case delete(filters: [FuseQueryFilter])
    /// Delete multiple records by their IDs
    case deleteMany(field: String, ids: [FuseDatabaseValueConvertible])
    /// Insert or update records (UPSERT)
    case upsert(values: [String: FuseDatabaseValueConvertible?], conflict: [String], update: [String]?)
}
