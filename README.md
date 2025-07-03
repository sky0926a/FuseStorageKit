# FuseStorageKit
<a href="https://developer.apple.com/swift/"><img alt="Swift 6" src="https://img.shields.io/badge/swift-6-orange.svg?style=flat"></a>
<a href="https://github.com/sky0926a/FuseStorageKit/blob/master/LICENSE"><img alt="License" src="https://img.shields.io/badge/license-MIT-black"></a>
<a href="https://github.com/sky0926a/FuseStorageKit/blob/master/USAGE.md"><img src="https://img.shields.io/badge/Swift-Doc-DE5C43.svg?style=flat"></a>

A lightweight, unified storage solution for iOS and macOS that provides a single interface for:

- **Database Storage** - SQLite with optional AES-256 encryption
- **File Management** - Structured file system operations
- **Preferences Storage** - UserDefaults and Keychain integration
- **Cloud Synchronization** - Framework ready (implementation in progress)

FuseStorageKit abstracts away the complexities of underlying implementations (GRDB, SQLCipher) through a simple builder pattern and manager facade.

> 📖 **For complete API documentation, see [USAGE.md](USAGE.md)**

## Core Concepts

Before diving into usage, let's understand the key concepts:

### 🏗️ Builder Pattern
FuseStorageKit uses a builder pattern to configure storage components. You create a `FuseStorageBuilder`, configure it with various storage options, then build a `FuseStorage` instance.

### 📦 Storage Managers
The `FuseStorage` instance contains different types of managers:
- **Database Manager**: Handle SQLite operations
- **Preferences Manager**: Handle settings and configuration
- **File Manager**: Handle file system operations
- **Sync Manager**: Handle cloud synchronization

### 🔍 Query Objects
To access specific managers, you use the same builder options as "query objects" to identify which manager you want.

## Features

- **Unified API**: Access database, file, preferences, and sync operations through a single `FuseStorage` instance.
- **Builder Pattern**: Configure storage components using a fluent builder interface with factory methods.
- **Multiple Managers**: Support multiple instances of the same storage type with different configurations.
- **Database Encryption**: Built-in support for enterprise-grade AES-256 encryption via SQLCipher.
- **Abstraction**: Users do not need to interact directly with underlying storage manager classes (e.g., GRDB managers) or import their libraries (like GRDB) for basic usage.
- **Modular Design**: Components are pluggable via protocols and builder options.
- **Auto-Registration**: Database factories are automatically registered at startup with no manual setup required.
- **Highly Extensible**: Easily integrate custom storage implementations.
- **Fully Type-Safe**: Leverages Swift's generics and the `Codable` protocol.

## Installation

### Swift Package Manager

Add FuseStorageKit to your `Package.swift` dependencies:

```swift
dependencies: [
    .package(url: "https://github.com/sky0926a/FuseStorageKit.git", from: "1.0.0")
]
```

Then add the target to your target dependencies:

```swift
.target(
    name: "YourTarget",
    dependencies: [
        .product(name: "FuseStorageKit", package: "FuseStorageKit")
    ]
)
```

**For Firebase sync features (optional):**
```swift
dependencies: [
    .package(url: "https://github.com/sky0926a/FuseStorageKit.git", from: "1.0.0"),
    .package(url: "https://github.com/firebase/firebase-ios-sdk.git", from: "11.0.0")
]

.target(
    name: "YourTarget",
    dependencies: [
        .product(name: "FuseStorageKit", package: "FuseStorageKit"),
        .product(name: "FirebaseFirestore", package: "firebase-ios-sdk")
    ]
)
```

Or add it through Xcode:
1. File → Add Package Dependencies
2. Enter the repository URL: `https://github.com/sky0926a/FuseStorageKit.git`
3. Select `FuseStorageKit` library
4. (Optional) Add Firebase SDK if using sync features

## Quick Start

### Step 1: Import and Create Storage

```swift
import FuseStorageKit

// Create storage with specific configurations
let storage = try FuseStorageBuilder()
    .with(database: .sqlite())
    .with(preferences: .userDefaults())
    .with(file: .document())
    .build()
```

### Step 2: Get Managers

```swift
// Get different types of managers
let dbManager = storage.db(.sqlite())!         // Database operations
let prefsManager = storage.pref(.userDefaults())!  // Preferences storage
let fileManager = storage.file(.document())!    // File operations
```

### Step 3: Store Simple Data

```swift
// Store preferences
try prefsManager.set("John Doe", forKey: "username")
try prefsManager.set(25, forKey: "userAge")

// Retrieve preferences
let username: String? = prefsManager.get(forKey: "username")  // "John Doe"
let age: Int? = prefsManager.get(forKey: "userAge")          // 25
```

### Step 4: Store Files

```swift
// Save text data
let textData = "Hello, World!".data(using: .utf8)!
let fileURL = try fileManager.save(data: textData, relativePath: "hello.txt")

// Retrieve file URL
let retrievedURL = fileManager.url(for: "hello.txt")
```

That's it! You now have a working storage system. Continue reading for database operations and advanced features.

## Next Steps

- 📖 **[Complete API Guide](USAGE.md)** - Comprehensive documentation with all protocols, classes, and usage patterns
- 🔧 **[Builder Options Reference](#builder-options-reference)** - All available configuration options
- 📱 **[Example App](FuseStorageKitExample/)** - Working iOS app demonstrating real-world usage

## Key Features

- **Unified API** - Single interface for database, file, preferences, and sync operations
- **Builder Pattern** - Fluent configuration with factory methods
- **Multiple Managers** - Support multiple instances with different configurations
- **AES-256 Encryption** - Enterprise-grade database security via SQLCipher
- **Type-Safe** - Leverages Swift generics and Codable protocol
- **Cross-Platform** - Works on iOS, macOS, tvOS, and watchOS
- **Modular Design** - Pluggable components via protocols

## Builder Options Reference

FuseStorageKit provides comprehensive configuration options for each storage component. Here are all available options with detailed usage examples:

### Database Options

#### SQLite Database
```swift
// Standard SQLite database with default name
.with(database: .sqlite())

// SQLite database with custom filename
.with(database: .sqlite("myapp.db"))

// Encrypted SQLite database with standard security
.with(database: .sqlite("secure.db", encryptions: EncryptionOptions.standard(passphrase: "mySecretKey")))

// Encrypted SQLite database with high security
.with(database: .sqlite("secure.db", encryptions: EncryptionOptions.high(passphrase: "mySecretKey")))

// Encrypted SQLite database with performance optimization
.with(database: .sqlite("fast.db", encryptions: EncryptionOptions.performance(passphrase: "mySecretKey")))

// Custom encryption configuration
let customEncryption = EncryptionOptions("mySecretKey")
    .pageSize(4096)
    .kdfIter(64000)
    .memorySecurity(true)
.with(database: .sqlite("custom.db", encryptions: customEncryption))
```

#### Custom Database
```swift
// Custom database implementation
.with(database: .custom("mydb", database: MyCustomDatabaseManager()))
```

### Preferences Options

#### UserDefaults Configuration
```swift
// Standard UserDefaults
.with(preferences: .userDefaults())

// UserDefaults with nil suite (uses standard)
.with(preferences: .userDefaults(nil))

// UserDefaults with custom suite name
.with(preferences: .userDefaults("com.myapp.settings"))

// UserDefaults for app groups (shared between apps)
.with(preferences: .userDefaults("group.com.mycompany.myappgroup"))
```

#### Keychain Configuration
```swift
// Keychain with service name and default accessibility
.with(preferences: .keychain("com.myapp.secure"))

// Keychain with custom accessibility level
.with(preferences: .keychain("com.myapp.tokens", accessibility: .whenUnlockedThisDeviceOnly))

// Keychain with access group for sharing between apps
.with(preferences: .keychain("com.myapp.shared", accessGroup: "TEAMID.com.mycompany.shared"))

// Available keychain accessibility options:
.with(preferences: .keychain("service", accessibility: .whenUnlocked))          // Default - accessible when device unlocked
.with(preferences: .keychain("service", accessibility: .afterFirstUnlock))     // Accessible after first unlock
.with(preferences: .keychain("service", accessibility: .whenUnlockedThisDeviceOnly))     // This device only
.with(preferences: .keychain("service", accessibility: .afterFirstUnlockThisDeviceOnly)) // After first unlock, this device only
```

#### Custom Preferences
```swift
// Custom preferences implementation
.with(preferences: .custom("myprefs", preferences: MyCustomPreferencesManager()))
```

### File Options

#### Standard Directories
```swift
// Documents directory (backed up by iCloud/iTunes)
.with(file: .document())                           // Uses default folder name
.with(file: .document("MyAppFiles"))              // Custom folder name

// Library directory (backed up but hidden from users)
.with(file: .library())                           // Uses default folder name  
.with(file: .library("AppLibrary"))              // Custom folder name

// Cache directory (may be purged by system when storage is low)
.with(file: .cache())                             // Uses default folder name
.with(file: .cache("TempFiles"))                 // Custom folder name
```

#### Custom Directories
```swift
// Application Support directory
.with(file: .file("MyData", 
                   searchPathDirectory: .applicationSupportDirectory, 
                   domainMask: .userDomainMask))

// Downloads directory
.with(file: .file("Downloads", 
                   searchPathDirectory: .downloadsDirectory, 
                   domainMask: .userDomainMask))

// Desktop directory (macOS)
.with(file: .file("DesktopFiles", 
                   searchPathDirectory: .desktopDirectory, 
                   domainMask: .userDomainMask))

// Movies directory
.with(file: .file("VideoCache", 
                   searchPathDirectory: .moviesDirectory, 
                   domainMask: .userDomainMask))

// Pictures directory
.with(file: .file("ImageCache", 
                   searchPathDirectory: .picturesDirectory, 
                   domainMask: .userDomainMask))

// Shared public directory
.with(file: .file("PublicData", 
                   searchPathDirectory: .sharedPublicDirectory, 
                   domainMask: .localDomainMask))
```

#### Custom File Manager
```swift
// Custom file manager implementation
.with(file: .custom("myfiles", file: MyCustomFileManager()))
```

### Sync Options

#### No Synchronization
```swift
// No synchronization - local storage only
.with(sync: .noSync())
```

#### Firebase Synchronization
```swift
// Firebase synchronization (framework available, implementation in progress)
#if canImport(FirebaseFirestore)
.with(sync: .firebase())
#endif
```

#### Custom Synchronization
```swift
// Custom sync implementation
.with(sync: .custom("mysync", sync: MyCustomSyncManager()))

// Multiple sync implementations
.with(sync: .custom("mainSync", sync: MainSyncManager()))
.with(sync: .custom("backupSync", sync: BackupSyncManager()))
```

### Multiple Manager Configuration Examples

#### Multi-Database Setup
```swift
let storage = try FuseStorageBuilder()
    .with(database: .sqlite("main.db"))                    // Main application data
    .with(database: .sqlite("cache.db"))                   // Temporary cache
    .with(database: .sqlite("secure.db", encryptions: EncryptionOptions.high(passphrase: "secret")))  // Encrypted sensitive data
    .build()

// Access specific databases
let mainDb = storage.db(.sqlite("main.db"))!
let cacheDb = storage.db(.sqlite("cache.db"))!
let secureDb = storage.db(.sqlite("secure.db"))!
```

#### Multi-Preferences Setup
```swift
let storage = try FuseStorageBuilder()
    .with(preferences: .userDefaults("com.myapp.general"))    // General app settings
    .with(preferences: .userDefaults("com.myapp.ui"))         // UI preferences
    .with(preferences: .keychain("com.myapp.auth"))           // Authentication tokens
    .with(preferences: .keychain("com.myapp.secrets"))        // Sensitive data
    .build()

// Access specific preference stores
let generalPrefs = storage.pref(.userDefaults("com.myapp.general"))!
let uiPrefs = storage.pref(.userDefaults("com.myapp.ui"))!
let authPrefs = storage.pref(.keychain("com.myapp.auth"))!
let secretsPrefs = storage.pref(.keychain("com.myapp.secrets"))!
```

#### Multi-File Storage Setup
```swift
let storage = try FuseStorageBuilder()
    .with(file: .document("UserFiles"))                       // User documents
    .with(file: .cache("ImageCache"))                         // Cached images
    .with(file: .library("AppData"))                          // Application data
    .with(file: .file("Logs", searchPathDirectory: .applicationSupportDirectory, domainMask: .userDomainMask))  // Log files
    .build()

// Access specific file managers
let userFiles = storage.file(.document("UserFiles"))!
let imageCache = storage.file(.cache("ImageCache"))!
let appData = storage.file(.library("AppData"))!
let logFiles = storage.file(.file("Logs", searchPathDirectory: .applicationSupportDirectory, domainMask: .userDomainMask))!
```

### Configuration Best Practices

#### Security Considerations
```swift
// For sensitive data - use encrypted database + keychain
let secureStorage = try FuseStorageBuilder()
    .with(database: .sqlite("secure.db", encryptions: EncryptionOptions.high(passphrase: generateSecurePassphrase())))
    .with(preferences: .keychain("com.myapp.secure", accessibility: .whenUnlockedThisDeviceOnly))
    .build()
```

#### Performance Optimization
```swift
// For high-performance scenarios
let performanceStorage = try FuseStorageBuilder()
    .with(database: .sqlite("fast.db", encryptions: EncryptionOptions.performance(passphrase: "key")))
    .with(file: .cache("FastAccess"))  // Use cache for temporary files
    .with(sync: .noSync())             // Disable sync for better performance
    .build()
```

#### App Extension Sharing
```swift
// For sharing data between main app and extensions
let sharedStorage = try FuseStorageBuilder()
    .with(database: .sqlite("shared.db"))
    .with(preferences: .userDefaults("group.com.mycompany.myapp"))  // App group for sharing
    .with(file: .file("Shared", searchPathDirectory: .applicationSupportDirectory, domainMask: .userDomainMask))
    .build()
```

## Complete Example

```swift
import FuseStorageKit

// 1. Configure storage
let storage = try FuseStorageBuilder()
    .with(database: .sqlite("app.db", encryptions: .standard(passphrase: "secret")))
    .with(preferences: .userDefaults("com.myapp.settings"))
    .with(file: .document("AppFiles"))
    .build()

// 2. Get managers
let db = storage.db(.sqlite("app.db"))!
let prefs = storage.pref(.userDefaults("com.myapp.settings"))!
let files = storage.file(.document("AppFiles"))!

// 3. Define your data model
struct User: FuseDatabaseRecord {
    let id: String
    let name: String
    let email: String
    
    static var _fuseidField: String = "id"
    static func tableDefinition() -> FuseTableDefinition {
        FuseTableDefinition(name: "users", columns: [
            FuseColumnDefinition(name: "id", type: .text, isPrimaryKey: true, isNotNull: true),
            FuseColumnDefinition(name: "name", type: .text, isNotNull: true),
            FuseColumnDefinition(name: "email", type: .text, isNotNull: true)
        ])
    }
}

// 4. Use your storage
try db.createTable(User.tableDefinition())
try db.add(User(id: "1", name: "John", email: "john@example.com"))
try prefs.set("dark", forKey: "theme")
let users: [User] = try db.fetch(of: User.self, filters: [], sort: nil, limit: nil, offset: nil)
let theme: String? = prefs.get(forKey: "theme")
```

> See **[USAGE.md](USAGE.md)** for detailed examples and advanced patterns.

## Requirements

- iOS 15.0+ / macOS 11.0+
- Swift 5.6+
- Xcode 13.0+

## Dependencies

### Core Dependencies

- **GRDB.swift with SQLCipher**: Database functionality with encryption via [duckduckgo/GRDB.swift](https://github.com/duckduckgo/GRDB.swift)

### Optional Dependencies

- **Firebase iOS SDK**: Sync framework support via [firebase/firebase-ios-sdk](https://github.com/firebase/firebase-ios-sdk) (implementation in progress)

## Documentation

- **[USAGE.md](USAGE.md)** - Complete API reference with all protocols, classes, and patterns
- **[Example App](FuseStorageKitExample/)** - Real-world usage examples
- **[Tests](Tests/)** - Comprehensive test suite demonstrating all features

## Core Architecture

**Protocols**: `FuseManageable`, `FuseDatabaseManageable`, `FuseFileManageable`, `FusePreferencesManageable`, `FuseSyncManageable`

**Classes**: `FuseStorageBuilder`, `FuseStorage`, `FuseDatabaseManager`, `FuseFileManager`, `FuseUserDefaultsManager`, `FuseKeychainManager`

**Models**: `FuseTableDefinition`, `FuseColumnDefinition`, `FuseQueryFilter`, `FuseQuerySort`, `EncryptionOptions`

## Capabilities

✅ SQLite database with GRDB  
✅ AES-256 encryption via SQLCipher  
✅ UserDefaults and Keychain storage  
✅ File system operations  
🚧 Firebase sync (framework ready, implementation in progress)  
✅ Multiple manager instances  
✅ Cross-platform support  
✅ Type-safe Codable integration  

## License

FuseStorageKit is released under the MIT License. See [LICENSE](LICENSE) for details.

### Third-Party Licenses

- **GRDB.swift**: MIT License - https://github.com/groue/GRDB.swift
- **GRDB.swift with SQLCipher**: MIT License - https://github.com/duckduckgo/GRDB.swift
- **SQLCipher**: Public Domain (Community Edition)
- **Firebase iOS SDK**: Apache License 2.0 - https://github.com/firebase/firebase-ios-sdk

For complete third-party notices, see [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).
