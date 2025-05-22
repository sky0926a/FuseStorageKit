import Foundation

/// Implementation of FuseFileManageable that manages files in the app's document directory
public final class FuseFileManager: FuseFileManageable {
    private let fm = FileManager.default
    private let baseURL: URL
    private let searchPath: URL

  /// Initialize with default base directory: Documents/FuseStorageKit
    public init(mainFolderName: String = "FuseStorageKit",
                searchPathDirectory: FileManager.SearchPathDirectory = .documentDirectory,
                domainMask: FileManager.SearchPathDomainMask = .userDomainMask) {
        self.searchPath = fm.urls(for: searchPathDirectory, in: domainMask)[0]
        let folder = self.searchPath.appendingPathComponent(mainFolderName, isDirectory: true)
        if !fm.fileExists(atPath: folder.path) {
            try? fm.createDirectory(at: folder,
                                    withIntermediateDirectories: true,
                                    attributes: nil)
        }
        baseURL = folder
    }

  /// Save an image to the file system, automatically selecting the format based on extension
  /// - Parameters:
  ///   - image: The image to save
  ///   - relativePath: Path relative to base directory, with extension determining format
  /// - Returns: The URL where the image was saved
  /// - Throws: Errors during image conversion or file writing
  public func save(image: FuseImage, fileName: String) throws -> URL {
    // 根據副檔名自動選擇 JPEG/PNG
    let ext = (fileName as NSString).pathExtension.lowercased()
    let data: Data?
    
    #if os(iOS) || os(tvOS) || os(watchOS)
    switch ext {
      case "png":  data = image.pngData()
      case "jpg", "jpeg": data = image.jpegData(compressionQuality: 0.9)
      default:     data = image.jpegData(compressionQuality: 0.9)
    }
    #elseif os(macOS)
    guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
      throw NSError(domain: "FileManager", code: -1,
                  userInfo: [NSLocalizedDescriptionKey: "無法將 NSImage 轉換為 CGImage"])
    }
    
    let bitmapRep = NSBitmapImageRep(cgImage: cgImage)
    switch ext {
      case "png":  data = bitmapRep.representation(using: .png, properties: [:])
      case "jpg", "jpeg": data = bitmapRep.representation(using: .jpeg, properties: [.compressionFactor: 0.9])
      default:     data = bitmapRep.representation(using: .jpeg, properties: [.compressionFactor: 0.9])
    }
    #endif
    
    guard let imageData = data else {
      throw NSError(domain: "FileManager", code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "無法將圖像轉換為資料"])
    }
    return try save(data: imageData, relativePath: fileName)
  }
    
    /// Save binary data to the file system
    /// - Parameters:
    ///   - data: The data to save
    ///   - relativePath: Path relative to base directory where the data will be saved
    /// - Returns: The URL where the data was saved
    /// - Throws: Errors during directory creation or file writing
    public func save(data: Data, relativePath: String) throws -> URL {
        let fileURL = url(for: relativePath)
        try fm.createDirectoriesIfNeeded(for: fileURL)
        try data.write(to: fileURL, options: .atomic)
        return fileURL
    }

    /// Get the absolute URL for a relative path
    /// - Parameter relativePath: Path relative to base directory
    /// - Returns: The absolute URL for the path
    public func url(for relativePath: String) -> URL {
        return baseURL.appendingPathComponent(relativePath, isDirectory: false)
    }

    /// Delete a file at the specified path
    /// - Parameter relativePath: Path relative to base directory of the file to delete
    /// - Throws: Errors during file deletion
    public func delete(relativePath: String) throws {
        let fileURL = url(for: relativePath)
        if fm.fileExists(atPath: fileURL.path) {
            try fm.removeItem(at: fileURL)
        }
    }
} 
