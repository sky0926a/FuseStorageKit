# FuseStorageKit Usage Guide

Unified storage solution for iOS/macOS applications with database, file management, and preferences capabilities.

## Quick Start

```swift
import FuseStorageKit

// Build storage with required services
let storage = try FuseStorageBuilder()
    .with(database: .sqlite("app.db", encryptions: EncryptionOptions("secret")))
    .with(preferences: .keychain("com.myapp.secure"))
    .with(file: .document("AppFiles"))
    .build()

// Access services (use identical configuration)
let database = storage.db(.sqlite("app.db", encryptions: EncryptionOptions("secret")))!
let keychain = storage.pref(.keychain("com.myapp.secure"))!
let fileManager = storage.file(.document("AppFiles"))!

// Use immediately
try database.add(myRecord)
try keychain.set("value", forKey: "key")
let fileURL = try fileManager.save(data: myData, relativePath: "file.txt")
```

## Important: Storing FuseStorage

**You must retain the FuseStorage instance.** FuseStorage acts as a manager factory and cache - it holds all your configured managers internally. If you don't keep a reference to it, your managers will be deallocated.

```swift
class AppStorage {
    static let shared = AppStorage()
    
    private let storage: FuseStorage  // Keep this reference!
    
    private init() {
        storage = try! FuseStorageBuilder()
            .with(database: .sqlite("app.db"))
            .with(preferences: .userDefaults())
            .build()
    }
    
    var database: FuseDatabaseManageable {
        storage.db(.sqlite("app.db"))!
    }
}
```

## Core Concepts

### Configuration Consistency

The configuration used when building must exactly match the configuration used when accessing services:

```swift
// Build with encryption
let storage = try FuseStorageBuilder()
    .with(database: .sqlite("app.db", encryptions: EncryptionOptions("secret")))
    .build()

// Access with same encryption
let db = storage.db(.sqlite("app.db", encryptions: EncryptionOptions("secret")))!
```

### Service Types

- **Database**: SQLite operations with GRDB backend
- **Preferences**: UserDefaults and Keychain storage  
- **File**: File system operations
- **Sync**: Currently not implemented (only no-op available)

## Database Operations

### Define Model

```swift
struct Note: FuseDatabaseRecord {
    static var _fuseidField: String = "id"
    
    var id: String
    var title: String
    var content: String
    var createdAt: Date
    var hasAttachment: Bool
    var attachmentPath: String?
    
    static func tableDefinition() -> FuseTableDefinition {
        let columns: [FuseColumnDefinition] = [
            FuseColumnDefinition(name: "id", type: .text, isPrimaryKey: true, isNotNull: true),
            FuseColumnDefinition(name: "title", type: .text, isNotNull: true),
            FuseColumnDefinition(name: "content", type: .text, isNotNull: true),
            FuseColumnDefinition(name: "createdAt", type: .date, isNotNull: true),
            FuseColumnDefinition(name: "hasAttachment", type: .boolean, isNotNull: true, defaultValue: "0"),
            FuseColumnDefinition(name: "attachmentPath", type: .text)
        ]
        return FuseTableDefinition(name: "notes", columns: columns)
    }
}
```

### Basic Operations

```swift
let database = storage.db(.sqlite("app.db"))!

// Create table
try database.createTable(Note.tableDefinition())

// Insert single record
let note = Note(id: UUID().uuidString, title: "Title", content: "Content", createdAt: Date())
try database.add(note)

// Insert multiple records
try database.add([note1, note2, note3])

// Query all records
let notes: [Note] = try database.fetch(of: Note.self, filters: [], sort: nil, limit: nil, offset: nil)

// Query with filters
let filteredNotes: [Note] = try database.fetch(
    of: Note.self,
    filters: [FuseQueryFilter.like(field: "title", value: "%search%")],
    sort: FuseQuerySort(field: "createdAt", order: .descending),
    limit: nil,
    offset: nil
)

// Delete single record
try database.delete(note)

// Delete multiple records
try database.delete([note1, note2])

// Check table existence
let exists = try database.tableExists("notes")

// Raw query execution
let customQuery = FuseQuery(table: "notes", action: .select(fields: ["*"], filters: [], sort: nil))
let results: [Note] = try database.read(customQuery)
```

## File Management

```swift
let fileManager = storage.file(.document("AppFiles"))!

// Save binary data
let textData = "Hello, World!".data(using: .utf8)!
let textURL = try fileManager.save(data: textData, relativePath: "documents/greeting.txt")

// Save image
let image = UIImage(named: "photo")!
let imageURL = try fileManager.save(image: image, fileName: "attachments/image.jpg")

// Get absolute URL for relative path
let fileURL = fileManager.url(for: "documents/greeting.txt")

// Delete file
try fileManager.delete(relativePath: "documents/old-file.txt")
```

## Preferences Storage

### UserDefaults for General Settings

```swift
let preferences = storage.pref(.userDefaults())!

// Store values
try preferences.set("dark", forKey: "theme")
try preferences.set(14, forKey: "fontSize")
try preferences.set(true, forKey: "notifications")

// Retrieve values
let theme: String? = preferences.get(forKey: "theme")
let fontSize: Int? = preferences.get(forKey: "fontSize")
let notifications: Bool? = preferences.get(forKey: "notifications")

// Check existence
let hasTheme = preferences.containsValue(forKey: "theme")

// Remove value
preferences.removeValue(forKey: "theme")
```

### Keychain for Sensitive Data

```swift
let keychain = storage.pref(.keychain("com.myapp.secure"))!

// Store sensitive data
try keychain.set("user-token-12345", forKey: "authToken")
try keychain.set("super-secret-password", forKey: "userPassword")

// Retrieve sensitive data
let token: String? = keychain.get(forKey: "authToken")
let password: String? = keychain.get(forKey: "userPassword")

// Check existence
let isLoggedIn = keychain.containsValue(forKey: "authToken")

// Remove sensitive data
keychain.removeValue(forKey: "authToken")
```

### Complex Objects

```swift
struct UserPreferences: Codable {
    let theme: String
    let fontSize: Int
    let language: String
}

let userPrefs = UserPreferences(theme: "dark", fontSize: 14, language: "en")
try preferences.set(userPrefs, forKey: "userPreferences")
let savedPrefs: UserPreferences? = preferences.get(forKey: "userPreferences")
```

## Synchronization (Not Implemented)

Currently, only a no-operation sync manager is available:

```swift
let storage = try FuseStorageBuilder()
    .with(sync: .noSync())  // Only no-op implementation available
    .build()

let syncManager = storage.sync(.noSync())!
syncManager.startSync()  // Does nothing
syncManager.pushLocalChanges([], at: "path")  // Does nothing
syncManager.observeRemoteChanges(path: "path") { _ in }  // Never calls handler
```

Real synchronization features are not yet implemented.

## Configuration Examples

### Basic App

```swift
let storage = try FuseStorageBuilder()
    .with(database: .sqlite("app.db"))
    .with(preferences: .userDefaults())
    .with(file: .document("AppFiles"))
    .build()
```

### Secure App

```swift
let storage = try FuseStorageBuilder()
    .with(database: .sqlite("app.db", encryptions: EncryptionOptions("secret")))
    .with(preferences: .keychain("com.myapp.secure"))
    .with(preferences: .userDefaults()) // Multiple preferences supported
    .with(file: .document("AppFiles"))
    .build()
```

### Multiple File Locations

```swift
let storage = try FuseStorageBuilder()
    .with(file: .document("UserFiles"))
    .with(file: .library("AppData"))
    .with(file: .cache("TempFiles"))
    .build()

let userFiles = storage.file(.document("UserFiles"))!
let appData = storage.file(.library("AppData"))!
let cache = storage.file(.cache("TempFiles"))!
```

## Singleton Pattern

```swift
class AppStorage {
    static let shared = AppStorage()
    
    private let storage: FuseStorage
    
    private init() {
        storage = try! FuseStorageBuilder()
            .with(database: .sqlite("app.db", encryptions: EncryptionOptions("secret")))
            .with(preferences: .keychain("com.myapp.secure"))
            .with(preferences: .userDefaults())
            .with(file: .document("AppFiles"))
            .build()
        
        try! database.createTable(Note.tableDefinition())
    }
    
    var database: FuseDatabaseManageable {
        storage.db(.sqlite("app.db", encryptions: EncryptionOptions("secret")))!
    }
    
    var keychain: FusePreferencesManageable {
        storage.pref(.keychain("com.myapp.secure"))!
    }
    
    var preferences: FusePreferencesManageable {
        storage.pref(.userDefaults())!
    }
    
    var fileManager: FuseFileManageable {
        storage.file(.document("AppFiles"))!
    }
}
```

## Error Handling

```swift
// Safe access pattern
guard let database = storage.db(.sqlite("app.db")) else {
    throw StorageError.databaseNotFound
}

// Operation error handling
do {
    try database.add(note)
} catch {
    print("Failed to add note: \(error)")
}

do {
    let url = try fileManager.save(data: data, relativePath: "file.txt")
} catch {
    print("Failed to save file: \(error)")
}

do {
    try preferences.set(value, forKey: "key")
} catch {
    print("Failed to save preference: \(error)")
}
```

## API Reference

### FuseStorage Methods

```swift
public final class FuseStorage {
    public func db(_ query: FuseDatabaseBuilderOption) -> FuseDatabaseManageable?
    public func pref(_ query: FusePreferencesBuilderOption) -> FusePreferencesManageable?
    public func file(_ query: FuseFileBuilderOption) -> FuseFileManageable?
    public func sync(_ query: FuseSyncBuilderOption) -> FuseSyncManageable?
}
```

### Database Manager Methods

```swift
public protocol FuseDatabaseManageable {
    func tableExists(_ tableName: String) throws -> Bool
    func createTable(_ tableDefinition: FuseTableDefinition) throws
    func add<T: FuseDatabaseRecord>(_ record: T) throws
    func add<T: FuseDatabaseRecord>(_ records: [T]) throws
    func fetch<T: FuseDatabaseRecord>(of type: T.Type, filters: [FuseQueryFilter], sort: FuseQuerySort?, limit: Int?, offset: Int?) throws -> [T]
    func delete<T: FuseDatabaseRecord>(_ record: T) throws
    func delete<T: FuseDatabaseRecord>(_ records: [T]) throws
    func read<T: FuseDatabaseRecord>(_ query: FuseQuery) throws -> [T]
    func write(_ query: FuseQuery) throws
}
```

### Preferences Manager Methods

```swift
public protocol FusePreferencesManageable {
    func set<Value: Codable>(_ value: Value, forKey key: String) throws
    func get<Value: Codable>(forKey key: String) -> Value?
    func removeValue(forKey key: String)
    func containsValue(forKey key: String) -> Bool
}
```

### File Manager Methods

```swift
public protocol FuseFileManageable {
    func save(image: FuseImage, fileName: String) throws -> URL
    func save(data: Data, relativePath: String) throws -> URL
    func url(for relativePath: String) -> URL
    func delete(relativePath: String) throws
}
```

### Builder Options

```swift
// Database
.sqlite("path.db", encryptions: EncryptionOptions("secret"))
.custom("name", database: customDb)

// Preferences  
.userDefaults()
.userDefaults("suiteName")
.keychain("service", accessibility: .whenUnlocked)
.custom("name", preferences: customPrefs)

// File
.document("folder")
.library("folder") 
.cache("folder")
.custom("name", file: customFile)

// Sync (only no-op available)
.noSync()
```

## Installation

### Swift Package Manager

```swift
dependencies: [
    .package(url: "https://github.com/sky0926a/FuseStorageKit.git", from: "1.0.0")
]
```

### Import

```swift
import FuseStorageKit
```
