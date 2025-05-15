import Foundation
import FuseStorageKit
import UIKit

class AppStorage {
    static let shared = AppStorage()
    
    private let storage: FuseStorage
    
    private init() {
        do {
            let buildStart = CFAbsoluteTimeGetCurrent()
            storage = try FuseStorageBuilder()
                .with(database: .sqlite("fuse.sqlite", encryptions: EncryptionOptions("fuse")))
                .with(file: .document("NoteAttachments"))
                .with(preferences: .keychain("com.fusestoragekit.user"))
                .build()
            let buildDuration = CFAbsoluteTimeGetCurrent() - buildStart
                    print("🛠️ storage.build() took \(String(format: "%.3f", buildDuration)) seconds")
            let tableStart = CFAbsoluteTimeGetCurrent()
            try database.createTable(Note.tableDefinition())
            let tableDuration = CFAbsoluteTimeGetCurrent() - tableStart
                    print("📋 createTable() took \(String(format: "%.3f", tableDuration)) seconds")
        } catch {
            fatalError("無法初始化儲存系統: \(error)")
        }
    }
    
    var database: FuseDatabaseManageable {
        return storage.db(.sqlite("fuse.sqlite"))!
    }
    
    var file: FuseFileManageable {
        return storage.file(.document("NoteAttachments"))!
    }
    
    var preferences: FusePreferencesManageable {
        return storage.pref(.userDefaults())!
    }
    
    var keychain: FusePreferencesManageable {
        return storage.pref(.keychain("com.fusestoragekit.user"))!
    }
    
    // MARK: - 筆記相關操作
    
    func saveNote(_ note: Note, image: UIImage? = nil) throws {
        var noteToSave = note
        
        // 如果有圖片附件，先儲存圖片
        if let image = image {
            let imagePath = "attachments/\(note.id)/image.jpg"
            _ = try file.save(image: image, fileName: imagePath)
            
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
            try file.delete(relativePath: path)
        }
    }
    
    func getAttachmentImage(for note: Note) -> UIImage? {
        guard note.hasAttachment, let path = note.attachmentPath else { return nil }
        
        let url = file.url(for: path)
        
        guard let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }
    
    // MARK: - 使用者偏好設定操作
    
    func saveThemePreference(isDarkMode: Bool) {
        try? preferences.set(isDarkMode, forKey: "isDarkMode")
    }
    
    func getThemePreference() -> Bool {
        preferences.get(forKey: "isDarkMode") ?? false
    }
    
    // MARK: - 用戶認證相關 Keychain 操作
    
    /// 儲存用戶登入令牌到 Keychain
    /// - Parameter token: 登入令牌
    func saveUserToken(_ token: String) {
        try? keychain.set(token, forKey: "userToken")
    }
    
    /// 從 Keychain 取得用戶登入令牌
    /// - Returns: 登入令牌，如果沒有則返回 nil
    func getUserToken() -> String? {
        return keychain.get(forKey: "userToken")
    }
    
    /// 儲存用戶密碼到 Keychain
    /// - Parameters:
    ///   - password: 用戶密碼
    ///   - username: 用戶名稱
    func saveUserPassword(_ password: String, for username: String) {
        try? keychain.set(password, forKey: "password_\(username)")
    }
    
    /// 從 Keychain 取得用戶密碼
    /// - Parameter username: 用戶名稱
    /// - Returns: 用戶密碼，如果沒有則返回 nil
    func getUserPassword(for username: String) -> String? {
        return keychain.get(forKey: "password_\(username)")
    }
    
    /// 清除所有用戶認證資訊
    func clearUserAuth() {
        keychain.removeValue(forKey: "userToken")
    }
    
    /// 清除特定用戶的密碼
    /// - Parameter username: 用戶名稱
    func clearUserPassword(for username: String) {
        keychain.removeValue(forKey: "password_\(username)")
    }
    
    /// 檢查是否已登入
    /// - Returns: 是否已登入
    func isUserLoggedIn() -> Bool {
        return keychain.containsValue(forKey: "userToken")
    }
} 
