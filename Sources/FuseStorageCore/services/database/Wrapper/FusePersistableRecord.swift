import Foundation

/// A protocol that abstracts persistable record operations
public protocol FusePersistableRecord {
    /// Converts the record to a dictionary of database values using tableDefinition
    /// - Returns: A dictionary mapping column names to their corresponding database values
    func toDatabaseValues() -> [String: FuseDatabaseValueConvertible?]
}

// Provide default implementation for FusePersistableRecord that requires tableDefinition
public extension FusePersistableRecord {
    /// Default implementation of toDatabaseValues using tableDefinition for type-safe conversion
    func toDatabaseValues() -> [String: FuseDatabaseValueConvertible?] {
        guard let recordType = Self.self as? any (FuseDatabaseBaseRecord.Type) else {
            fatalError("FusePersistableRecord must be used with FuseDatabaseRecord")
        }
        
        var values: [String: FuseDatabaseValueConvertible?] = [:]
        let mirror = Mirror(reflecting: self)
        let columnsByName = Dictionary(uniqueKeysWithValues: recordType.tableDefinition().columns.map { ($0.name, $0) })
        
        for child in mirror.children {
            guard let label = child.label,
                  let columnDef = columnsByName[label] else { continue }
            
            // Use column definition to handle type conversion properly
            values[label] = convertToFuseDatabaseValue(child.value, columnType: columnDef.type)
        }
        
        return values
    }
    
    /// Helper method to convert Swift values to database values based on column type
    private func convertToFuseDatabaseValue(_ value: Any, columnType: FuseColumnType) -> FuseDatabaseValueConvertible? {
        // Handle nil/NSNull first
        if value is NSNull {
            return NSNull()
        }
        func unwrap(_ x: Any) -> Any {
            let m = Mirror(reflecting: x)
            if m.displayStyle == .optional, let c = m.children.first { return unwrap(c.value) }
            return x
        }
        let u = unwrap(value)
        switch columnType {
        case .text:
            if let s = u as? String { return s }
            if let d = u as? Data { return d.base64EncodedString() }
            return String(describing: u)
        case .integer:
            if let i64 = u as? Int64 { return i64 }
            if let i = u as? Int { return Int64(i) }
            if let d = u as? Double { return Int64(d) }
            if let s = u as? String, let i64 = Int64(s) { return i64 }
            return nil
        case .real, .double:
            if let d = u as? Double { return d }
            if let f = u as? Float { return Double(f) }
            if let i = u as? Int { return Double(i) }
            if let s = u as? String, let d = Double(s) { return d }
            return nil
        case .numeric:
            if let d = u as? Double { return d }
            if let i = u as? Int { return Double(i) }
            if let s = u as? String, let d = Double(s) { return d }
            return nil
        case .boolean:
            if let b = u as? Bool { return b }
            if let i = u as? Int { return i != 0 }
            if let s = u as? String {
                let l = s.trimmingCharacters(in: .whitespaces).lowercased()
                if ["true","1","yes"].contains(l) { return true }
                if ["false","0","no"].contains(l) { return false }
            }
            return nil
        case .date:
            if let d = u as? Date { return d }
            if let ts = u as? TimeInterval { return Date(timeIntervalSince1970: ts) }
            if let i = u as? Int { return Date(timeIntervalSince1970: TimeInterval(i)) }
            if let s = u as? String, let d = FuseConstants.getDataFormatter().date(from: s) { return d }
            return nil
        case .blob:
            if let d = u as? Data { return d }
            if let s = u as? String, let data = Data(base64Encoded: s) { return data }
            if let s = u as? String, let data = s.data(using: .utf8) { return data }
            return nil
        case .any:
            if let c = u as? FuseDatabaseValueConvertible { return c }
            return String(describing: u)
        }
    }
}
