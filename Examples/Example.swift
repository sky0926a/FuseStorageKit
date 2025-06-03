import FuseStorageCore
import FuseStorageSQLCipher  // Just import this to enable SQLCipher support

// Define your data model
struct User: FuseDatabaseRecord {
    static var _fuseidField: String = "id"
    static var databaseTableName: String = "users"
    
    let id: Int64
    let name: String
    let email: String
    let age: Int
    
    init(id: Int64, name: String, email: String, age: Int) {
        self.id = id
        self.name = name
        self.email = email
        self.age = age
    }
}

// Usage example - completely seamless!
func exampleUsage() throws {
    // 1. Create database manager - SQLCipher support is automatically available
    let dbManager = try FuseDatabaseManager(path: "my_app.sqlite")
    
    // 2. Create table
    let tableDefinition = FuseTableDefinition(
        name: User.databaseTableName,
        columns: [
            FuseColumnDefinition(name: "id", type: .integer, isPrimaryKey: true),
            FuseColumnDefinition(name: "name", type: .text, isNotNull: true),
            FuseColumnDefinition(name: "email", type: .text, isUnique: true),
            FuseColumnDefinition(name: "age", type: .integer)
        ]
    )
    try dbManager.createTable(tableDefinition)
    
    // 3. Add users
    let user1 = User(id: 1, name: "Alice", email: "alice@example.com", age: 30)
    let user2 = User(id: 2, name: "Bob", email: "bob@example.com", age: 25)
    
    try dbManager.add(user1)
    try dbManager.add(user2)
    
    // 4. Fetch users
    let allUsers: [User] = try dbManager.fetch(of: User.self)
    print("All users: \(allUsers)")
    
    // 5. Fetch with filters
    let youngUsers: [User] = try dbManager.fetch(
        of: User.self,
        filters: [FuseQueryFilter.lessThan(field: "age", value: 30)]
    )
    print("Young users: \(youngUsers)")
    
    // 6. With encryption (also seamless!)
    let encryptedDbManager = try FuseDatabaseManager(
        path: "encrypted_app.sqlite",
        encryptions: EncryptionOptions(passphrase: "my_secret_key")
    )
    
    print("Database operations completed successfully!")
}

/*
 Key Benefits:
 
 1. 💫 **完全無感使用**: 用戶只需要 import FuseStorageSQLCipher，SQLCipher 支援就會自動啟用
 2. 🔄 **自動註冊**: 不需要任何手動註冊或初始化代碼
 3. 🏗️ **模組化設計**: 核心功能在 FuseStorageCore，具體實作在 FuseStorageSQLCipher
 4. 🔒 **加密支援**: 自動支援 SQLCipher 加密，無需額外設定
 5. 🧩 **Extension 不能覆蓋**: 使用 Registry 模式而非 extension 覆蓋避免 Swift 限制
 
 Architecture:
 
 FuseStorageCore (定義接口):
 ├── FuseDatabaseFactory (protocol)
 ├── FuseDatabaseProxyFactory (使用 Registry)
 └── FuseDatabaseFactoryRegistry (註冊機制)
 
 FuseStorageSQLCipher (提供實作):
 ├── GRDBSQLCipherDatabaseFactory (具體實作)
 ├── FuseStorageSQLCipherAutoRegister (自動註冊)
 └── GRDB Extensions (FuseDatabaseRecord 實作)
 */ 