import Foundation
import FuseStorageCoreKit

/// Factory for creating SQLCipher-enabled database managers
public struct SQLCipherDatabaseManagerFactory: FuseDatabaseManagerFactory {
    public init() {}
    
    public func createDatabaseManager(path: String, encryptions: EncryptionOptions?) throws -> FuseDatabaseManageable {
        return try FuseDatabaseManager(path: path, encryptions: encryptions)
    }
} 