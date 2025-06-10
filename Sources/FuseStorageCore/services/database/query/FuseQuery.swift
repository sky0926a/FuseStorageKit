import Foundation

/// Represents a database query with its action and target table
public struct FuseQuery {
    /// The name of the table to query
    public let table: String
    /// The action to perform on the table
    public let action: FuseQueryAction

    /// Creates a new query
    /// - Parameters:
    ///   - table: The name of the table to query
    ///   - action: The action to perform
    public init(table: String, action: FuseQueryAction) {
        self.table = table
        self.action = action
    }

    /// Builds the SQL query and its parameters
    /// - Returns: A tuple containing the SQL query and its parameter values
    internal func build() -> (sql: String, args: [FuseDatabaseValueConvertible]) {
        switch action {
        case .select(let fields, let filters, let sort, let limit, let offset):
            var sql = "SELECT \(fields.joined(separator: ", ")) FROM \(table)"
            var args: [FuseDatabaseValueConvertible] = []
            if !filters.isEmpty {
                let parts = filters.map { f in f.build() }
                sql += " WHERE " + parts.map { $0.clause }.joined(separator: " AND ")
                args = parts.flatMap { $0.values }
            }
            if let s = sort {
                sql += " " + s.build()
            }
            if let limit = limit {
                sql += " LIMIT \(limit)"
            }
            if let offset = offset {
                sql += " OFFSET \(offset)"
            }
            return (sql, args)

        case .insert(let values):
            let sortedKeys = values.keys.sorted()
            let cols = sortedKeys.joined(separator: ", ")
            let placeholders = Array(repeating: "?", count: values.count).joined(separator: ", ")
            let sql = "INSERT INTO \(table) (\(cols)) VALUES (\(placeholders))"
            let args = sortedKeys.map { (values[$0] as? FuseDatabaseValueConvertible) ?? NSNull() }
            return (sql, args)

        case .insertMany(let manyValues):
            guard !manyValues.isEmpty else {
                return ("", [])
            }
            
            // 從所有記錄中找出所有可能的欄位
            let allKeys = Set(manyValues.flatMap { $0.keys }).sorted()
            let cols = allKeys.joined(separator: ", ")
            
            // 為每筆記錄創建值佔位符 (?, ?, ...)
            let valuePlaceholders = Array(repeating: "?", count: allKeys.count).joined(separator: ", ")
            let rowPlaceholders = Array(repeating: "(\(valuePlaceholders))", count: manyValues.count).joined(separator: ", ")
            
            let sql = "INSERT INTO \(table) (\(cols)) VALUES \(rowPlaceholders)"
            
            // 組裝所有參數，確保每筆記錄的欄位順序與 allKeys 一致
            var args: [FuseDatabaseValueConvertible] = []
            for values in manyValues {
                args.append(contentsOf: allKeys.map { values[$0] as? FuseDatabaseValueConvertible ?? NSNull() })
            }
            
            return (sql, args)

        case .update(let values, let filters):
            let sortedKeys = values.keys.sorted()
            let setClause = sortedKeys.map { "\($0) = ?" }.joined(separator: ", ")
            var sql = "UPDATE \(table) SET \(setClause)"
            var args = sortedKeys.map { (values[$0] as? FuseDatabaseValueConvertible) ?? NSNull() }
            if !filters.isEmpty {
                let parts = filters.map { f in f.build() }
                sql += " WHERE " + parts.map { $0.clause }.joined(separator: " AND ")
                args += parts.flatMap { $0.values }
            }
            return (sql, args)

        case .delete(let filters):
            var sql = "DELETE FROM \(table)"
            var args: [FuseDatabaseValueConvertible] = []
            if !filters.isEmpty {
                let parts = filters.map { f in f.build() }
                sql += " WHERE " + parts.map { $0.clause }.joined(separator: " AND ")
                args = parts.flatMap { $0.values }
            }
            return (sql, args)

        case .deleteMany(let field, let ids):
            let placeholders = Array(repeating: "?", count: ids.count).joined(separator: ", ")
            let sql = "DELETE FROM \(table) WHERE \(field) IN (\(placeholders))"
            let args = ids
            return (sql, args)

        case .upsert(let values, let conflictCols, let updateCols):
            let sortedValueKeys = values.keys.sorted()
            let cols = sortedValueKeys.joined(separator: ", ")
            let placeholders = Array(repeating: "?", count: values.count).joined(separator: ", ")
            let conflictList = conflictCols.joined(separator: ", ")
            
            let keysForUpdateClause: [String]
            if let specificUpdateCols = updateCols {
                keysForUpdateClause = specificUpdateCols.sorted()
            } else {
                keysForUpdateClause = values.keys.filter { !conflictCols.contains($0) }.sorted()
            }
            
            let updateList = keysForUpdateClause
                .map { "\($0) = excluded.\($0)" }
                .joined(separator: ", ")
                
            let sql = "INSERT INTO \(table) (\(cols)) VALUES (\(placeholders)) ON CONFLICT(\(conflictList)) DO UPDATE SET \(updateList)"
            let args = sortedValueKeys.map { (values[$0] as? FuseDatabaseValueConvertible) ?? NSNull() }
            return (sql, args)
        }
    }
}
