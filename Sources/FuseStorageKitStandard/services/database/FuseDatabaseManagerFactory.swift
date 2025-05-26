import Foundation
import FuseStorageCoreKit

/// Factory for creating standard GRDB database managers (no encryption)
public struct StandardDatabaseManagerFactory: FuseDatabaseManagerFactory {
    public init() {}
    
    public func createDatabaseManager(path: String, encryptions: EncryptionOptions?) throws -> FuseDatabaseManageable {
        return try FuseDatabaseManager(path: path, encryptions: encryptions)
    }
} 