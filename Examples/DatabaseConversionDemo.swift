import FuseStorageKit
import Foundation

// 示例：展示 fromDatabase 與 tableDefinition 的完美協同

struct Employee: FuseDatabaseRecord {
    static var _fuseidField: String = "id"
    static var databaseTableName: String = "employees"
    
    let id: String
    let name: String
    let age: Int64
    let salary: Double
    let isActive: Bool
    let hiredDate: Date
    let department: String?
    let profilePhoto: Data?
    
    static func tableDefinition() -> FuseTableDefinition {
        return FuseTableDefinition(
            name: databaseTableName,
            columns: [
                FuseColumnDefinition(name: "id", type: .text, isPrimaryKey: true, isNotNull: true),
                FuseColumnDefinition(name: "name", type: .text, isNotNull: true),
                FuseColumnDefinition(name: "age", type: .integer, isNotNull: true),
                FuseColumnDefinition(name: "salary", type: .double, isNotNull: true),
                FuseColumnDefinition(name: "isActive", type: .boolean, isNotNull: true),
                FuseColumnDefinition(name: "hiredDate", type: .date, isNotNull: true),
                FuseColumnDefinition(name: "department", type: .text),  // 可選
                FuseColumnDefinition(name: "profilePhoto", type: .blob) // 可選
            ]
        )
    }
}

// 示例：對比有/無 tableDefinition 指導的轉換效果

func demonstrateTableDefinitionGuidedConversion() throws {
    let storage = try FuseStorageBuilder()
        .with(database: .sqlite("conversion_demo.db"))
        .build()
    
    let database = storage.db(.sqlite("conversion_demo.db"))!
    
    // 建立表格
    try database.createTable(Employee.tableDefinition())
    
    print("🏗️ 展示 toDatabaseValues 與 fromDatabase 的對稱性")
    print("=" * 60)
    
    // 1. 建立測試資料
    let originalEmployee = Employee(
        id: "EMP001",
        name: "張小明",
        age: 28,
        salary: 75000.50,
        isActive: true,
        hiredDate: Date(),
        department: "軟體開發部",
        profilePhoto: "fake_photo_data".data(using: .utf8)
    )
    
    print("📝 原始資料:")
    printEmployeeDetails(originalEmployee, prefix: "   ")
    
    // 2. 透過 toDatabaseValues 轉換 (使用 tableDefinition)
    print("\n🔄 toDatabaseValues 轉換 (參考 tableDefinition):")
    let databaseValues = originalEmployee.toDatabaseValues()
    for (key, value) in databaseValues.sorted(by: { $0.key < $1.key }) {
        let typeInfo = getColumnTypeInfo(for: key, in: Employee.tableDefinition())
        print("   \(key): \(value ?? "nil") → 資料庫型別: \(typeInfo)")
    }
    
    // 3. 儲存到資料庫
    try database.add(originalEmployee)
    print("\n💾 資料已儲存到資料庫")
    
    // 4. 從資料庫讀取 (使用 fromDatabase 與 tableDefinition)
    print("\n🔍 fromDatabase 轉換 (參考 tableDefinition):")
    let retrievedEmployees: [Employee] = try database.fetch(of: Employee.self)
    
    guard let retrievedEmployee = retrievedEmployees.first else {
        print("❌ 無法讀取資料")
        return
    }
    
    print("📖 讀取的資料:")
    printEmployeeDetails(retrievedEmployee, prefix: "   ")
    
    // 5. 驗證資料完整性
    print("\n✅ 資料完整性驗證:")
    verifyDataIntegrity(original: originalEmployee, retrieved: retrievedEmployee)
}

// 輔助函數：取得欄位的型別資訊
func getColumnTypeInfo(for columnName: String, in tableDefinition: FuseTableDefinition) -> String {
    if let column = tableDefinition.columns.first(where: { $0.name == columnName }) {
        return "\(column.type)"
    }
    return "未定義"
}

// 輔助函數：列印員工詳細資訊
func printEmployeeDetails(_ employee: Employee, prefix: String) {
    print("\(prefix)ID: \(employee.id)")
    print("\(prefix)姓名: \(employee.name)")
    print("\(prefix)年齡: \(employee.age)")
    print("\(prefix)薪資: \(employee.salary)")
    print("\(prefix)在職: \(employee.isActive)")
    print("\(prefix)雇用日期: \(employee.hiredDate)")
    print("\(prefix)部門: \(employee.department ?? "未指定")")
    print("\(prefix)有照片: \(employee.profilePhoto != nil)")
}

// 輔助函數：驗證資料完整性
func verifyDataIntegrity(original: Employee, retrieved: Employee) {
    let checks: [(String, Bool)] = [
        ("ID", original.id == retrieved.id),
        ("姓名", original.name == retrieved.name),
        ("年齡", original.age == retrieved.age),
        ("薪資", abs(original.salary - retrieved.salary) < 0.01),
        ("在職狀態", original.isActive == retrieved.isActive),
        ("雇用日期", abs(original.hiredDate.timeIntervalSince1970 - retrieved.hiredDate.timeIntervalSince1970) < 1.0),
        ("部門", original.department == retrieved.department),
        ("照片資料", (original.profilePhoto == nil) == (retrieved.profilePhoto == nil))
    ]
    
    var allPassed = true
    for (field, passed) in checks {
        let status = passed ? "✅" : "❌"
        print("   \(status) \(field): \(passed ? "一致" : "不一致")")
        if !passed { allPassed = false }
    }
    
    print("\n🎯 整體結果: \(allPassed ? "✅ 所有資料完美保持一致！" : "❌ 發現資料不一致")")
}

// 演示型別安全轉換的詳細步驟
func demonstrateTypeSafeConversionSteps() {
    print("\n🔬 深入解析：tableDefinition 指導的轉換流程")
    print("=" * 60)
    
    let tableDefinition = Employee.tableDefinition()
    
    print("📋 tableDefinition 定義的欄位:")
    for column in tableDefinition.columns {
        let nullability = column.isNotNull ? "NOT NULL" : "NULLABLE"
        let primaryKey = column.isPrimaryKey ? " (PRIMARY KEY)" : ""
        print("   • \(column.name): \(column.type) \(nullability)\(primaryKey)")
    }
    
    print("\n🔄 轉換流程說明:")
    print("   1. toDatabaseValues():")
    print("      Swift Object → 查閱 tableDefinition → 按型別轉換 → Database Values")
    print("   2. fromDatabase():")
    print("      Database Row → 查閱 tableDefinition → 按型別轉換 → Swift Object")
    
    print("\n💡 這種設計的好處:")
    print("   ✅ 型別安全：轉換基於明確定義，不是猜測")
    print("   ✅ 一致性：存儲和讀取使用相同的型別對應規則")
    print("   ✅ 可預測：開發者完全控制資料型別處理")
    print("   ✅ 可維護：型別變更只需修改 tableDefinition")
    print("   ✅ 高效能：減少試探性轉換和錯誤處理")
}

// 演示錯誤處理情況
func demonstrateErrorHandling() throws {
    print("\n🚨 錯誤處理演示")
    print("=" * 60)
    
    // 故意建立一個有問題的資料結構來測試錯誤處理
    struct CorruptedData: FuseDatabaseRecord {
        static var _fuseidField: String = "id"
        static var databaseTableName: String = "corrupted_test"
        
        let id: String
        let invalidBoolField: Bool  // 這個欄位在 tableDefinition 中會被錯誤定義
        
        static func tableDefinition() -> FuseTableDefinition {
            return FuseTableDefinition(
                name: databaseTableName,
                columns: [
                    FuseColumnDefinition(name: "id", type: .text, isPrimaryKey: true),
                    FuseColumnDefinition(name: "invalidBoolField", type: .text)  // 錯誤：應該是 .boolean
                ]
            )
        }
    }
    
    print("⚠️  當 tableDefinition 與實際資料型別不匹配時:")
    print("   1. fromDatabase 會嘗試按照 tableDefinition 轉換")
    print("   2. 如果轉換失敗，會提供清楚的錯誤訊息")
    print("   3. 錯誤訊息會指出是哪個欄位的型別不匹配")
    print("   4. 開發者可以修正 tableDefinition 或資料型別")
}

/*
使用方式:

do {
    try demonstrateTableDefinitionGuidedConversion()
    demonstrateTypeSafeConversionSteps()
    try demonstrateErrorHandling()
} catch {
    print("❌ 發生錯誤: \(error)")
}
*/ 