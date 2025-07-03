import Foundation

// MARK: - Database Factory Registry
/// Registry for managing database factory implementations
public class FuseDatabaseFactoryRegistry {
    nonisolated(unsafe) public static let shared = FuseDatabaseFactoryRegistry()
    
    private var registeredFactory: FuseDatabaseFactory?
    private let lock = NSLock()
    
    private init() {
    }
    
    /// Register a database factory implementation
    /// This is typically called by database implementation modules during their initialization
    public func setMainFactory(_ factory: FuseDatabaseFactory) {
        lock.lock()
        defer { lock.unlock() }
        registeredFactory = factory
    }
    
    /// Get the currently registered factory
    /// Returns nil if no factory has been registered
    func mainFactory() -> FuseDatabaseFactory? {
        lock.lock()
        defer { lock.unlock() }
        return registeredFactory
    }
}
