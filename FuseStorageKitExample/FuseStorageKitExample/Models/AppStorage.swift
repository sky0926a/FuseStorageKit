import Foundation
import FuseStorageKit
import UIKit

class AppStorage {
    static let shared = AppStorage()
    
    private let storageKit: FuseStorageKit
    
    private init() {
        do {
            storageKit = try FuseStorageKitBuilder()
                .with(database: FuseDatabaseManager(path: "fuse.sqlite"))
                .with(file: FuseFileManager.withBaseFolder("NoteAttachments"))
                .build()
            try database.createTable(Note.tableDefinition())
        } catch {
            fatalError("無法初始化儲存系統: \(error)")
        }
    }
    
    var database: FuseDatabaseManageable {
        return storageKit.database
    }
    
    // MARK: - 筆記相關操作
    
    func saveNote(_ note: Note, image: UIImage? = nil) throws {
        var noteToSave = note
        
        // 如果有圖片附件，先儲存圖片
        if let image = image {
            let imagePath = "attachments/\(note.id)/image.jpg"
            _ = try storageKit.file.save(image: image, relativePath: imagePath)
            
            // 更新筆記的附件信息
            noteToSave.hasAttachment = true
            noteToSave.attachmentPath = imagePath
        }
        try database.add(noteToSave)
    }
    
    func getAllNotes(withTitle title: String? = nil) throws -> [Note] {
        var filters: [FuseQueryFilter] = []
        
        if let title = title, !title.isEmpty {
            filters.append(FuseQueryFilter.like(
                field: Note.Field.title,
                value: "%\(title)%"
            ))
        }
        
        return try database.fetch(
            of: Note.self,
            filters: filters,
            sort: FuseQuerySort(field: Note.Field.createdAt, order: .descending),
            limit: nil,
            offset: nil
        )
    }
    
    func getNote(withID id: String) throws -> Note? {
        let query = FuseQuery(
            table: Note.databaseTableName,
            action: .select(
                fields: ["*"],
                filters: [FuseQueryFilter.equals(field: Note.Field.id, value: id)],
                sort: nil
            )
        )
        
        return try database.read(query).first
    }
    
    func deleteNote(_ note: Note) throws {
        // 刪除筆記記錄
        try database.delete(note)
        
        // 如果有附件，也刪除附件
        if note.hasAttachment, let path = note.attachmentPath {
            try storageKit.file.delete(relativePath: path)
        }
    }
    
    func getAttachmentImage(for note: Note) -> UIImage? {
        guard note.hasAttachment, let path = note.attachmentPath else { return nil }
        
        let url = storageKit.file.url(for: path)
        
        guard let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }
    
    // MARK: - 使用者偏好設定操作
    
    func saveThemePreference(isDarkMode: Bool) {
        storageKit.preferences.set(isDarkMode, forKey: "isDarkMode")
    }
    
    func getThemePreference() -> Bool {
        storageKit.preferences.get(forKey: "isDarkMode") ?? false
    }
    
    // MARK: - 文件打包分享功能
    
    /// 將整個 Documents 目錄打包成 ZIP 文件
    /// - Returns: ZIP 文件的 URL
    /// - Throws: 打包過程中的錯誤
    func createNotesZipArchive() throws -> URL {
        let fileManager = FileManager.default
        
        // 先清理所有可能存在的舊臨時 ZIP 文件
        try cleanupOldZipFiles()
        
        // 獲取應用的 Documents 目錄
        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        
        // 遞歸創建 FileWrapper 的輔助函數
        func createFileWrapper(for directory: URL) throws -> FileWrapper {
            var contentWrappers = [String: FileWrapper]()
            
            // 獲取目錄中的所有內容
            let contents = try fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil, options: [])
            
            for url in contents {
                let fileName = url.lastPathComponent
                
                // 跳過某些系統文件和臨時文件
                if fileName.hasPrefix(".") || fileName == "Inbox" {
                    continue
                }
                
                if url.hasDirectoryPath {
                    // 遞歸處理子目錄
                    let subWrapper = try createFileWrapper(for: url)
                    contentWrappers[fileName] = subWrapper
                } else {
                    // 處理文件
                    let fileData = try Data(contentsOf: url)
                    let fileWrapper = FileWrapper(regularFileWithContents: fileData)
                    fileWrapper.preferredFilename = fileName
                    contentWrappers[fileName] = fileWrapper
                }
            }
            
            return FileWrapper(directoryWithFileWrappers: contentWrappers)
        }
        
        // 創建包含整個 Documents 內容的 FileWrapper
        let docWrapper = try createFileWrapper(for: documentsDirectory)
        
        // 創建 ZIP 文件路徑 (使用 UUID 確保唯一性)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd-HH-mm-ss"
        let dateString = dateFormatter.string(from: Date())
        let uniqueID = UUID().uuidString.prefix(8)
        let zipFileName = "Documents_\(dateString)_\(uniqueID).zip"
        let zipFilePath = fileManager.temporaryDirectory.appendingPathComponent(zipFileName)
        
        // 將 FileWrapper 寫入 ZIP 文件
        try docWrapper.write(to: zipFilePath, options: .atomic, originalContentsURL: nil)
        
        return zipFilePath
    }
    
    /// 清理舊的臨時 ZIP 文件
    private func cleanupOldZipFiles() throws {
        let fileManager = FileManager.default
        let tempDir = fileManager.temporaryDirectory
        
        // 獲取臨時目錄中的所有內容
        let tempContents = try fileManager.contentsOfDirectory(at: tempDir, includingPropertiesForKeys: nil, options: [])
        
        // 刪除所有以 "Documents_" 開頭且以 ".zip" 結尾的文件
        for fileURL in tempContents {
            let fileName = fileURL.lastPathComponent
            if fileName.hasPrefix("Documents_") && fileName.hasSuffix(".zip") {
                try? fileManager.removeItem(at: fileURL)
            }
        }
    }
} 
