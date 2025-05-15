import Foundation

/// Enumeration defining the types of preferences storage configurations available
/// 
/// This enumeration provides different preferences storage options, including
/// UserDefaults for standard app preferences and Keychain for secure data storage.
public enum FusePreferencesBuilderOptionType {
    /// Store preferences using UserDefaults with optional suite name
    case userDefaults(suiteName: String?)
    /// Store preferences securely using Keychain services
    case keychain(service: String, accessGroup: String?, accessibility: FuseKeychainAccessibility)
    /// Use a custom preferences manager implementation
    case custom(name: String, preferences: FusePreferencesManageable)
}

/// Builder option for configuring preferences managers in FuseStorageKit
/// 
/// This structure provides factory methods for creating different types of preferences
/// storage configurations, supporting both standard UserDefaults and secure Keychain
/// storage, as well as custom preferences implementations.
public struct FusePreferencesBuilderOption: FuseStorageBuilderOption {
    private let optionType: FusePreferencesBuilderOptionType

    init(optionType: FusePreferencesBuilderOptionType) {
        self.optionType = optionType
    }

    /// Creates a UserDefaults-based preferences configuration
    /// 
    /// This factory method configures a preferences manager that uses UserDefaults
    /// for storing application preferences and settings. UserDefaults is suitable
    /// for non-sensitive configuration data.
    /// 
    /// - Parameter suiteName: Optional suite name for shared preferences between apps
    /// - Returns: A configured preferences builder option
    public static func userDefaults(_ suiteName: String? = nil) -> Self {
        return .init(optionType: .userDefaults(suiteName: suiteName))
    }

    /// Creates a Keychain-based preferences configuration for secure storage
    /// 
    /// This factory method configures a preferences manager that uses the system
    /// Keychain for storing sensitive data such as passwords, tokens, and other
    /// confidential information with hardware-level security.
    /// 
    /// - Parameters:
    ///   - service: The service identifier for Keychain items
    ///   - accessGroup: Optional access group for sharing between apps
    ///   - accessibility: The accessibility level for Keychain items
    /// - Returns: A configured preferences builder option
    public static func keychain(_ service: String, accessGroup: String? = nil, accessibility: FuseKeychainAccessibility = .whenUnlocked) -> Self {
        return .init(optionType: .keychain(service: service, accessGroup: accessGroup, accessibility: accessibility))
    }

    /// Creates a custom preferences configuration using a provided preferences manager
    /// 
    /// This factory method allows integration of custom preferences implementations
    /// that conform to FusePreferencesManageable, providing flexibility for specialized
    /// storage requirements or third-party preferences systems.
    /// 
    /// - Parameters:
    ///   - name: A unique identifier for this preferences configuration
    ///   - preferences: The custom preferences manager implementation
    /// - Returns: A configured preferences builder option
    public static func custom(_ name: String, preferences: FusePreferencesManageable) -> Self {
        return .init(optionType: .custom(name: name, preferences: preferences))
    }

    public func build() throws -> FuseManageable {
        switch self.optionType {
        case .userDefaults(let suiteName):
            return FuseUserDefaultsManager(suiteName: suiteName)
        case .keychain(let service, let accessGroup, let accessibility):
            return FuseKeychainManager(service: service, accessGroup: accessGroup, accessibility: accessibility)
        case .custom(_, let preferences):
            return preferences
        }
    }
    
    public var name: String {
        switch self.optionType {
        case .userDefaults(let suiteName):
            return "pref_userDefaults_\(suiteName ?? Bundle.main.bundleIdentifier ?? FuseConstants.packageName)"
        case .keychain(let service, _, _):
            return "pref_keychain_\(service)"
        case .custom(let name, _):
            return "pref_custom_\(name)"
        }
    }
}
