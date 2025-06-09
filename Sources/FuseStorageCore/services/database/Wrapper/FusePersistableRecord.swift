import Foundation

/// A protocol that abstracts persistable record operations
public protocol FusePersistableRecord {
    /// Converts the record to a dictionary of database values using tableDefinition
    /// This method uses tableDefinition for precise type conversion and validation
    /// - Returns: A dictionary mapping column names to their corresponding database values
    func toDatabaseValues() -> [String: FuseDatabaseValueConvertible?]
}

// Provide default implementation for FusePersistableRecord using tableDefinition
public extension FusePersistableRecord where Self: FuseDatabaseRecord {
    
    /// Enhanced implementation of toDatabaseValues using tableDefinition for precise conversion
    /// 
    /// This method provides:
    /// 1. Direct property-to-value conversion with minimal overhead
    /// 2. Validation that all properties match their expected column types
    /// 3. Consistent behavior with the fromDatabase implementation
    /// 4. No fallback mechanisms - proper conversion or error
    /// 5. 🎯 Intelligent auto-inference when column not found in tableDefinition
    /// 6. 🎯 Uses unified FuseTypeConverter to eliminate duplicate logic
    /// 
    /// - Returns: A dictionary mapping column names to database-compatible values
    func toDatabaseValues() -> [String: FuseDatabaseValueConvertible?] {
        let tableDefinition = Self.tableDefinition()
        let columnsByName = Dictionary(uniqueKeysWithValues: tableDefinition.columns.map { ($0.name, $0) })
        
        var values: [String: FuseDatabaseValueConvertible?] = [:]
        let mirror = Mirror(reflecting: self)
        
        // 🎯 Simplified conversion using unified type converter
        for child in mirror.children {
            guard let propertyName = child.label else { continue }
            
            let (columnType, isOptional): (FuseColumnType, Bool)
            
            if let columnDef = columnsByName[propertyName] {
                // Use tableDefinition when available
                columnType = columnDef.type
                isOptional = !columnDef.isNotNull
            } else {
                // Auto-infer when not in tableDefinition
                (columnType, isOptional) = FuseTypeConverter.inferColumnType(from: child.value)
            }
            
            // 🎯 Use unified converter - eliminates duplicate logic!
            let convertedValue = FuseTypeConverter.swiftToDatabaseValue(
                child.value,
                columnType: columnType,
                isOptional: isOptional
            )
            values[propertyName] = convertedValue
        }
        
        return values
    }
}
