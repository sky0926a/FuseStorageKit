import Foundation

public enum FusePreferencesBuilderOptionType {
    case userDefaults(suiteName: String? = nil)
    case keychain(service: String? = nil, accessGroup: String? = nil, accessibility: FuseKeychainAccessibility)
    case custom(name: String, preferences: FusePreferencesManageable)
}

public struct FusePreferencesBuilderOption: FuseStorageBuilderOption {
    private let optionType: FusePreferencesBuilderOptionType

    init(optionType: FusePreferencesBuilderOptionType) {
        self.optionType = optionType
    }

    public static func userDefaults(suiteName: String? = nil) -> Self {
        return .init(optionType: .userDefaults(suiteName: suiteName))
    }

    public static func keychain(service: String? = nil, accessGroup: String? = nil, accessibility: FuseKeychainAccessibility) -> Self {
        return .init(optionType: .keychain(service: service, accessGroup: accessGroup, accessibility: accessibility))
    }

    public static func custom(name: String, preferences: FusePreferencesManageable) -> Self {
        return .init(optionType: .custom(name: name, preferences: preferences))
    }

    public func build() throws -> FuseManageable {
        switch self.optionType {
        case .userDefaults(let suiteName):
            return FusePreferencesManager(suiteName: suiteName)
        case .keychain(let service, let accessGroup, let accessibility):
            return FuseKeychainManager(service: service, accessGroup: accessGroup, accessibility: accessibility)
        case .custom(_, let preferences):
            return preferences
        }
    }

    public var query: FuseStorageOptionQuery {
        switch self.optionType {
        case .userDefaults(let suiteName):
            return FusePreferencesOptionQuery.userDefaults(suiteName)
        case .keychain(let service, _, _):
            return FusePreferencesOptionQuery.keychain(service)
        case .custom(let name, _):
            return FusePreferencesOptionQuery.custom(name)
        }
    }
}

enum FusePreferencesOptionQueryType {
    case userDefaults(_ suiteName: String?)
    case keychain(_ service: String?)
    case custom(_ name: String)
}

public struct FusePreferencesOptionQuery: FuseStorageOptionQuery {
    private let optionType: FusePreferencesOptionQueryType

    init(optionType: FusePreferencesOptionQueryType) {
        self.optionType = optionType
    }

    public static func userDefaults(_ suiteName: String? = nil) -> Self {
        return .init(optionType: .userDefaults(suiteName))
    }

    public static func keychain(_ service: String? = nil) -> Self { 
        return .init(optionType: .keychain(service))
    }

    public static func custom(_ name: String) -> Self {
        return .init(optionType: .custom(name))
    }

    public var name: String {
        switch self.optionType {
        case .userDefaults(let suiteName):
            return "pref_userDefaults_\(suiteName ?? Bundle.main.bundleIdentifier ?? FuseConstants.packageName)"
        case .keychain(let service):
            let wrappedService = service ?? ""
            return "pref_keychain_\(wrappedService)"
        case .custom(let name):
            return "pref_custom_\(name)"
        }
    }
}
