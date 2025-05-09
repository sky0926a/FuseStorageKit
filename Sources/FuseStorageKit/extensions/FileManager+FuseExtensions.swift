import Foundation

/// Extensions for FileManager to provide common functionality for FuseStorageKit
public extension FileManager {
    /// Returns the Documents directory URL
    /// - Returns: URL to the app's Documents directory
    func documentsDirectory() -> URL {
        return urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    /// Creates required directories for a file path if they don't exist
    /// - Parameter url: The URL of the file
    /// - Throws: Error if directory creation fails
    func createDirectoriesIfNeeded(for url: URL) throws {
        let directory = url.deletingLastPathComponent()
        if !fileExists(atPath: directory.path) {
            try createDirectory(
                at: directory,
                withIntermediateDirectories: true
            )
        }
    }
} 