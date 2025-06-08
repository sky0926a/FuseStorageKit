# FuseStorageKit

FuseStorageKit is a lightweight storage solution for iOS and macOS, providing a unified, abstracted interface for handling:

- Local Database Storage (with optional encryption)
- File System Storage
- User Preferences
- Cloud Synchronization (optional)

It allows developers to interact with various storage mechanisms through a single facade, abstracting away the complexities of underlying implementations like GRDB with SQLCipher support or Firebase Store.

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

### Basic Usage

```swift
import FuseStorageKit

// Simple setup with default configurations
let storage = try FuseStorageBuilder().build()

// Get managers
let dbManager = storage.db(.sqlite())!
let prefsManager = storage.pref(.userDefaults())!
let fileManager = storage.file(.document())!

// Define your data model
struct Note: FuseDatabaseRecord {
    var id: String
    var title: String
    var content: String
    var createdAt: Date
    
    static var _fuseidField: String = "id"
    
    static func tableDefinition() -> FuseTableDefinition {
        let columns: [FuseColumnDefinition] = [
            FuseColumnDefinition(name: "id", type: .text, isPrimaryKey: true, isNotNull: true),
            FuseColumnDefinition(name: "title", type: .text, isNotNull: true),
            FuseColumnDefinition(name: "content", type: .text, isNotNull: true),
            FuseColumnDefinition(name: "createdAt", type: .date, isNotNull: true)
        ]
        return FuseTableDefinition(name: "notes", columns: columns)
    }
}

// Create table and add data
try dbManager.createTable(Note.tableDefinition())

let note = Note(id: UUID().uuidString, title: "Hello", content: "World", createdAt: Date())
try dbManager.add(note)

// Fetch data
let allNotes: [Note] = try dbManager.fetch(of: Note.self)
```

## Detailed Usage

### 1. Initialization and Configuration

Initialize `FuseStorage` using the `FuseStorageBuilder`. The builder pattern allows you to configure different storage components using builder options.

```swift
// Basic setup with default configurations
let storage = try FuseStorageBuilder().build()

// Configure specific components
let customStorage = try FuseStorageBuilder()
    .with(database: .sqlite("myapp.db"))
    .with(preferences: .userDefaults("com.myapp.settings"))
    .with(file: .document("MyAppFiles"))
    .with(sync: .noSync())
    .build()

// Multiple managers of the same type
let multiStorage = try FuseStorageBuilder()
    .with(database: .sqlite("main.db"))
    .with(database: .sqlite("cache.db"))
    .with(preferences: .userDefaults("general"))
    .with(preferences: .keychain("secure", accessibility: .whenUnlocked))
    .with(file: .document("Documents"))
    .with(file: .cache("Cache"))
    .build()

// With Firebase sync (requires Firebase SDK)
#if canImport(FirebaseFirestore)
let cloudStorage = try FuseStorageBuilder()
    .with(database: .sqlite())
    .with(preferences: .userDefaults())
    .with(file: .document())
    .with(sync: .firebase())
    .build()
#endif
```

### 2. Accessing Storage Components

Access different storage managers through the `FuseStorage` instance using query objects:

```swift
// Get managers using builder options as queries
let dbManager = storage.db(.sqlite("myapp.db"))
let prefsManager = storage.pref(.userDefaults("com.myapp.settings"))
let fileManager = storage.file(.document("MyAppFiles"))
let syncManager = storage.sync(.noSync())
```

### 3. Database Management

#### Database Model Creation

Your data models must conform to the `FuseDatabaseRecord` protocol:

```swift
struct Note: FuseDatabaseRecord {
    var id: String
    var title: String
    var content: String
    var createdAt: Date
    var hasAttachment: Bool = false
    var attachmentPath: String? = nil

    // Provide the field name that serves as the unique identifier
    static var _fuseidField: String = "id"

    // Define the database table and columns
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

#### Basic Database Operations

```swift
// Get database manager
let dbManager = storage.db(.sqlite("notes.db"))!

// Create table
try dbManager.createTable(Note.tableDefinition())

// Add records
let newNote = Note(id: UUID().uuidString, title: "Sample", content: "Content", createdAt: Date())
try dbManager.add(newNote)

// Batch insert
let batchNotes = [
    Note(id: UUID().uuidString, title: "Note 1", content: "Content 1", createdAt: Date()),
    Note(id: UUID().uuidString, title: "Note 2", content: "Content 2", createdAt: Date())
]
try dbManager.add(batchNotes)

// Fetch all records
let allNotes: [Note] = try dbManager.fetch(of: Note.self)

// Fetch with filtering
let filters = [FuseQueryFilter.equals(field: "hasAttachment", value: true)]
let notesWithAttachments: [Note] = try dbManager.fetch(of: Note.self, filters: filters)

// Fetch with sorting and pagination
let sortedNotes: [Note] = try dbManager.fetch(
    of: Note.self,
    sort: FuseQuerySort(field: "createdAt", ascending: false),
    limit: 10,
    offset: 0
)

// Delete records
try dbManager.delete(newNote)
try dbManager.delete(batchNotes)
```

#### Database Encryption

FuseStorageKit provides enterprise-grade AES-256 encryption via SQLCipher for secure database storage.

```swift
import FuseStorageKit

// Standard security level (recommended)
let standardEncryption = EncryptionOptions.standard(passphrase: "YourSecurePassphrase")

// High security level
let highSecurityEncryption = EncryptionOptions.high(passphrase: "YourSecurePassphrase")

// Performance-optimized
let performanceEncryption = EncryptionOptions.performance(passphrase: "YourSecurePassphrase")

// Custom encryption configuration
let customEncryption = EncryptionOptions("YourSecurePassphrase")
    .pageSize(4096)
    .kdfIter(64000)
    .memorySecurity(true)

// Build storage with encrypted database
let secureStorage = try FuseStorageBuilder()
    .with(database: .sqlite("encrypted.db", encryptions: standardEncryption))
    .build()

let encryptedDbManager = secureStorage.db(.sqlite("encrypted.db"))!
```

### 4. File Management

The file manager provides a simple interface for file operations:

```swift
// Configure file storage
let storage = try FuseStorageBuilder()
    .with(file: .document("MyAppFiles"))    // Documents directory
    .with(file: .cache("TempFiles"))        // Cache directory
    .build()

let fileManager = storage.file(.document("MyAppFiles"))!

// Save images
#if os(iOS) || os(tvOS) || os(watchOS)
import UIKit
let image = UIImage(named: "profile")!
#elseif os(macOS)
import AppKit
let image = NSImage(named: "profile")!
#endif

let imagePath = "profiles/user123.jpg"
let savedImageURL = try fileManager.save(image: image, fileName: imagePath)

// Save data files
let jsonData = try JSONEncoder().encode(["key": "value"])
let dataPath = "configuration/settings.json"
let savedDataURL = try fileManager.save(data: jsonData, relativePath: dataPath)

// Get file URLs
let imageURL = fileManager.url(for: imagePath)
let dataURL = fileManager.url(for: dataPath)

// Delete files
try fileManager.delete(relativePath: dataPath)
```

### 5. Preferences Management

The preferences manager provides type-safe storage for settings and configuration:

```swift
// Configure preferences storage
let storage = try FuseStorageBuilder()
    .with(preferences: .userDefaults("com.myapp.settings"))
    .with(preferences: .keychain("com.myapp.secure", accessibility: .whenUnlocked))
    .build()

let userDefaultsManager = storage.pref(.userDefaults("com.myapp.settings"))!
let keychainManager = storage.pref(.keychain("com.myapp.secure"))!

// Store simple values
try userDefaultsManager.set(true, forKey: "isDarkModeEnabled")
try userDefaultsManager.set(42, forKey: "lastSelectedTab")
try userDefaultsManager.set("English", forKey: "preferredLanguage")

// Store sensitive data in keychain
try keychainManager.set("user_token_123", forKey: "authToken")
try keychainManager.set("secret_password", forKey: "userPassword")

// Store complex objects
struct UserPreferences: Codable {
    var theme: String
    var fontSize: Int
    var notifications: Bool
}

let preferences = UserPreferences(theme: "Dark", fontSize: 14, notifications: true)
try userDefaultsManager.set(preferences, forKey: "userPreferences")

// Retrieve values
let isDarkMode: Bool? = userDefaultsManager.get(forKey: "isDarkModeEnabled")
let userPrefs: UserPreferences? = userDefaultsManager.get(forKey: "userPreferences")
let authToken: String? = keychainManager.get(forKey: "authToken")

// Check existence and remove
let hasSettings = userDefaultsManager.containsValue(forKey: "userPreferences")
userDefaultsManager.removeValue(forKey: "temporarySetting")
```

## Builder Options Reference

### Database Options

```swift
// Standard SQLite database
.with(database: .sqlite("myapp.db"))

// Encrypted SQLite database
.with(database: .sqlite("secure.db", encryptions: EncryptionOptions.standard(passphrase: "secret")))

// Custom database implementation
.with(database: .custom("mydb", database: MyCustomDatabaseManager()))
```

### Preferences Options

```swift
// UserDefaults with custom suite
.with(preferences: .userDefaults("com.myapp.settings"))

// Keychain storage
.with(preferences: .keychain("com.myapp.secure", accessibility: .whenUnlocked))

// Custom preferences implementation
.with(preferences: .custom("myprefs", preferences: MyCustomPreferencesManager()))
```

### File Options

```swift
// Documents directory
.with(file: .document("MyAppFiles"))

// Library directory
.with(file: .library("AppLibrary"))

// Cache directory
.with(file: .cache("TempFiles"))

// Custom directory
.with(file: .file("CustomDir", searchPathDirectory: .applicationSupportDirectory, domainMask: .userDomainMask))

// Custom file manager
.with(file: .custom("myfiles", file: MyCustomFileManager()))
```

### Sync Options

```swift
// No synchronization
.with(sync: .noSync())

// Firebase synchronization (requires Firebase SDK)
#if canImport(FirebaseFirestore)
.with(sync: .firebase())
#endif

// Custom sync implementation
.with(sync: .custom("mysync", sync: MyCustomSyncManager()))
```

## Complete Example

Here's a complete example showing how to use all components together:

```swift
import FuseStorageKit

// Create storage instance
let storage = try FuseStorageBuilder()
    .with(database: .sqlite("notes.db"))
    .with(preferences: .userDefaults("com.myapp.settings"))
    .with(file: .document("MyAppFiles"))
    .with(sync: .noSync())
    .build()

// Get managers
let dbManager = storage.db(.sqlite("notes.db"))!
let prefsManager = storage.pref(.userDefaults("com.myapp.settings"))!
let fileManager = storage.file(.document("MyAppFiles"))!

// 1. Create a note
let newNote = Note(id: UUID().uuidString, title: "Project Ideas", content: "My ideas...", createdAt: Date())
try dbManager.add(newNote)

// 2. Attach an image
#if os(iOS) || os(tvOS) || os(watchOS)
let attachmentImage = UIImage(named: "sketch")!
#elseif os(macOS)
let attachmentImage = NSImage(named: "sketch")!
#endif

let imagePath = "notes/attachments/\(newNote.id).jpg"
let imageURL = try fileManager.save(image: attachmentImage, fileName: imagePath)

// 3. Update note with attachment info
var updatedNote = newNote
updatedNote.hasAttachment = true
updatedNote.attachmentPath = imagePath
try dbManager.add(updatedNote)

// 4. Store user preferences
try prefsManager.set(true, forKey: "showAttachmentsInline")

// 5. Fetch and display
let allNotes: [Note] = try dbManager.fetch(of: Note.self)
let showInline: Bool? = prefsManager.get(forKey: "showAttachmentsInline")
```

## Requirements

- iOS 15.0+ / macOS 11.0+
- Swift 5.6+
- Xcode 13.0+

## Dependencies

### Core Dependencies

- **GRDB.swift with SQLCipher**: Database functionality with encryption via [duckduckgo/GRDB.swift](https://github.com/duckduckgo/GRDB.swift)
- **Firebase iOS SDK**: Sync functionality via [firebase/firebase-ios-sdk](https://github.com/firebase/firebase-ios-sdk) (optional)

## Key Features

FuseStorageKit provides a unified storage solution with the following capabilities:

- **Standard SQLite**: High-performance local database storage
- **Database Encryption**: Enterprise-grade AES-256 encryption via SQLCipher
- **File Management**: Structured file system operations
- **Preferences Storage**: Type-safe settings and configuration management
- **Cloud Sync**: Optional Firebase integration for remote synchronization
- **Modular Architecture**: Extensible design with custom implementations

## Limitations

- Models must conform to `FuseDatabaseRecord` protocol when using default GRDB managers
- Thread safety varies by component (database managers are thread-safe, file managers require external synchronization)
- Database migrations are handled by the underlying GRDB implementation
- Error handling and sync conflict resolution depend on the specific implementations used

## License

FuseStorageKit is released under the MIT License. See [LICENSE](LICENSE) for details.

### Third-Party Licenses

- **GRDB.swift**: MIT License - https://github.com/groue/GRDB.swift
- **GRDB.swift with SQLCipher**: MIT License - https://github.com/duckduckgo/GRDB.swift
- **SQLCipher**: Public Domain (Community Edition)
- **Firebase iOS SDK**: Apache License 2.0 - https://github.com/firebase/firebase-ios-sdk

For complete third-party notices, see [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).
