import Foundation

enum FuseDatabaseBuilderOptionType {
    case sqlite(path: String = FuseConstants.defaultName, encryptions: EncryptionOptions?)
    case custom(name: String, database: FuseDatabaseManageable)
}

public struct FuseDatabaseBuilderOption: FuseStorageBuilderOption {
    private let optionType: FuseDatabaseBuilderOptionType

    init(optionType: FuseDatabaseBuilderOptionType) {
        self.optionType = optionType
    }
    
    public static func sqlite(path: String = FuseConstants.defaultName, encryptions: EncryptionOptions? = nil) -> Self {
        return .init(optionType: .sqlite(path: path, encryptions: encryptions))
    }
    
    public static func custom(name: String, database: FuseDatabaseManageable) -> Self {
        return .init(optionType: .custom(name: name, database: database))
    }
    
    public var query: FuseStorageOptionQuery {
        switch self.optionType {
        case .sqlite(let path, _):
            return FuseDatabaseOptionQuery.sqlite(path)
        case .custom(let name, _):
            return FuseDatabaseOptionQuery.custom(name)
        }
    }

    public func build() throws -> FuseManageable {
        switch self.optionType {
        case .sqlite(let path, let encryptions):
            return try FuseDatabaseManager(path: path, encryptions: encryptions)
        case .custom(_, let database):
            return database
        }
    }
}

public enum FuseDatabaseOptionQuery: FuseStorageOptionQuery {
    case sqlite(_ path: String = FuseConstants.defaultName)
    case custom(_ name: String)

    public var name: String {
        switch self {
        case .sqlite(let path):
            return "db_sqlite_\(path)"
        case .custom(let name):
            return "db_custom_\(name)"
        }
    }
}
