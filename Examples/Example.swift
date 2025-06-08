import FuseStorageKit  // Just import this to enable SQLCipher support

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
    
    static func tableDefinition() -> FuseTableDefinition {
        return FuseTableDefinition(
            name: User.databaseTableName,
            columns: [
                FuseColumnDefinition(name: "id", type: .integer, isPrimaryKey: true),
                FuseColumnDefinition(name: "name", type: .text, isNotNull: true),
                FuseColumnDefinition(name: "email", type: .text, isUnique: true),
                FuseColumnDefinition(name: "age", type: .integer)
            ]
        )
    }
}

// Usage example - completely seamless!
func exampleUsage() throws {
    // 1. Create database manager - SQLCipher support is automatically available
    let dbManager = try FuseDatabaseManager(path: "my_app.sqlite")
    
    // 2. Create table
   
    try dbManager.createTable(User.tableDefinition())
    
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
