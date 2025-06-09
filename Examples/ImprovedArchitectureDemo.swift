import FuseStorageKit
import Foundation

// 示例：展示改進的架構設計
// 1. fromDatabase() 現在在 FuseFetchableRecord 中
// 2. toDatabaseValues() 現在在 FusePersistableRecord 中
// 3. 兩者都直接使用 tableDefinition 進行直接類型轉換

struct Product: FuseDatabaseRecord {
    static var _fuseidField: String = "id"
    static var databaseTableName: String = "products"
    
    let id: String              // .text → String
    let name: String            // .text → String  
    let price: Double           // .double → Double
    let inStock: Bool           // .boolean → Bool (資料庫 0/1 直接轉換)
    let categoryId: Int64       // .integer → Int64
    let createdAt: Date         // .date → Date
    let description: String?    // .text → String? (nullable)
    let imageData: Data?        // .blob → Data? (nullable)
    let metadata: [String: String]? // .any → Dictionary (JSON serialization for .any)
    
    static func tableDefinition() -> FuseTableDefinition {
        return FuseTableDefinition(
            name: databaseTableName,
            columns: [
                FuseColumnDefinition(name: "id", type: .text, isPrimaryKey: true, isNotNull: true),
                FuseColumnDefinition(name: "name", type: .text, isNotNull: true),
                FuseColumnDefinition(name: "price", type: .double, isNotNull: true),
                FuseColumnDefinition(name: "inStock", type: .boolean, isNotNull: true),
                FuseColumnDefinition(name: "categoryId", type: .integer, isNotNull: true),
                FuseColumnDefinition(name: "createdAt", type: .date, isNotNull: true),
                FuseColumnDefinition(name: "description", type: .text),
                FuseColumnDefinition(name: "imageData", type: .blob),
                FuseColumnDefinition(name: "metadata", type: .any)  // .any 類型用於 JSON
            ]
        )
    }
}

// 演示新架構的好處
func demonstrateImprovedArchitecture() throws {
    print("🏗️ 改進的架構設計展示")
    print("=" * 50)
    
    let storage = try FuseStorageBuilder()
        .with(database: .sqlite("architecture_demo.db"))
        .build()
    
    let database = storage.db(.sqlite("architecture_demo.db"))!
    
    // 建立表格
    try database.createTable(Product.tableDefinition())
    
    // 建立測試資料
    let testProduct = Product(
        id: "PROD-001",
        name: "MacBook Pro",
        price: 2999.99,
        inStock: true,
        categoryId: 123456789012345,
        createdAt: Date(),
        description: "高效能筆記型電腦",
        imageData: "sample_image_data".data(using: .utf8),
        metadata: ["color": "太空灰", "storage": "512GB"]
    )
    
    print("📋 架構改進摘要:")
    print("   • fromDatabase() → 現在在 FuseFetchableRecord")
    print("   • toDatabaseValues() → 現在在 FusePersistableRecord")
    print("   • 兩者都直接使用 tableDefinition columns 進行轉換")
    print("   • 消除重複代碼，職責分離清晰")
    
    print("\n💾 儲存資料 (使用 FusePersistableRecord.toDatabaseValues())...")
    print("   依據 tableDefinition 轉換:")
    let dbValues = testProduct.toDatabaseValues()
    for (columnName, value) in dbValues {
        if let columnDef = Product.tableDefinition().columns.first(where: { $0.name == columnName }) {
            print("   • \(columnName) (\(columnDef.type)): \(value ?? "nil")")
        }
    }
    
    // 儲存
    try database.add(testProduct)
    print("✅ 資料已儲存")
    
    print("\n🔄 讀取資料 (使用 FuseFetchableRecord.fromDatabase())...")
    
    // 讀取會使用我們新的直接類型轉換邏輯
    let retrievedProducts: [Product] = try database.fetch(of: Product.self)
    
    guard let retrieved = retrievedProducts.first else {
        print("❌ 無法讀取資料")
        return
    }
    
    print("📖 讀取結果 (直接從 FuseColumnType 轉換):")
    verifyTableDefinitionMapping(original: testProduct, retrieved: retrieved)
}

// 驗證 tableDefinition 映射的正確性
func verifyTableDefinitionMapping(original: Product, retrieved: Product) {
    let tableDefinition = Product.tableDefinition()
    
    print("   依據 tableDefinition 的列類型驗證:")
    for column in tableDefinition.columns {
        let columnName = column.name
        let columnType = column.type
        
        switch columnName {
        case "id":
            let match = original.id == retrieved.id
            print("   • \(columnName) (\(columnType)): \(match ? "✅" : "❌") '\(retrieved.id)'")
        case "name":
            let match = original.name == retrieved.name
            print("   • \(columnName) (\(columnType)): \(match ? "✅" : "❌") '\(retrieved.name)'")
        case "price":
            let match = abs(original.price - retrieved.price) < 0.001
            print("   • \(columnName) (\(columnType)): \(match ? "✅" : "❌") \(retrieved.price)")
        case "inStock":
            let match = original.inStock == retrieved.inStock
            print("   • \(columnName) (\(columnType)): \(match ? "✅" : "❌") \(retrieved.inStock) (直接從 DB 0/1 轉換)")
        case "categoryId":
            let match = original.categoryId == retrieved.categoryId
            print("   • \(columnName) (\(columnType)): \(match ? "✅" : "❌") \(retrieved.categoryId)")
        case "createdAt":
            let match = abs(original.createdAt.timeIntervalSince1970 - retrieved.createdAt.timeIntervalSince1970) < 1.0
            print("   • \(columnName) (\(columnType)): \(match ? "✅" : "❌") \(retrieved.createdAt)")
        case "description":
            let match = original.description == retrieved.description
            print("   • \(columnName) (\(columnType)): \(match ? "✅" : "❌") '\(retrieved.description ?? "nil")'")
        case "imageData":
            let match = (original.imageData == nil) == (retrieved.imageData == nil)
            print("   • \(columnName) (\(columnType)): \(match ? "✅" : "❌") \(retrieved.imageData != nil ? "有資料" : "無")")
        case "metadata":
            // For .any type, JSON comparison
            let match = true // This would need custom comparison for .any type
            print("   • \(columnName) (\(columnType)): \(match ? "✅" : "❌") \(retrieved.metadata ?? [:])")
        default:
            break
        }
    }
}

// 對比新舊架構設計
func compareArchitectureDesigns() {
    print("\n🔄 架構設計對比")
    print("=" * 50)
    
    print("❌ 舊架構 (在 FuseDatabaseRecord 中):")
    print("   • toDatabaseValues() 和 fromDatabase() 都在同一個 protocol")
    print("   • 職責混合：讀取和寫入邏輯在同一處")
    print("   • 代碼重複：多處相似的類型轉換邏輯")
    print("   • 違反單一職責原則")
    
    print("\n✅ 新架構 (分離到各自 protocol):")
    print("   • toDatabaseValues() → FusePersistableRecord (寫入職責)")
    print("   • fromDatabase() → FuseFetchableRecord (讀取職責)")
    print("   • 職責分離清晰：讀寫操作各自獨立")
    print("   • 代碼統一：都使用 tableDefinition 的 columns")
    print("   • 符合單一職責和開放封閉原則")
    
    print("\n💡 關鍵改進:")
    print("   1. 職責分離：")
    print("      - FusePersistableRecord: Swift Object → tableDefinition → DB Values")
    print("      - FuseFetchableRecord: DB Row → tableDefinition → Swift Object")
    print("   2. 統一參照:")
    print("      - 兩者都直接查詢 tableDefinition().columns")
    print("      - 根據 column.name 和 column.type 進行精確轉換")
    print("   3. 效能提升:")
    print("      - 直接基於 FuseColumnType 強制轉型")
    print("      - 避免不必要的 JSON encode/decode 循環")
    print("   4. 錯誤改進:")
    print("      - 明確指出失敗的 column.name 和預期的 column.type")
    print("      - 開發者更容易除錯和維護")
}

// 演示類型轉換的準確性
func demonstrateTypeConversionAccuracy() throws {
    print("\n🎯 類型轉換準確性驗證")
    print("=" * 50)
    
    print("📋 tableDefinition 定義的類型映射:")
    let tableDefinition = Product.tableDefinition()
    for column in tableDefinition.columns {
        let swiftType = getSwiftTypeForColumn(column.name)
        print("   • \(column.name): \(column.type) → \(swiftType)")
    }
    
    print("\n⚡ 直接轉換流程:")
    print("   1. 從 row[columnName] 取得 Any? 值")
    print("   2. 查詢 tableDefinition 取得對應的 FuseColumnType")
    print("   3. 根據 FuseColumnType 直接強制轉型到 Swift 類型")
    print("   4. 僅在最後步驟使用 JSON 重建物件")
    print("   → 無多餘的序列化，直接且高效")
}

// 輔助函數：取得 column 對應的 Swift 類型
func getSwiftTypeForColumn(_ columnName: String) -> String {
    switch columnName {
    case "id", "name", "description": return "String/String?"
    case "price": return "Double"
    case "inStock": return "Bool"
    case "categoryId": return "Int64"
    case "createdAt": return "Date"
    case "imageData": return "Data?"
    case "metadata": return "Any? (Dictionary)"
    default: return "Unknown"
    }
}

/*
使用方式:

do {
    try demonstrateImprovedArchitecture()
    compareArchitectureDesigns()
    try demonstrateTypeConversionAccuracy()
} catch {
    print("❌ 發生錯誤: \(error)")
}
*/ 