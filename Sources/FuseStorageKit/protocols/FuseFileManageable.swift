import Foundation

/// Protocol defining file operations (handles only files, not database-related)
public protocol FuseFileManageable {
  /// Save an image to the file system
  /// - Parameters:
  ///   - image: The image to save
  ///   - relativePath: The path relative to the base directory
  /// - Returns: The URL where the image was saved
  /// - Throws: File system errors during saving
  func save(image: FuseImage, relativePath: String) throws -> URL
  
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