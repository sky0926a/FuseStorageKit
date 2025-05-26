import Foundation

/// Enumeration defining the types of file storage configurations available
/// 
/// This enumeration provides different file storage location options, including
/// standard system directories and custom file manager implementations.
public enum FuseFileBuilderOptionType {
    /// Store files in the Documents directory
    case document(mainFolderName: String)
    /// Store files in the Library directory
    case library(mainFolderName: String)
    /// Store files in the Cache directory
    case cache(mainFolderName: String)
    /// Store files in a custom directory with specified search path
    case file(mainFolderName: String, searchPathDirectory: FileManager.SearchPathDirectory, domainMask: FileManager.SearchPathDomainMask)
    /// Use a custom file manager implementation
    case custom(name: String, file: FuseFileManageable)
}

/// Builder option for configuring file managers in FuseStorageKit
/// 
/// This structure provides factory methods for creating different types of file
/// storage configurations, supporting various system directories and custom
/// file management implementations for flexible file handling.
public struct FuseFileBuilderOption: FuseStorageBuilderOption {
    private let optionType: FuseFileBuilderOptionType

    init(optionType: FuseFileBuilderOptionType) {
        self.optionType = optionType
    }
    
    /// Creates a file manager configuration for the Documents directory
    /// 
    /// This factory method configures a file manager that stores files in the
    /// app's Documents directory, which is backed up by iTunes and iCloud.
    /// 
    /// - Parameter mainFolderName: The main folder name within Documents directory
    /// - Returns: A configured file builder option
    public static func document(_ mainFolderName: String = FuseConstants.packageName) -> Self {
        return .init(optionType: .document(mainFolderName: mainFolderName))
    }
    
    /// Creates a file manager configuration for the Library directory
    /// 
    /// This factory method configures a file manager that stores files in the
    /// app's Library directory, which is not visible to users but is backed up.
    /// 
    /// - Parameter mainFolderName: The main folder name within Library directory
    /// - Returns: A configured file builder option
    public static func library(_ mainFolderName: String = FuseConstants.packageName) -> Self {
        return .init(optionType: .library(mainFolderName: mainFolderName))
    }
    
    /// Creates a file manager configuration for the Cache directory
    /// 
    /// This factory method configures a file manager that stores files in the
    /// app's Cache directory, which may be purged by the system when storage is low.
    /// 
    /// - Parameter mainFolderName: The main folder name within Cache directory
    /// - Returns: A configured file builder option
    public static func cache(_ mainFolderName: String = FuseConstants.packageName) -> Self {
        return .init(optionType: .cache(mainFolderName: mainFolderName))
    }
    
    /// Creates a file manager configuration for a custom directory location
    /// 
    /// This factory method provides maximum flexibility by allowing specification
    /// of any system directory through FileManager's search path system.
    /// 
    /// - Parameters:
    ///   - mainFolderName: The main folder name within the specified directory
    ///   - searchPathDirectory: The system directory to use for file storage
    ///   - domainMask: The domain mask for directory search
    /// - Returns: A configured file builder option
    public static func file(_ mainFolderName: String = FuseConstants.packageName,
                            searchPathDirectory: FileManager.SearchPathDirectory = .documentDirectory,
                            domainMask: FileManager.SearchPathDomainMask = .userDomainMask) -> Self {
        return .init(optionType: .file(mainFolderName: mainFolderName, searchPathDirectory: searchPathDirectory, domainMask: domainMask))
    }
    
    /// Creates a custom file manager configuration using a provided file manager
    /// 
    /// This factory method allows integration of custom file management implementations
    /// that conform to FuseFileManageable, providing flexibility for specialized
    /// file handling requirements or third-party file systems.
    /// 
    /// - Parameters:
    ///   - name: A unique identifier for this file configuration
    ///   - file: The custom file manager implementation
    /// - Returns: A configured file builder option
    public static func custom(_ name: String, file: FuseFileManageable) -> Self {
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
    
    public var name: String {
        switch self.optionType {
        case .document(let mainFolderName):
            return "file_document_\(mainFolderName)"
        case .library(let mainFolderName):
            return "file_library_\(mainFolderName)"
        case .cache(let mainFolderName):
            return "file_cache_\(mainFolderName)"
        case .file(let mainFolderName, _, _):
            return "file_file_\(mainFolderName))"
        case .custom(let name, _):
            return "file_custom_\(name)"
        }
    }
}
