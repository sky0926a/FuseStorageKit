import Foundation

/// A wrapper for statement arguments that can be used across different database implementations
public struct FuseStatementArguments: FuseStatementArgumentsProtocol {
    private let arguments: [(any FuseDatabaseValueConvertible)?]
    
    public init<S: Sequence>(_ arguments: S) where S.Element == (any FuseDatabaseValueConvertible)? {
        self.arguments = Array(arguments)
    }
    
    public func toGRDBArguments() -> Any {
        // Convert our abstract values to concrete database values
        return arguments.map { argument in
            if let arg = argument {
                return arg.fuseDatabaseValue
            } else {
                return NSNull()
            }
        }
    }
}
