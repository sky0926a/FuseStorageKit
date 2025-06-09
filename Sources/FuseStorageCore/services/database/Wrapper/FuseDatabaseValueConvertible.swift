import Foundation

// MARK: - Database Value Protocols
/// A protocol that abstracts database value conversion without depending on specific database implementations
public protocol FuseDatabaseValueConvertible {
    /// Convert this value to a database-compatible representation
    var fuseDatabaseValue: Any { get }
}

// Make standard types conform to our protocol
extension String: FuseDatabaseValueConvertible {
    public var fuseDatabaseValue: Any { return self }
}

extension Int: FuseDatabaseValueConvertible {
    public var fuseDatabaseValue: Any { return self }
}

extension Int64: FuseDatabaseValueConvertible {
    public var fuseDatabaseValue: Any { return self }
}

extension Double: FuseDatabaseValueConvertible {
    public var fuseDatabaseValue: Any { return self }
}

extension Bool: FuseDatabaseValueConvertible {
    public var fuseDatabaseValue: Any { return self }
}

extension Date: FuseDatabaseValueConvertible {
    public var fuseDatabaseValue: Any { return self }
}

extension Data: FuseDatabaseValueConvertible {
    public var fuseDatabaseValue: Any { return self }
}

extension NSNull: FuseDatabaseValueConvertible {
    public var fuseDatabaseValue: Any { return self }
}

extension Optional: FuseDatabaseValueConvertible where Wrapped: FuseDatabaseValueConvertible {
    public var fuseDatabaseValue: Any {
        switch self {
        case .none:
            return NSNull()
        case .some(let wrapped):
            return wrapped.fuseDatabaseValue
        }
    }
}

// Make Array conform to FuseDatabaseValueConvertible by converting to JSON string
extension Array: FuseDatabaseValueConvertible where Element: Codable {
    public var fuseDatabaseValue: Any {
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: self, options: [])
            return String(data: jsonData, encoding: .utf8) ?? "[]"
        } catch {
            return "[]" // Fallback to empty array
        }
    }
}

// Make Dictionary conform to FuseDatabaseValueConvertible by converting to JSON string
extension Dictionary: FuseDatabaseValueConvertible where Key == String, Value: Codable {
    public var fuseDatabaseValue: Any {
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: self, options: [])
            return String(data: jsonData, encoding: .utf8) ?? "{}"
        } catch {
            return "{}" // Fallback to empty object
        }
    }
}
