import Foundation
#if os(iOS) || os(tvOS) || os(watchOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

/// Protocol defining file operations for FuseStorageKit
/// 
/// This protocol provides a unified interface for file system operations,
/// handling file storage, retrieval, and management. It supports various
/// file types including images and binary data with cross-platform compatibility.
public protocol FuseFileManageable: FuseManageable {
    /// Save an image to the file system
    /// - Parameters:
    ///   - image: The image to save
    ///   - fileName: The filename for the saved image
    /// - Returns: The URL where the image was saved
    /// - Throws: File system errors during saving
    func save(image: FuseImage, fileName: String) throws -> URL
    
    /// Save binary data to the file system
    /// - Parameters:
    ///   - data: The data to save
    ///   - relativePath: The path relative to the base directory
    /// - Returns: The URL where the data was saved
    /// - Throws: File system errors during saving
    func save(data: Data, relativePath: String) throws -> URL
  
    /// Get the absolute URL for a relative path
    /// - Parameter relativePath: The path relative to the base directory
    /// - Returns: The absolute URL for the path
    func url(for relativePath: String) -> URL

    /// Delete a file at the specified path
    /// - Parameter relativePath: The path relative to the base directory
    /// - Throws: File system errors during deletion
    func delete(relativePath: String) throws
} 
