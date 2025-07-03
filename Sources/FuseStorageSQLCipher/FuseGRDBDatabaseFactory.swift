internal import GRDB
import Foundation
@_exported import FuseStorageCore

// MARK: - Fsue GRDB Integration
class FuseGRDBDatabaseFactory: NSObject, FuseDatabaseFactory {
    override init() {
        super.init()
    }
    
    func createDatabaseQueue(path: String, encryptionOptions: EncryptionOptions?) throws -> FuseDatabaseQueueProtocol {
        var configuration = Configuration()
        if let encryptionOptions = encryptionOptions {
            configuration.prepareDatabase { db in
                if encryptionOptions.passphrase.isEmpty {
                    throw FuseDatabaseError.missingPassphrase
                }
                try Self.applyEncryptionOptions(encryptionOptions, to: db)
            }
        }
        let grdbQueue = try DatabaseQueue(path: path, configuration: configuration)
        return FuseGRDBDatabaseQueue(queue: grdbQueue)
    }
    
    private static func applyEncryptionOptions(_ options: EncryptionOptions, to db: Database) throws {
        try db.usePassphrase(options.passphrase)

        if let pageSize = options.pageSize {
            try db.execute(sql: "PRAGMA cipher_page_size = \(pageSize)")
        }
        if let kdfIter = options.kdfIter {
            try db.execute(sql: "PRAGMA kdf_iter = \(kdfIter)")
        }
        if options.memorySecurity == true {
            try db.execute(sql: "PRAGMA cipher_memory_security = ON")
        }
        if let defaultKdf = options.defaultKdfIter {
            try db.execute(sql: "PRAGMA cipher_default_kdf_iter = \(defaultKdf)")
        }
        if let defaultPage = options.defaultPageSize {
            try db.execute(sql: "PRAGMA cipher_default_page_size = \(defaultPage)")
        }
    }
}
