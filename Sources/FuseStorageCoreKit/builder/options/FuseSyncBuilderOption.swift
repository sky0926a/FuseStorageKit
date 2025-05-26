import Foundation

/// Enumeration defining the types of synchronization configurations available
/// 
/// This enumeration provides different sync options, including Firebase integration,
/// no-operation sync for offline-only apps, and custom sync implementations.
public enum FuseSyncBuilderOptionType {
    #if canImport(FirebaseStorage)
    /// Synchronize data using Firebase Storage services
    case firebase
    #endif
    /// No synchronization - local storage only
    case noSync
    /// Use a custom synchronization manager implementation
    case custom(name: String, sync: FuseSyncManageable)
}

/// Builder option for configuring synchronization managers in FuseStorageKit
/// 
/// This structure provides factory methods for creating different types of sync
/// configurations, supporting Firebase integration, offline-only operation,
/// and custom synchronization implementations for flexible data sync strategies.
public struct FuseSyncBuilderOption: FuseStorageBuilderOption {
    
    private let optionType: FuseSyncBuilderOptionType

    init(optionType: FuseSyncBuilderOptionType) {
        self.optionType = optionType
    }

    #if canImport(FirebaseStorage)
    /// Creates a Firebase-based synchronization configuration
    /// 
    /// This factory method configures a sync manager that uses Firebase Storage
    /// for cloud-based data synchronization, enabling real-time data sharing
    /// across devices and platforms.
    /// 
    /// - Returns: A configured sync builder option for Firebase
    public static func firebase() -> Self {
        return .init(optionType: .firebase)
    }
    #endif

    /// Creates a no-operation synchronization configuration
    /// 
    /// This factory method configures a sync manager that performs no actual
    /// synchronization, suitable for offline-only applications or when
    /// synchronization is handled externally.
    /// 
    /// - Returns: A configured sync builder option with no synchronization
    public static func noSync() -> Self {
        return .init(optionType: .noSync)
    }

    /// Creates a custom synchronization configuration using a provided sync manager
    /// 
    /// This factory method allows integration of custom synchronization implementations
    /// that conform to FuseSyncManageable, providing flexibility for specialized
    /// sync requirements or third-party cloud services.
    /// 
    /// - Parameters:
    ///   - name: A unique identifier for this sync configuration
    ///   - sync: The custom sync manager implementation
    /// - Returns: A configured sync builder option
    public static func custom(name: String, sync: FuseSyncManageable) -> Self {
        return .init(optionType: .custom(name: name, sync: sync))
    }

    public func build() throws ->  FuseManageable {
        switch self.optionType {
        #if canImport(FirebaseStorage)
        case .firebase:
            return FuseFirebaseSyncManager()
        #endif
        case .noSync:
            return NoSyncManager()
        case .custom(_, let sync):
            return sync
        }
    }
    
    public var name: String {
        switch self.optionType {
        #if canImport(FirebaseStorage)
        case .firebase:
            return "sync_firebase"
        #endif
        case .noSync:
            return "sync_noSync"
        case .custom(let name, _):
            return "sync_custom_\(name)"
        }
    }
}
