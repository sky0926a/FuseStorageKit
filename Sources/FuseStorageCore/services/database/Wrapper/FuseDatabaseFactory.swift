import Foundation
// MARK: - Database Factory
/// A protocol for creating database queues
public protocol FuseDatabaseFactory {
    func createDatabaseQueue(path: String, encryptionOptions: EncryptionOptions?) throws -> FuseDatabaseQueueProtocol
}
