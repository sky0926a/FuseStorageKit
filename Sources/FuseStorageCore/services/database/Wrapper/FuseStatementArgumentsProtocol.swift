import Foundation

// MARK: - Statement Arguments Protocol
/// A protocol that abstracts statement arguments for database queries
public protocol FuseStatementArgumentsProtocol {
    init<S: Sequence>(_ arguments: S) where S.Element == (any FuseDatabaseValueConvertible)?
}
