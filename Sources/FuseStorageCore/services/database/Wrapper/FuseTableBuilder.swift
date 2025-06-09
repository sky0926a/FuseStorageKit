import Foundation

// MARK: - Table Builder Protocol
/// A protocol that abstracts table building operations
public protocol FuseTableBuilder {
    func column(_ name: String, _ type: String, isPrimaryKey: Bool, isNotNull: Bool, isUnique: Bool, defaultValue: FuseDatabaseValueConvertible?) throws
}
