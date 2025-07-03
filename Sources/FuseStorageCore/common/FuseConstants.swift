import Foundation

/// Constants used throughout the FuseStorageKit framework
/// 
/// This structure provides centralized access to default values and configuration
/// constants that are used across different components of the storage framework.
public struct FuseConstants {
    /// The default package name used for directory creation and identification
    /// 
    /// This name is used as the default folder name when creating storage directories
    /// in the file system, ensuring consistent organization of FuseStorageKit data.
    public static let packageName: String = "FuseStorageKit"
    
    /// The default SQLite database filename
    /// 
    /// This filename is used when creating new database instances without specifying
    /// a custom path, providing a consistent default database file name.
    public static let databaseName: String = "fuse.sqlite"
    
    
    static func getIso8601DataFormatter() -> ISO8601DateFormatter {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds, .withDashSeparatorInDate, .withColonSeparatorInTimeZone]
        return f
    }
    
    static func getDataFormatter() -> DateFormatter {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        return f
    }
}
