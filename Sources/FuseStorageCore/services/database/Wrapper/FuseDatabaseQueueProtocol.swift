import Foundation

// MARK: - Database Queue Protocol
/// A protocol that abstracts database queue operations
public protocol FuseDatabaseQueueProtocol {
    func read<T>(_ block: @escaping (FuseDatabaseConnection) throws -> T) throws -> T
    func write<T>(_ block: @escaping (FuseDatabaseConnection) throws -> T) throws -> T
}
