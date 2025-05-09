import Foundation
import FuseStorageKit

// 實現 FuseDatabaseRecord 協議
struct Note: FuseDatabaseRecord, Identifiable {
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
    
    // FuseDatabaseRecord 協議已經繼承自 Codable, FetchableRecord, PersistableRecord
    // 因此這些屬性會自動對應到資料庫中的欄位
    // 但我們需要一些常量用於查詢
    
    static let databaseTableName = "notes"
    
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
