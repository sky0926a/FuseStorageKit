import FuseStorageKit
import Foundation

// 示例：展示使用 tableDefinition 進行安全類型轉換的好處

struct Product: FuseDatabaseRecord {
    static var _fuseidField: String = "id"
    static var databaseTableName: String = "products"
    
    let id: String
    let name: String
    let price: Double
    let inStock: Bool              // 布林值欄位
    let categoryId: Int64          // 整數欄位
    let createdAt: Date           // 日期欄位
    let description: String?      // 可選字串欄位
    let imageData: Data?          // 可選二進位資料
    
    static func tableDefinition() -> FuseTableDefinition {
        return FuseTableDefinition(
            name: databaseTableName,
            columns: [
                FuseColumnDefinition(name: "id", type: .text, isPrimaryKey: true, isNotNull: true),
                FuseColumnDefinition(name: "name", type: .text, isNotNull: true),
                FuseColumnDefinition(name: "price", type: .double, isNotNull: true),
                FuseColumnDefinition(name: "inStock", type: .boolean, isNotNull: true),  // 明確定義為布林值
                FuseColumnDefinition(name: "categoryId", type: .integer, isNotNull: true),
                FuseColumnDefinition(name: "createdAt", type: .date, isNotNull: true),
                FuseColumnDefinition(name: "description", type: .text),  // 可選
                FuseColumnDefinition(name: "imageData", type: .blob)     // 可選
            ]
        )
    }
}

// 測試資料轉換的安全性
func demonstrateSafeTypeConversion() throws {
    let storage = try FuseStorageBuilder()
        .with(database: .sqlite("safe_conversion_demo.db"))
        .build()
    
    let database = storage.db(.sqlite("safe_conversion_demo.db"))!
    
    // 建立表格
    try database.createTable(Product.tableDefinition())
    
    // 測試資料
    let product = Product(
        id: "prod-001",
        name: "iPhone 15 Pro",
        price: 999.99,
        inStock: true,                    // 布林值會正確轉換為資料庫的 0/1
        categoryId: 123456789,            // 大整數會正確處理
        createdAt: Date(),                // 日期會正確格式化
        description: "Latest iPhone model",
        imageData: "sample data".data(using: .utf8)
    )
    
    // 儲存
    try database.add(product)
    print("✅ Product saved successfully")
    
    // 讀取 - 這裡會使用 tableDefinition 進行安全的類型轉換
    let products: [Product] = try database.fetch(of: Product.self)
    
    if let retrievedProduct = products.first {
        print("📖 Retrieved product:")
        print("   ID: \(retrievedProduct.id)")
        print("   Name: \(retrievedProduct.name)")
        print("   Price: \(retrievedProduct.price)")
        print("   In Stock: \(retrievedProduct.inStock)")           // 資料庫的 0/1 正確轉換回 Bool
        print("   Category ID: \(retrievedProduct.categoryId)")     // 正確的整數類型
        print("   Created At: \(retrievedProduct.createdAt)")       // 正確的日期
        print("   Description: \(retrievedProduct.description ?? "nil")")
        print("   Has Image Data: \(retrievedProduct.imageData != nil)")
        
        // 驗證類型
        assert(retrievedProduct.inStock == product.inStock, "Boolean conversion should be accurate")
        assert(retrievedProduct.categoryId == product.categoryId, "Integer conversion should be accurate")
        assert(abs(retrievedProduct.createdAt.timeIntervalSince1970 - product.createdAt.timeIntervalSince1970) < 1.0, "Date conversion should be accurate")
        
        print("✅ All type conversions are accurate!")
    }
}

// 對比：沒有 tableDefinition 指導的危險轉換
struct UnsafeProduct: FuseDatabaseRecord {
    static var _fuseidField: String = "id"
    static var databaseTableName: String = "unsafe_products"
    
    let id: String
    let name: String
    let inStock: Bool
    
    // 沒有提供準確的 tableDefinition，或者類型定義錯誤
    static func tableDefinition() -> FuseTableDefinition {
        return FuseTableDefinition(
            name: databaseTableName,
            columns: [
                FuseColumnDefinition(name: "id", type: .text, isPrimaryKey: true),
                FuseColumnDefinition(name: "name", type: .text),
                FuseColumnDefinition(name: "inStock", type: .text),  // 錯誤：應該是 .boolean
            ]
        )
    }
}

// 比較不同轉換策略的效果
func compareConversionStrategies() {
    print("\n🔍 比較轉換策略的效果:")
    print("==========================================")
    
    // 安全轉換 (使用正確的 tableDefinition)
    print("✅ 安全轉換 (基於 tableDefinition):")
    print("   - 布林值: 資料庫 1 → Swift true")
    print("   - 整數: 資料庫 Int64 → Swift Int64/Int")
    print("   - 日期: 資料庫字串/時間戳 → Swift Date")
    print("   - 可選值: 資料庫 NULL → Swift nil")
    
    // 不安全轉換 (依賴猜測)
    print("\n❌ 不安全轉換 (依賴名稱猜測):")
    print("   - 布林值: 依賴欄位名稱包含 'is', 'has' 等")
    print("   - 可能誤判非布林欄位為布林")
    print("   - 無法處理自訂欄位名稱")
    
    print("\n💡 改進效果:")
    print("   1. 精確的類型轉換 - 基於明確定義，不是猜測")
    print("   2. 更好的錯誤處理 - 知道預期的類型")
    print("   3. 更高的效能 - 減少試探性轉換")
    print("   4. 更強的類型安全 - 編譯時檢查")
}

/*
使用方式:

do {
    try demonstrateSafeTypeConversion()
    compareConversionStrategies()
} catch {
    print("❌ Error: \(error)")
}
*/ 