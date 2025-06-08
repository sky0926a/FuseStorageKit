# FuseStorageKit Usage Guide

Complete usage guide for FuseStorageKit unified storage solution, centered around `FuseStorage` as the core interface.

## Table of Contents

- [🚀 Quick Start](#-quick-start)
- [💡 Core Concepts](#-core-concepts)
- [⚙️ Installation & Setup](#️-installation--setup)
- [🏗️ FuseStorage Construction](#️-fusestorage-construction)
- [📊 Database Operations](#-database-operations)
- [📁 File Management](#-file-management)
- [⚙️ Preferences Storage](#️-preferences-storage)
- [🔄 Synchronization Services](#-synchronization-services)
- [🔧 Advanced Configuration](#-advanced-configuration)
- [📚 API Reference](#-api-reference)
- [❌ Error Handling](#-error-handling)
- [🎯 Best Practices](#-best-practices)

## 🚀 Quick Start

### 30-Second Quick Setup

```swift
import FuseStorageKit

// 1. Build FuseStorage (unified storage interface)
let storage = try FuseStorageBuilder()
    .with(database: .sqlite("app.db"))
    .with(preferences: .userDefaults())
    .with(file: .document())
    .build()

// 2. Access various storage services through FuseStorage
let database = storage.db(.sqlite("app.db"))!
let preferences = storage.pref(.userDefaults())!
let fileManager = storage.file(.document())!

// 3. Use immediately
try database.add(myRecord)
try preferences.set("value", forKey: "key")
let fileURL = try fileManager.save(data: myData, relativePath: "file.txt")
```

## 💡 Core Concepts

### FuseStorage: Unified Storage Facade

`FuseStorage` is the core class of FuseStorageKit, providing:

- **Unified Interface**: Access all storage services through a single object
- **Manager Caching**: Automatically cache and reuse manager instances
- **Lazy Loading**: Create managers only when needed
- **Configuration Flexibility**: Support various storage configuration combinations

### Storage Service Types

| Service Type | Method | Purpose |
|-------------|--------|---------|
| **Database** | `storage.db()` | SQLite database operations |
| **Preferences** | `storage.pref()` | UserDefaults/Keychain preferences |
| **File** | `storage.file()` | File system operations |
| **Sync** | `storage.sync()` | Data synchronization services |

### Construction and Access Pattern

```swift
// Construction phase: Define all required services
let storage = try FuseStorageBuilder()
    .with(database: .sqlite("main.db"))     // Configure database
    .with(preferences: .userDefaults())     // Configure preferences
    .build()                                // Build FuseStorage

// Usage phase: Access services using the same configuration
let db = storage.db(.sqlite("main.db"))!   // Get database with same config
let prefs = storage.pref(.userDefaults())! // Get preferences with same config
```

## ⚙️ Installation & Setup

### Swift Package Manager

#### Option 1: Package.swift
```swift
// Package.swift
dependencies: [
    .package(url: "https://github.com/sky0926a/FuseStorageKit.git", from: "1.0.0")
]

// Target dependencies
.target(
    name: "YourApp",
    dependencies: [
        .product(name: "FuseStorageKit", package: "FuseStorageKit")
    ]
)
```

#### Option 2: Xcode
1. **File → Add Package Dependencies**
2. **Enter URL**: `https://github.com/sky0926a/FuseStorageKit.git`
3. **Select**: `FuseStorageKit` library
4. **Add to Target**: Your app target

### Import

```swift
import FuseStorageKit

// Cross-platform image handling (optional)
#if os(iOS) || os(tvOS) || os(watchOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif
```

## 🏗️ FuseStorage Construction

### Basic Construction Pattern

```swift
// Builder pattern
let storage = try FuseStorageBuilder()
    .with(database: .sqlite("app.db"))           // Database configuration
    .with(preferences: .userDefaults())          // Preferences configuration
    .with(file: .document("AppFiles"))           // File management configuration
    .with(sync: .noSync())                       // Sync service configuration
    .build()                                     // Build FuseStorage instance
```

### Common Configuration Examples

#### Minimal Setup
```swift
let storage = try FuseStorageBuilder()
    .with(database: .sqlite())
    .build()
```

#### Standard App Setup
```swift
let storage = try FuseStorageBuilder()
    .with(database: .sqlite("app.db"))
    .with(preferences: .userDefaults("com.myapp.settings"))
    .with(file: .document("AppFiles"))
    .build()
```

#### Secure App Setup
```swift
let storage = try FuseStorageBuilder()
    .with(database: .sqlite("secure.db", encryptions: .high(passphrase: "secret")))
    .with(preferences: .keychain("com.myapp.secure"))
    .with(file: .document("SecureFiles"))
    .with(sync: .noSync())
    .build()
```

### FuseStorage Manager Access

After construction, access managers using the same configuration options:

```swift
// ⚠️ Important: Must use the same configuration as during construction
let database = storage.db(.sqlite("app.db"))!                    // ✅ Correct
let preferences = storage.pref(.userDefaults("com.myapp.settings"))! // ✅ Correct
let fileManager = storage.file(.document("AppFiles"))!               // ✅ Correct

// ❌ Wrong: Inconsistent configuration will return nil
let wrongDb = storage.db(.sqlite("different.db"))  // nil, not configured during construction
```

## 📊 Database Operations

### Database Operations Through FuseStorage

#### Step 1: Define Data Model

```swift
struct User: FuseDatabaseRecord {
    let id: String
    let name: String
    let email: String
    let isActive: Bool
    let createdAt: Date
    
    static var _fuseidField: String = "id"
    
    static func tableDefinition() -> FuseTableDefinition {
        let columns: [FuseColumnDefinition] = [
            FuseColumnDefinition(name: "id", type: .text, isPrimaryKey: true, isNotNull: true),
            FuseColumnDefinition(name: "name", type: .text, isNotNull: true),
            FuseColumnDefinition(name: "email", type: .text, isNotNull: true),
            FuseColumnDefinition(name: "isActive", type: .boolean, isNotNull: true, defaultValue: "1"),
            FuseColumnDefinition(name: "createdAt", type: .date, isNotNull: true)
        ]
        return FuseTableDefinition(name: "users", columns: columns)
    }
    
    var tableDefinition: FuseTableDefinition {
        return User.tableDefinition()
    }
}
```

#### Step 2: Get Database Manager Through FuseStorage

```swift
// Configure database during construction
let storage = try FuseStorageBuilder()
    .with(database: .sqlite("app.db"))
    .build()

// Access database through FuseStorage
let database = storage.db(.sqlite("app.db"))!
```

#### Step 3: Basic CRUD Operations

```swift
// Create table
try database.createTable(User.tableDefinition())

// Add record
let user = User(id: "1", name: "John Doe", email: "john@example.com", isActive: true, createdAt: Date())
try database.add(user)

// Add multiple records
let users = [
    User(id: "2", name: "Jane Smith", email: "jane@example.com", isActive: true, createdAt: Date()),
    User(id: "3", name: "Bob Wilson", email: "bob@example.com", isActive: false, createdAt: Date())
]
try database.add(users)

// Fetch all records
let allUsers: [User] = try database.fetch(of: User.self)

// Conditional query
let activeUsers: [User] = try database.fetch(
    of: User.self,
    filters: [FuseQueryFilter.equals(field: "isActive", value: true)]
)

// Sorted query
let sortedUsers: [User] = try database.fetch(
    of: User.self,
    sort: FuseQuerySort(field: "name", order: .ascending)
)

// Delete record
try database.delete(user)
```

### Multiple Database Configuration

```swift
// Build multiple databases
let storage = try FuseStorageBuilder()
    .with(database: .sqlite("main.db"))                              // Main data
    .with(database: .sqlite("cache.db"))                             // Cache data
    .with(database: .sqlite("secure.db", encryptions: .high(passphrase: "secret"))) // Sensitive data
    .build()

// Access different databases through FuseStorage
let mainDb = storage.db(.sqlite("main.db"))!
let cacheDb = storage.db(.sqlite("cache.db"))!
let secureDb = storage.db(.sqlite("secure.db"))!
```

## 📁 File Management

### File Operations Through FuseStorage

#### Basic File Operations

```swift
// Configure file management during construction
let storage = try FuseStorageBuilder()
    .with(file: .document("MyAppFiles"))
    .build()

// Access file manager through FuseStorage
let fileManager = storage.file(.document("MyAppFiles"))!

// Save text data
let textData = "Hello, World!".data(using: .utf8)!
let textURL = try fileManager.save(data: textData, relativePath: "documents/greeting.txt")

// Save JSON data
struct AppConfig: Codable {
    let version: String
    let features: [String]
}

let config = AppConfig(version: "1.0", features: ["sync", "encryption"])
let jsonData = try JSONEncoder().encode(config)
let configURL = try fileManager.save(data: jsonData, relativePath: "config/app.json")

// Save images
#if os(iOS)
let image = UIImage(named: "profile-photo")!
#elseif os(macOS)
let image = NSImage(named: "profile-photo")!
#endif
let imageURL = try fileManager.save(image: image, fileName: "images/profile.jpg")

// Get file URL
let documentURL = fileManager.url(for: "documents/greeting.txt")

// Delete file
try fileManager.delete(relativePath: "documents/old-file.txt")
```

### Multiple File Location Configuration

```swift
let storage = try FuseStorageBuilder()
    .with(file: .document("UserFiles"))     // User documents
    .with(file: .library("AppData"))        // App data
    .with(file: .cache("TempFiles"))        // Cache files
    .build()

let userFiles = storage.file(.document("UserFiles"))!
let appData = storage.file(.library("AppData"))!
let cache = storage.file(.cache("TempFiles"))!
```

## ⚙️ Preferences Storage

### Preferences Management Through FuseStorage

#### Basic Preferences Operations

```swift
// Configure preferences during construction
let storage = try FuseStorageBuilder()
    .with(preferences: .userDefaults("com.myapp.settings"))
    .with(preferences: .keychain("com.myapp.secure"))
    .build()

// Access preferences managers through FuseStorage
let preferences = storage.pref(.userDefaults("com.myapp.settings"))!
let keychain = storage.pref(.keychain("com.myapp.secure"))!

// Store general settings
try preferences.set("dark", forKey: "theme")
try preferences.set(14, forKey: "fontSize")
try preferences.set(true, forKey: "notificationsEnabled")

// Store complex objects
struct UserPreferences: Codable {
    let theme: String
    let fontSize: Int
    let language: String
}

let userPrefs = UserPreferences(theme: "dark", fontSize: 14, language: "en")
try preferences.set(userPrefs, forKey: "userPreferences")

// Read settings
let theme: String? = preferences.get(forKey: "theme")
let fontSize: Int? = preferences.get(forKey: "fontSize")
let userPrefs: UserPreferences? = preferences.get(forKey: "userPreferences")

// Use default values
let themeValue = preferences.get(forKey: "theme") ?? "light"

// Store sensitive data to Keychain
try keychain.set("user-auth-token-12345", forKey: "authToken")
try keychain.set("super-secret-password", forKey: "userPassword")

// Read sensitive data
let token: String? = keychain.get(forKey: "authToken")
let password: String? = keychain.get(forKey: "userPassword")
```

### Multiple Preferences Storage Configuration

```swift
let storage = try FuseStorageBuilder()
    .with(preferences: .userDefaults("com.myapp.general"))   // General settings
    .with(preferences: .userDefaults("com.myapp.ui"))        // UI settings
    .with(preferences: .keychain("com.myapp.auth"))          // Authentication data
    .build()

let general = storage.pref(.userDefaults("com.myapp.general"))!
let ui = storage.pref(.userDefaults("com.myapp.ui"))!
let auth = storage.pref(.keychain("com.myapp.auth"))!
```

## 🔄 Synchronization Services

### Sync Management Through FuseStorage

```swift
// Configure sync service during construction
let storage = try FuseStorageBuilder()
    .with(database: .sqlite("app.db"))
    .with(sync: .noSync())  // or .firebase()
    .build()

// Access sync manager through FuseStorage
let syncManager = storage.sync(.noSync())!
let database = storage.db(.sqlite("app.db"))!

// Start sync
syncManager.startSync()

// Push local changes
let users: [User] = try database.fetch(of: User.self)
syncManager.pushLocalChanges(users, at: "users")

// Observe remote changes
syncManager.observeRemoteChanges(path: "users") { result in
    switch result {
    case .success(let data):
        // Parse and update local database
        do {
            let remoteUsers = try JSONDecoder().decode([User].self, from: data)
            try database.add(remoteUsers)
            print("Synced \(remoteUsers.count) users from remote")
        } catch {
            print("Failed to parse remote data: \(error)")
        }
        
    case .failure(let error):
        print("Sync error: \(error)")
    }
}
```

## 🔧 Advanced Configuration

### Environment-Based Configuration

```swift
enum Environment {
    case development, staging, production
}

func createStorage(for env: Environment) throws -> FuseStorage {
    let builder = FuseStorageBuilder()
    
    switch env {
    case .development:
        return try builder
            .with(database: .sqlite("dev.db"))
            .with(preferences: .userDefaults("com.myapp.dev"))
            .with(file: .cache("DevFiles"))
            .with(sync: .noSync())
            .build()
            
    case .staging:
        return try builder
            .with(database: .sqlite("staging.db", encryptions: .standard(passphrase: "staging")))
            .with(preferences: .userDefaults("com.myapp.staging"))
            .with(file: .document("StagingFiles"))
            .build()
            
    case .production:
        return try builder
            .with(database: .sqlite("prod.db", encryptions: .high(passphrase: getSecureKey())))
            .with(preferences: .keychain("com.myapp.prod"))
            .with(file: .document("ProductionFiles"))
            .with(sync: .firebase())
            .build()
    }
}

// Usage
let storage = try createStorage(for: .production)
```

### Singleton Pattern Integration

```swift
class AppStorage {
    static let shared = AppStorage()
    
    private let storage: FuseStorage
    
    private init() {
        do {
            storage = try FuseStorageBuilder()
                .with(database: .sqlite("app.db", encryptions: EncryptionOptions("mySecret")))
                .with(file: .document("AppFiles"))
                .with(preferences: .keychain("com.myapp.secure"))
                .build()
        } catch {
            fatalError("Failed to initialize storage system: \(error)")
        }
    }
    
    // Provide convenience methods through FuseStorage
    var database: FuseDatabaseManageable {
        return storage.db(.sqlite("app.db"))!
    }
    
    var fileManager: FuseFileManageable {
        return storage.file(.document("AppFiles"))!
    }
    
    var preferences: FusePreferencesManageable {
        return storage.pref(.keychain("com.myapp.secure"))!
    }
}

// Usage
let db = AppStorage.shared.database
let files = AppStorage.shared.fileManager
let prefs = AppStorage.shared.preferences
```

## 📚 API Reference

### FuseStorage Core Methods

```swift
public final class FuseStorage {
    /// Get database manager
    /// - Parameter query: Database builder option (must match construction)
    /// - Returns: Database manager instance, nil if failed
    public func db(_ query: FuseDatabaseBuilderOption) -> FuseDatabaseManageable?
    
    /// Get preferences manager
    /// - Parameter query: Preferences builder option (must match construction)
    /// - Returns: Preferences manager instance, nil if failed
    public func pref(_ query: FusePreferencesBuilderOption) -> FusePreferencesManageable?
    
    /// Get file manager
    /// - Parameter query: File builder option (must match construction)
    /// - Returns: File manager instance, nil if failed
    public func file(_ query: FuseFileBuilderOption) -> FuseFileManageable?
    
    /// Get sync manager
    /// - Parameter query: Sync builder option (must match construction)
    /// - Returns: Sync manager instance, nil if failed
    public func sync(_ query: FuseSyncBuilderOption) -> FuseSyncManageable?
}
```

### Builder Options

```swift
// Database options
FuseDatabaseBuilderOption.sqlite("path.db", encryptions: .high(passphrase: "secret"))
FuseDatabaseBuilderOption.custom("name", database: customDb)

// Preferences options
FusePreferencesBuilderOption.userDefaults("suiteName")
FusePreferencesBuilderOption.keychain("service", accessibility: .whenUnlocked)
FusePreferencesBuilderOption.custom("name", preferences: customPrefs)

// File options
FuseFileBuilderOption.document("folderName")
FuseFileBuilderOption.library("folderName")
FuseFileBuilderOption.cache("folderName")
FuseFileBuilderOption.custom("name", file: customFile)

// Sync options
FuseSyncBuilderOption.noSync()
FuseSyncBuilderOption.firebase() // Requires Firebase SDK
FuseSyncBuilderOption.custom(name: "name", sync: customSync)
```

## ❌ Error Handling

### Common FuseStorage Errors

```swift
// Manager not found (configuration mismatch)
let db = storage.db(.sqlite("nonexistent.db"))  // Returns nil

// Safe access pattern
guard let database = storage.db(.sqlite("app.db")) else {
    print("Database manager not found, check configuration")
    return
}

// Construction error handling
do {
    let storage = try FuseStorageBuilder()
        .with(database: .sqlite("app.db"))
        .build()
} catch {
    print("Failed to build FuseStorage: \(error)")
}
```

### Operation Error Handling

```swift
// Database operation errors
do {
    try database.add(user)
} catch {
    print("Failed to add user: \(error)")
}

// File operation errors
do {
    let url = try fileManager.save(data: data, relativePath: "document.pdf")
} catch {
    print("Failed to save file: \(error)")
}

// Preferences errors
do {
    try preferences.set(complexObject, forKey: "config")
} catch {
    print("Failed to save preferences: \(error)")
}
```

## 🎯 Best Practices

### 1. Unified Configuration Management

```swift
// ✅ Recommended: Centrally manage all configurations
struct StorageConfiguration {
    static let database = FuseDatabaseBuilderOption.sqlite("app.db", 
                                                           encryptions: .high(passphrase: "mySecret"))
    static let preferences = FusePreferencesBuilderOption.keychain("com.myapp.secure")
    static let fileManager = FuseFileBuilderOption.document("AppFiles")
    static let sync = FuseSyncBuilderOption.noSync()
    
    static func createStorage() throws -> FuseStorage {
        return try FuseStorageBuilder()
            .with(database: database)
            .with(preferences: preferences)
            .with(file: fileManager)
            .with(sync: sync)
            .build()
    }
}

// Usage
let storage = try StorageConfiguration.createStorage()
let database = storage.db(StorageConfiguration.database)!
```

### 2. Manager Caching

```swift
// ✅ FuseStorage automatically caches managers for efficient repeated access
class DataService {
    private let storage: FuseStorage
    
    init(storage: FuseStorage) {
        self.storage = storage
    }
    
    func saveUser(_ user: User) throws {
        // storage.db() returns cached instance, no duplicate creation
        let database = storage.db(.sqlite("app.db"))!
        try database.add(user)
    }
    
    func loadUsers() throws -> [User] {
        // Same database instance
        let database = storage.db(.sqlite("app.db"))!
        return try database.fetch(of: User.self)
    }
}
```

### 3. Error Handling Strategy

```swift
// ✅ Recommended: Create safe wrapper methods
extension FuseStorage {
    func safeDatabase(_ option: FuseDatabaseBuilderOption) throws -> FuseDatabaseManageable {
        guard let database = db(option) else {
            throw StorageError.databaseNotFound
        }
        return database
    }
    
    func safePreferences(_ option: FusePreferencesBuilderOption) throws -> FusePreferencesManageable {
        guard let preferences = pref(option) else {
            throw StorageError.preferencesNotFound
        }
        return preferences
    }
}

enum StorageError: Error {
    case databaseNotFound
    case preferencesNotFound
}
```

### 4. Test-Friendly Design

```swift
// ✅ Recommended: Protocol-oriented design for easy testing
protocol StorageServiceProtocol {
    func database() -> FuseDatabaseManageable?
    func preferences() -> FusePreferencesManageable?
}

class ProductionStorageService: StorageServiceProtocol {
    private let storage: FuseStorage
    
    init() throws {
        storage = try FuseStorageBuilder()
            .with(database: .sqlite("app.db"))
            .with(preferences: .userDefaults())
            .build()
    }
    
    func database() -> FuseDatabaseManageable? {
        return storage.db(.sqlite("app.db"))
    }
    
    func preferences() -> FusePreferencesManageable? {
        return storage.pref(.userDefaults())
    }
}

class MockStorageService: StorageServiceProtocol {
    func database() -> FuseDatabaseManageable? {
        return MockDatabase()
    }
    
    func preferences() -> FusePreferencesManageable? {
        return MockPreferences()
    }
}
```

---

## 📝 Quick Reference

### Basic Usage Pattern

```swift
// 1. Build FuseStorage
let storage = try FuseStorageBuilder()
    .with(database: .sqlite("app.db"))
    .with(preferences: .userDefaults())
    .with(file: .document())
    .build()

// 2. Access services through FuseStorage (using same configuration)
let db = storage.db(.sqlite("app.db"))!
let prefs = storage.pref(.userDefaults())!
let files = storage.file(.document())!

// 3. Use immediately
try db.add(record)
try prefs.set(value, forKey: "key")
let url = try files.save(data: data, relativePath: "file.txt")
```

### Common Operations

```swift
// Database
try database.add(record)                           // Insert/Update
let items: [T] = try database.fetch(of: T.self)   // Fetch all
try database.delete(record)                        // Delete

// Preferences
try preferences.set(value, forKey: "key")         // Store
let value: Type? = preferences.get(forKey: "key") // Retrieve

// Files
let url = try fileManager.save(data: data, relativePath: "file.txt")  // Save
try fileManager.delete(relativePath: "file.txt")                       // Delete
```

FuseStorageKit provides a unified, efficient storage solution through `FuseStorage`. For more examples, see the [Tests](../Tests/) and [Example App](../FuseStorageKitExample/) directories.
