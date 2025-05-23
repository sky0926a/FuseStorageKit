import Foundation

public enum FuseFileBuilderOptionType {
    case document(mainFolderName: String)
    case library(mainFolderName: String)
    case cache(mainFolderName: String)
    case file(mainFolderName: String, searchPathDirectory: FileManager.SearchPathDirectory, domainMask: FileManager.SearchPathDomainMask)
    case custom(name: String, file: FuseFileManageable)
}

public struct FuseFileBuilderOption: FuseStorageBuilderOption {
    private let optionType: FuseFileBuilderOptionType

    init(optionType: FuseFileBuilderOptionType) {
        self.optionType = optionType
    }
    
    public static func document(mainFolderName: String = FuseConstants.packageName) -> Self {
        return .init(optionType: .document(mainFolderName: mainFolderName))
    }
    
    public static func library(mainFolderName: String = FuseConstants.packageName) -> Self {
        return .init(optionType: .library(mainFolderName: mainFolderName))
    }
    
    public static func cache(mainFolderName: String = FuseConstants.packageName) -> Self {
        return .init(optionType: .cache(mainFolderName: mainFolderName))
    }
    
    public static func file(mainFolderName: String = FuseConstants.packageName,
                            searchPathDirectory: FileManager.SearchPathDirectory = .documentDirectory,
                            domainMask: FileManager.SearchPathDomainMask = .userDomainMask) -> Self {
        return .init(optionType: .file(mainFolderName: mainFolderName, searchPathDirectory: searchPathDirectory, domainMask: domainMask))
    }
    
    public static func custom(name: String, file: FuseFileManageable) -> Self {
        return .init(optionType: .custom(name: name, file: file))
    }

    public func build() throws -> FuseManageable {
        switch self.optionType {
        case .document(let mainFolderName):
            return FuseFileManager(mainFolderName: mainFolderName, searchPathDirectory: .documentDirectory, domainMask: .userDomainMask)
        case .library(let mainFolderName):
            return FuseFileManager(mainFolderName: mainFolderName, searchPathDirectory: .libraryDirectory, domainMask: .userDomainMask)
        case .cache(let mainFolderName):
            return FuseFileManager(mainFolderName: mainFolderName, searchPathDirectory: .cachesDirectory, domainMask: .userDomainMask)
        case .file(let mainFolderName, let searchPathDirectory, let domainMask):
            return FuseFileManager(mainFolderName: mainFolderName, searchPathDirectory: searchPathDirectory, domainMask: domainMask)
        case .custom(_, let file):
            return file
        }
    }
    
    public var query: FuseStorageOptionQuery {
        switch self.optionType {
        case .document(let mainFolderName):
            return FuseFileOptionQuery.document(mainFolderName)
        case .library(let mainFolderName):
            return FuseFileOptionQuery.library(mainFolderName)
        case .cache(let mainFolderName):
            return FuseFileOptionQuery.cache(mainFolderName)
        case .file(let mainFolderName, _, _):
            return FuseFileOptionQuery.file(mainFolderName)
        case .custom(let name, _):
            return FuseFileOptionQuery.custom(name)
        }
    }
}

enum FuseFileOptionQueryType {
    case document(_ mainFolderName: String)
    case library(_ mainFolderName: String)
    case cache(_ mainFolderName: String)
    case file(_ mainFolderName: String)
    case custom(_ name: String)
}

public struct FuseFileOptionQuery: FuseStorageOptionQuery {
    private let optionType: FuseFileOptionQueryType
    init(optionType: FuseFileOptionQueryType) {
        self.optionType = optionType
    }
    
    public static func document(_ mainFolderName: String = FuseConstants.packageName) -> Self {
        return .init(optionType: .document(mainFolderName))
    }

    public static func library(_ mainFolderName: String = FuseConstants.packageName) -> Self {
        return .init(optionType: .library(mainFolderName))
    }
    
    public static func cache(_ mainFolderName: String = FuseConstants.packageName) -> Self {
        return .init(optionType: .cache(mainFolderName))
    }

    public static func file(_ mainFolderName: String = FuseConstants.packageName) -> Self {
        return .init(optionType: .file(mainFolderName))
    }
    
    public static func custom(_ name: String) -> Self {
        return .init(optionType: .custom(name))
    }

    public var name: String {
        switch self.optionType {
        case .document(let mainFolderName):
            return "file_document_\(mainFolderName)"
        case .library(let mainFolderName):
            return "file_library_\(mainFolderName)"
        case .cache(let mainFolderName):
            return "file_cache_\(mainFolderName)"
        case .file(let mainFolderName):
            return "file_file_\(mainFolderName))"
        case .custom(let name):
            return "file_custom_\(name)"
        }
    }
}
