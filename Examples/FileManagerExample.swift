import FuseStorageKit
import Foundation

// Usage example: File management across different locations
func fileManagerExample() throws {
    // 1. Build storage with multiple file locations
    let storage = try FuseStorageBuilder()
        .with(file: .document("UserFiles"))
        .with(file: .library("AppData"))
        .with(file: .cache("TempFiles"))
        .build()
    
    let documentsManager = storage.file(.document("UserFiles"))!
    let libraryManager = storage.file(.library("AppData"))!
    let cacheManager = storage.file(.cache("TempFiles"))!
    
    // 2. Save text files to Documents
    let textData = "Hello, World! This is a sample text file.".data(using: .utf8)!
    let textURL = try documentsManager.save(
        data: textData,
        relativePath: "notes/sample.txt"
    )
    print("📄 Text file saved: \(textURL)")
    
    // 3. Save JSON data to Library
    let jsonData = [
        "name": "John Doe",
        "age": 30,
        "city": "New York"
    ]
    let jsonString = try JSONSerialization.data(withJSONObject: jsonData)
    let jsonURL = try libraryManager.save(
        data: jsonString,
        relativePath: "config/user.json"
    )
    print("📋 JSON file saved: \(jsonURL)")
    
    // 4. Save binary data to Cache
    let binaryData = Data([0x48, 0x65, 0x6c, 0x6c, 0x6f])  // "Hello" in hex
    let binaryURL = try cacheManager.save(
        data: binaryData,
        relativePath: "temp/binary.dat"
    )
    print("💾 Binary file saved: \(binaryURL)")
    
    // 5. Get file URLs without saving
    let logURL = documentsManager.url(for: "logs/app.log")
    let configURL = libraryManager.url(for: "settings/config.plist")
    let tempURL = cacheManager.url(for: "temp/image.png")
    
    print("📂 File URLs:")
    print("  Log file: \(logURL)")
    print("  Config file: \(configURL)")
    print("  Temp file: \(tempURL)")
    
    // 6. Save multiple files in different formats
    let files = [
        ("document1.txt", "First document content"),
        ("document2.txt", "Second document content"),
        ("document3.txt", "Third document content")
    ]
    
    for (filename, content) in files {
        let data = content.data(using: .utf8)!
        let url = try documentsManager.save(
            data: data,
            relativePath: "documents/\(filename)"
        )
        print("📝 Saved: \(filename) at \(url)")
    }
    
    // 7. Save image data (simulated)
    let imageData = Data(count: 1024)  // Simulate image data
    let imageURL = try documentsManager.save(
        data: imageData,
        relativePath: "images/photo.jpg"
    )
    print("🖼️ Image saved: \(imageURL)")
    
    // 8. Save configuration files
    let configData = """
    {
        "version": "1.0",
        "features": {
            "darkMode": true,
            "pushNotifications": false
        }
    }
    """.data(using: .utf8)!
    
    let appConfigURL = try libraryManager.save(
        data: configData,
        relativePath: "config/app.json"
    )
    print("⚙️ App config saved: \(appConfigURL)")
    
    // 9. Delete files
    try documentsManager.delete(relativePath: "documents/document1.txt")
    try cacheManager.delete(relativePath: "temp/binary.dat")
    print("🗑️ Deleted some files")
    
    // 10. Organize files in folders
    let folderStructure = [
        "projects/project1/code.swift",
        "projects/project2/readme.md",
        "backup/2024/january.zip",
        "backup/2024/february.zip"
    ]
    
    for path in folderStructure {
        let sampleData = "Sample content for \(path)".data(using: .utf8)!
        let url = try documentsManager.save(data: sampleData, relativePath: path)
        print("📁 Created: \(path)")
    }
    
    print("File management example completed successfully!")
} 