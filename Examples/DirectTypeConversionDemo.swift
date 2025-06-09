import FuseStorageKit
import Foundation

// 示例：展示直接基於 FuseColumnType 的類型轉換

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
    let metadata: Any?          // .any → Any? (不做轉換，保持原樣)
    
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
                FuseColumnDefinition(name: "metadata", type: .any)  // 特殊：.any 類型
            ]
        )
    }
}

// 演示直接類型轉換的好處
func demonstrateDirectTypeConversion() throws {
    print("🎯 直接基於 FuseColumnType 的類型轉換")
    print("=" * 50)
    
    let storage = try FuseStorageBuilder()
        .with(database: .sqlite("direct_conversion_demo.db"))
        .build()
    
    let database = storage.db(.sqlite("direct_conversion_demo.db"))!
    
    // 建立表格
    try database.createTable(Product.tableDefinition())
    
    // 建立測試資料，包含各種類型
    let testProduct = Product(
        id: "PROD-001",
        name: "iPhone 15 Pro",
        price: 999.99,
        inStock: true,                // Bool → 資料庫會存為 1
        categoryId: 123456789012345,  // Int64 → 資料庫存為大整數
        createdAt: Date(),            // Date → 資料庫存為時間戳
        description: "最新型號",
        imageData: "fake_image_data".data(using: .utf8),
        metadata: ["color": "深空灰", "storage": "256GB"] // Dictionary → .any 類型
    )
    
    print("📝 儲存測試資料...")
    print("   Bool值: \(testProduct.inStock) (會存為資料庫的 1)")
    print("   大整數: \(testProduct.categoryId)")
    print("   日期: \(testProduct.createdAt)")
    print("   .any 資料: \(testProduct.metadata ?? "nil")")
    
    // 儲存
    try database.add(testProduct)
    print("✅ 資料已儲存")
    
    print("\n🔄 從資料庫讀取並進行直接類型轉換...")
    
    // 這裡會使用我們新的直接類型轉換邏輯
    let retrievedProducts: [Product] = try database.fetch(of: Product.self)
    
    guard let retrieved = retrievedProducts.first else {
        print("❌ 無法讀取資料")
        return
    }
    
    print("📖 讀取結果 (直接類型轉換):")
    print("   ID: '\(retrieved.id)' (資料庫 String → Swift String)")
    print("   名稱: '\(retrieved.name)' (資料庫 String → Swift String)")
    print("   價格: \(retrieved.price) (資料庫 Double → Swift Double)")
    print("   庫存: \(retrieved.inStock) (資料庫 1 → Swift true) ✨")
    print("   分類ID: \(retrieved.categoryId) (資料庫 Int64 → Swift Int64)")
    print("   建立時間: \(retrieved.createdAt) (資料庫時間戳 → Swift Date)")
    print("   描述: '\(retrieved.description ?? "nil")' (資料庫 String? → Swift String?)")
    print("   圖片資料: \(retrieved.imageData != nil ? "有資料" : "無") (資料庫 Data? → Swift Data?)")
    print("   元資料: \(retrieved.metadata ?? "nil") (.any 類型保持原樣)")
    
    // 驗證類型轉換的準確性
    print("\n✅ 類型轉換驗證:")
    verifyTypeConversion(original: testProduct, retrieved: retrieved)
}

// 驗證類型轉換的準確性
func verifyTypeConversion(original: Product, retrieved: Product) {
    let checks: [(String, Bool)] = [
        ("String ID", original.id == retrieved.id),
        ("String 名稱", original.name == retrieved.name),
        ("Double 價格", abs(original.price - retrieved.price) < 0.001),
        ("Bool 庫存", original.inStock == retrieved.inStock),  // 關鍵：Bool 轉換
        ("Int64 分類", original.categoryId == retrieved.categoryId),
        ("Date 時間", abs(original.createdAt.timeIntervalSince1970 - retrieved.createdAt.timeIntervalSince1970) < 1.0),
        ("Optional 描述", original.description == retrieved.description),
        ("Optional 資料", (original.imageData == nil) == (retrieved.imageData == nil))
    ]
    
    for (testName, passed) in checks {
        let status = passed ? "✅" : "❌"
        print("   \(status) \(testName): \(passed ? "正確" : "錯誤")")
    }
}

// 對比新舊轉換方式的差異
func compareConversionApproaches() {
    print("\n🔬 轉換方式對比")
    print("=" * 50)
    
    print("🔄 舊方式 (透過 JSON encode/decode):")
    print("   1. 資料庫 row[columnName] → Any?")
    print("   2. 粗略轉換 → [String: Any?]") 
    print("   3. JSON 序列化 → Data")
    print("   4. JSON 反序列化 → Swift Object")
    print("   ❌ 問題：多餘的序列化步驟，效能損失")
    print("   ❌ 問題：依賴 JSON 轉換的限制和錯誤")
    
    print("\n⚡ 新方式 (直接基於 FuseColumnType):")
    print("   1. 資料庫 row[columnName] → Any?")
    print("   2. 查閱 tableDefinition → FuseColumnType")
    print("   3. 直接強制轉型 → 正確的 Swift 類型")
    print("   4. 僅最後步驟使用 JSON 重建物件")
    print("   ✅ 優勢：直接、高效的類型轉換")
    print("   ✅ 優勢：更準確的錯誤處理")
    print("   ✅ 優勢：減少不必要的序列化開銷")
    
    print("\n💡 關鍵改進:")
    print("   • .boolean → 資料庫 0/1 直接轉為 Swift Bool")
    print("   • .integer → 資料庫 Int64 直接轉為 Swift Int64")
    print("   • .double → 資料庫 Double 直接轉為 Swift Double") 
    print("   • .date → 資料庫時間戳直接轉為 Swift Date")
    print("   • .blob → 資料庫 Data 直接轉為 Swift Data")
    print("   • .text → 資料庫 String 直接轉為 Swift String")
    print("   • .any → 保持原樣，最大彈性")
}

// 演示錯誤處理的改進
func demonstrateImprovedErrorHandling() throws {
    print("\n🚨 改進的錯誤處理")
    print("=" * 50)
    
    // 模擬各種錯誤情況
    print("💡 新的錯誤處理優勢:")
    print("   1. 精確的錯誤訊息：指出具體的欄位和期望類型")
    print("   2. 更早的錯誤發現：在類型轉換階段就發現問題")
    print("   3. 更清楚的除錯資訊：知道是哪個 FuseColumnType 轉換失敗")
    
    print("\n🔍 錯誤訊息示例:")
    print("   ❌ 舊方式: 'DecodingError: Cannot decode Bool from JSON'")
    print("   ✅ 新方式: 'Cannot convert value '999' to Bool for column 'isActive''")
    print("   → 開發者立即知道是 'isActive' 欄位的 Bool 轉換問題")
    
    print("\n📋 支援的類型轉換:")
    let typeConversions = [
        ".text": "Any → String (使用 String(describing:))",
        ".integer": "Int/Int64/String → Int64", 
        ".double/.real": "Double/Float/Int/String → Double",
        ".boolean": "Bool/Int/String → Bool (0/1, true/false)",
        ".date": "Date/Double/String → Date (支援多種格式)",
        ".blob": "Data/String → Data (支援 base64)",
        ".any": "保持原樣，不做轉換"
    ]
    
    for (type, conversion) in typeConversions {
        print("   • \(type): \(conversion)")
    }
}

/*
使用方式:

do {
    try demonstrateDirectTypeConversion()
    compareConversionApproaches()
    try demonstrateImprovedErrorHandling()
} catch {
    print("❌ 發生錯誤: \(error)")
}
*/ 