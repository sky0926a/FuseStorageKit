import Foundation
import FuseStorageKit

// 🎉 簡化的實作：用戶只需要實現 FuseDatabaseRecord
// SDK 自動提供 GRDB 的 FetchableRecord 和 PersistableRecord 符合性
struct Note: FuseDatabaseRecord {
    static var _fuseidField: String = "id"
    
    var id: String
    var title: String
    var content: String
    var createdAt: Date
    var hasAttachment: Bool
    var attachmentPath: String?
    
    init(id: String = UUID().uuidString, 
         title: String, 
         content: String, 
         createdAt: Date = Date(),
         hasAttachment: Bool = false, 
         attachmentPath: String? = nil) {
        self.id = id
        self.title = title
        self.content = content
        self.createdAt = createdAt
        self.hasAttachment = hasAttachment
        self.attachmentPath = attachmentPath
    }
    
    static var databaseTableName: String { return "notes" }
    
    // 欄位名稱定義，方便在代碼中使用
    enum Field {
        static let id = "id" 
        static let title = "title"
        static let content = "content"
        static let createdAt = "createdAt"
        static let hasAttachment = "hasAttachment"
        static let attachmentPath = "attachmentPath"
    }
    
    // MARK: - 表格定義
    
    /// 取得 Note 表格的定義
    /// - Returns: 表格定義
    static func tableDefinition() -> FuseTableDefinition {
        let columns: [FuseColumnDefinition] = [
            FuseColumnDefinition(name: Field.id, type: .text, isPrimaryKey: true, isNotNull: true),
            FuseColumnDefinition(name: Field.title, type: .text, isNotNull: true),
            FuseColumnDefinition(name: Field.content, type: .text, isNotNull: true),
            FuseColumnDefinition(name: Field.createdAt, type: .date, isNotNull: true),
            FuseColumnDefinition(name: Field.hasAttachment, type: .boolean, isNotNull: true, defaultValue: "0"),
            FuseColumnDefinition( name: Field.attachmentPath, type: .text)
        ]
        
        return FuseTableDefinition(
            name: databaseTableName,
            columns: columns
        )
    }
}
