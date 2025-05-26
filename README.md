# FuseStorageKit

FuseStorageKit is a lightweight storage solution for iOS and macOS, providing a unified, abstracted interface for handling:

- Local Database Storage
- File System Storage
- User Preferences
- Cloud Synchronization (optional)

It allows developers to interact with various storage mechanisms through a single facade, abstracting away the complexities of underlying implementations like GRDB or Firebase Storage.

## Features

- **Unified API**: Access database, file, preferences, and sync operations through a single `FuseStorage` instance.
- **Builder Pattern**: Configure storage components using a fluent builder interface with factory methods.
- **Multiple Managers**: Support multiple instances of the same storage type with different configurations.
- **Abstraction**: Users do not need to interact directly with underlying storage manager classes (e.g., GRDB managers) or import their libraries (like GRDB) for basic usage.
- **Modular Design**: Components are pluggable via protocols and builder options.
- **Highly Extensible**: Easily integrate custom storage implementations.
- **Fully Type-Safe**: Leverages Swift's generics and the `Codable` protocol.

## Installation

### Swift Package Manager

Add FuseStorageKit to your `Package.swift` dependencies:

**Option 1: With SQLCipher support (Recommended for encrypted databases)**
```swift
dependencies: [
    .package(url: "https://github.com/sky0926a/FuseStorageKit.git", from: "1.0.0"),
    // GRDB with SQLCipher support for encrypted databases
    .package(url: "https://github.com/duckduckgo/GRDB.swift.git", from: "3.0.0"),
    // Optional: Required only if using Firebase sync
    .package(url: "https://github.com/firebase/firebase-ios-sdk.git", from: "10.0.0")
]
```

**Option 2: With original GRDB (For standard SQLite databases)**
```swift
dependencies: [
    .package(url: "https://github.com/sky0926a/FuseStorageKit.git", from: "1.0.0"),
    // Original GRDB for standard SQLite databases
    .package(url: "https://github.com/groue/GRDB.swift.git", from: "7.5.0"),
    // Optional: Required only if using Firebase sync
    .package(url: "https://github.com/firebase/firebase-ios-sdk.git", from: "10.0.0")
]
```

Or add it through Xcode:
1. File → Add Package Dependencies
2. Enter the repository URL: `https://github.com/sky0926a/FuseStorageKit.git`
3. Choose your GRDB dependency:
   - For encrypted databases: `https://github.com/duckduckgo/GRDB.swift.git`
   - For standard databases: `https://github.com/groue/GRDB.swift.git`
4. (Optional) Add Firebase SDK if using sync features: `https://github.com/firebase/firebase-ios-sdk.git`

## Usage

### Initialization

Initialize `FuseStorage` using the `FuseStorageBuilder`. The builder pattern allows you to configure different storage components using builder options. Each component type has factory methods for common configurations.

```swift
import FuseStorageKit

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
#if canImport(FirebaseStorage)
let cloudStorage = try FuseStorageBuilder()
    .with(database: .sqlite())
    .with(preferences: .userDefaults())
    .with(file: .document())
    .with(sync: .firebase())
    .build()
#endif

// Custom implementations
let customImplementationStorage = try FuseStorageBuilder()
    .with(database: .custom("mydb", database: MyCustomDatabaseManager()))
    .with(preferences: .custom("myprefs", preferences: MyCustomPreferencesManager()))
    .with(file: .custom("myfiles", file: MyCustomFileManager()))
    .with(sync: .custom("mysync", sync: MyCustomSyncManager()))
    .build()
```

### Accessing Storage Functionality

Access different storage managers through the `FuseStorage` instance using query objects:

```swift
// Get managers using builder options as queries
let dbManager = storage.db(.sqlite("myapp.db"))
let prefsManager = storage.pref(.userDefaults("com.myapp.settings"))
let fileManager = storage.file(.document("MyAppFiles"))
let syncManager = storage.sync(.noSync())
```

## Builder Options Reference

### Database Options

```swift
// SQLite database with default settings
.with(database: .sqlite())

// SQLite database with custom filename
.with(database: .sqlite("myapp.db"))

// SQLite database with encryption (requires duckduckgo/GRDB.swift)
.with(database: .sqlite("secure.db", encryptions: EncryptionOptions.standard(passphrase: "secret")))

// Custom database implementation
.with(database: .custom("mydb", database: MyCustomDatabaseManager()))
```

**GRDB Version Compatibility:**
- **Standard SQLite features**: Compatible with both `groue/GRDB.swift` and `duckduckgo/GRDB.swift`
- **Encryption features**: Only available with `duckduckgo/GRDB.swift` (SQLCipher integration)
- **Performance**: Both versions offer excellent performance, DuckDuckGo version includes XCFramework optimization

### Preferences Options

```swift
// UserDefaults with default suite
.with(preferences: .userDefaults())

// UserDefaults with custom suite
.with(preferences: .userDefaults("com.myapp.settings"))

// Keychain storage with default accessibility
.with(preferences: .keychain("com.myapp.secure"))

// Keychain storage with custom accessibility and access group
.with(preferences: .keychain("com.myapp.secure", accessGroup: "group.myapp", accessibility: .whenUnlockedThisDeviceOnly))

// Custom preferences implementation
.with(preferences: .custom("myprefs", preferences: MyCustomPreferencesManager()))
```

### File Options

```swift
// Documents directory with default folder name
.with(file: .document())

// Documents directory with custom folder name
.with(file: .document("MyAppFiles"))

// Library directory
.with(file: .library("AppLibrary"))

// Cache directory
.with(file: .cache("TempFiles"))

// Custom directory location
.with(file: .file("CustomDir", searchPathDirectory: .applicationSupportDirectory, domainMask: .userDomainMask))

// Custom file manager implementation
.with(file: .custom("myfiles", file: MyCustomFileManager()))
```

### Sync Options

```swift
// No synchronization (offline only)
.with(sync: .noSync())

// Firebase synchronization (requires Firebase SDK)
#if canImport(FirebaseStorage)
.with(sync: .firebase())
#endif

// Custom sync implementation
.with(sync: .custom("mysync", sync: MyCustomSyncManager()))
```

## Detailed Usage Guide

### 1. Database Management

The database manager provides a type-safe SQLite database implementation using GRDB. It handles table creation, data retrieval, and record manipulation.

#### Database Model Creation

Your data models must conform to the `FuseDatabaseRecord` protocol:

```swift
import FuseStorageKit
import Foundation // For UUID and Date

struct Note: Codable, Identifiable, FuseDatabaseRecord {
    var id: String
    var title: String
    var content: String
    var createdAt: Date
    var hasAttachment: Bool = false
    var attachmentPath: String? = nil

    // Provide the field name that serves as the unique identifier for the record
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

        return FuseTableDefinition(
            name: "notes", // Define your table name
            columns: columns
        )
    }
}
```

#### Table Management

```swift
// Get database manager
let dbManager = storage.db(.sqlite("notes.db"))!

// Check if table exists
let tableExists = try dbManager.tableExists("notes")

// Create table from model definition
try dbManager.createTable(Note.tableDefinition())
```

#### Database Encryption

FuseStorageKit supports database encryption using SQLCipher through the [duckduckgo/GRDB.swift](https://github.com/duckduckgo/GRDB.swift) integration. This provides enterprise-grade AES-256 encryption for your SQLite databases.

**Note**: Database encryption requires the DuckDuckGo GRDB.swift fork. If you're using the original [groue/GRDB.swift](https://github.com/groue/GRDB.swift), encryption features will not be available.

To enable encryption, follow these steps:

```swift
// Initialize encryption options with default presets
// 1. Standard security level (recommended)
let standardEncryption = EncryptionOptions.standard(passphrase: "YourSecurePassphrase")

// 2. High security level (more secure but lower performance)
let highSecurityEncryption = EncryptionOptions.high(passphrase: "YourSecurePassphrase")

// 3. Performance-first (less secure but better performance)
let performanceEncryption = EncryptionOptions.performance(passphrase: "YourSecurePassphrase")

// Or manually configure custom encryption options
let customEncryption = EncryptionOptions("YourSecurePassphrase")
    .pageSize(4096)           // Set page size
    .kdfIter(64000)           // Set KDF iteration count
    .memorySecurity(true)     // Enable memory security
    .defaultPageSize(4096)    // Set default page size
    .defaultKdfIter(64000)    // Set default KDF iteration count

// Build FuseStorage with encrypted database
let secureStorage = try FuseStorageBuilder()
    .with(database: .sqlite("encrypted.db", encryptions: standardEncryption))
    .build()

// Access the encrypted database manager
let encryptedDbManager = secureStorage.db(.sqlite("encrypted.db"))!
```

SQLCipher Encryption Options:
- `pageSize`: Sets the database page size; affects performance and encryption strength. Common value: 4096 (aligned with system page size).
- `kdfIter`: Number of iterations for the Key Derivation Function (KDF); higher values increase security but reduce performance.
- `memorySecurity`: Enables in-memory security to prevent sensitive data from lingering in memory.
- `defaultPageSize`: Sets the default page size for new databases.
- `defaultKdfIter`: Sets the default KDF iteration count for new databases.

Default Presets:
- `standard`: Balanced security and performance (page size 4096, KDF iterations 64,000, memory security enabled).
- `high`: High-security configuration (page size 4096, KDF iterations 200,000, memory security enabled).
- `performance`: Performance-first configuration (page size 4096, KDF iterations 10,000, memory security disabled).

**SQLCipher Integration Notes:**
- Uses SQLCipher Community Edition 4.7.0 with AES-256 encryption
- Encrypted and unencrypted databases are incompatible; manage your encryption keys carefully
- If you lose the encryption key, the database cannot be restored
- Encryption may introduce a slight performance overhead but provides enhanced data protection
- The integration is provided through DuckDuckGo's fork which packages SQLCipher as XCFramework for easy Swift Package Manager consumption
- Supports all standard SQLCipher PRAGMA commands for advanced configuration

#### Record Operations

```swift
// Get database manager
let dbManager = storage.db(.sqlite("notes.db"))!

// Create a new record
let newNote = Note(id: UUID().uuidString,
                  title: "Sample Title",
                  content: "This is sample content.",
                  createdAt: Date())

// Add a record to the database
try dbManager.add(newNote)

// Batch insert multiple records
let batchNotes = [
    Note(id: UUID().uuidString, title: "Note 1", content: "Content 1", createdAt: Date()),
    Note(id: UUID().uuidString, title: "Note 2", content: "Content 2", createdAt: Date()),
    Note(id: UUID().uuidString, title: "Note 3", content: "Content 3", createdAt: Date())
]
try dbManager.add(batchNotes)

// Fetch all records of a type
let allNotes: [Note] = try dbManager.fetch(of: Note.self)

// Fetch with filtering
let filters = [FuseQueryFilter.equals(field: "hasAttachment", value: true)]
let notesWithAttachments: [Note] = try dbManager.fetch(
    of: Note.self,
    filters: filters
)

// Fetch with sorting and pagination
let sortedNotes: [Note] = try dbManager.fetch(
    of: Note.self,
    sort: FuseQuerySort(field: "createdAt", ascending: false),
    limit: 10,
    offset: 0
)

// Delete a record
try dbManager.delete(note)

// Batch delete multiple records
let notesToDelete = [note1, note2, note3]
try dbManager.delete(notesToDelete)
```

#### Advanced Queries

For complex operations, you can use the `FuseQuery` API:

```swift
// Get database manager
let dbManager = storage.db(.sqlite("notes.db"))!

// Custom SELECT query
let query = FuseQuery(
    table: "notes",
    action: .select(
        fields: ["id", "title"], 
        filters: [
            FuseQueryFilter.equals(field: "hasAttachment", value: true),
            FuseQueryFilter.greaterThan(field: "createdAt", value: Date().addingTimeInterval(-86400))
        ],
        sort: FuseQuerySort(field: "createdAt", ascending: false),
        limit: 20
    )
)
let recentNotes: [Note] = try dbManager.read(query)

// Custom UPDATE query
let updateQuery = FuseQuery(
    table: "notes",
    action: .update(
        values: ["title": "Updated Title"],
        filters: [FuseQueryFilter.equals(field: "id", value: note.id)]
    )
)
try dbManager.write(updateQuery)
```

#### Batch Operations

FuseStorageKit provides optimized methods for working with multiple records at once:

```swift
// Get database manager
let dbManager = storage.db(.sqlite("notes.db"))!

// Batch insert multiple records in a single database transaction
let batchRecords = [
    Note(id: UUID().uuidString, title: "Meeting Notes", content: "Discuss roadmap", createdAt: Date()),
    Note(id: UUID().uuidString, title: "Project Ideas", content: "New feature concepts", createdAt: Date()),
    Note(id: UUID().uuidString, title: "Shopping List", content: "Items to buy", createdAt: Date())
]

// Insert all records in a single optimized transaction
try dbManager.add(batchRecords)

// Batch delete multiple records in a single database transaction
let recordsToDelete = [note1, note2, note3]
try dbManager.delete(recordsToDelete)
```

Benefits of batch operations:
- Improved performance through reduced database transactions
- Enhanced atomicity with all operations succeeding or failing together
- Reduced disk I/O overhead
- Optimized for large datasets

Under the hood, batch operations use special SQL syntax for maximum efficiency rather than executing individual operations in a loop.

### 2. File Management

The file manager provides a simple interface for file operations, including saving and retrieving images and data files.

#### Configuration

```swift
// Configure file storage in different directories
let storage = try FuseStorageBuilder()
    .with(file: .document("MyAppFiles"))    // Documents directory
    .with(file: .library("AppLibrary"))     // Library directory
    .with(file: .cache("TempFiles"))        // Cache directory
    .build()

// Get specific file managers
let docFileManager = storage.file(.document("MyAppFiles"))!
let cacheFileManager = storage.file(.cache("TempFiles"))!
```

#### Working with Images

```swift
#if os(iOS) || os(tvOS) || os(watchOS)
import UIKit
let image = UIImage(named: "profile")!
#elseif os(macOS)
import AppKit
let image = NSImage(named: "profile")!
#endif

// Get file manager
let fileManager = storage.file(.document("MyAppFiles"))!

// Save an image (format determined by file extension)
let imagePath = "profiles/user123.jpg"
let savedImageURL = try fileManager.save(image: image, fileName: imagePath)

// Get URL for an image
let imageURL = fileManager.url(for: imagePath)
```

#### Working with Data Files

```swift
// Get file manager
let fileManager = storage.file(.document("MyAppFiles"))!

// Save data to a file
let jsonData = try JSONEncoder().encode(["key": "value"])
let dataPath = "configuration/settings.json"
let savedDataURL = try fileManager.save(data: jsonData, relativePath: dataPath)

// Reading data
// Note: You'll need to use Foundation APIs to read the data
let fileURL = fileManager.url(for: dataPath)
let data = try Data(contentsOf: fileURL)

// Delete a file
try fileManager.delete(relativePath: dataPath)
```

### 3. Preferences Management

The preferences manager provides a type-safe wrapper around UserDefaults and Keychain, optimized for storing both primitive and complex types.

#### Configuration

```swift
// Configure different types of preferences storage
let storage = try FuseStorageBuilder()
    .with(preferences: .userDefaults("com.myapp.settings"))    // UserDefaults
    .with(preferences: .keychain("com.myapp.secure", accessibility: .whenUnlocked))  // Keychain
    .build()

// Get specific preferences managers
let userDefaultsManager = storage.pref(.userDefaults("com.myapp.settings"))!
let keychainManager = storage.pref(.keychain("com.myapp.secure"))!
```

#### Storing and Retrieving Preferences

```swift
// Get preferences managers
let userDefaultsManager = storage.pref(.userDefaults("com.myapp.settings"))!
let keychainManager = storage.pref(.keychain("com.myapp.secure"))!

// Store values in UserDefaults
try userDefaultsManager.set(true, forKey: "isDarkModeEnabled")
try userDefaultsManager.set(42, forKey: "lastSelectedTab")
try userDefaultsManager.set("English", forKey: "preferredLanguage")

// Store sensitive data in Keychain
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
let lastTab: Int? = userDefaultsManager.get(forKey: "lastSelectedTab")
let language: String? = userDefaultsManager.get(forKey: "preferredLanguage")
let userPrefs: UserPreferences? = userDefaultsManager.get(forKey: "userPreferences")

// Retrieve sensitive data
let authToken: String? = keychainManager.get(forKey: "authToken")
let password: String? = keychainManager.get(forKey: "userPassword")

// Check if a preference exists
let hasThemeSettings = userDefaultsManager.containsValue(forKey: "userPreferences")
let hasAuthToken = keychainManager.containsValue(forKey: "authToken")

// Remove preferences
userDefaultsManager.removeValue(forKey: "temporarySetting")
keychainManager.removeValue(forKey: "oldToken")
```

### Using Multiple Managers Together

The real power of FuseStorageKit comes from using all managers together through the unified facade:

```swift
import FuseStorageKit

// Create and configure a FuseStorage instance
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
let syncManager = storage.sync(.noSync())!

// Example workflow with multiple storage types:
// 1. User creates a note
let newNote = Note(id: UUID().uuidString, title: "Project Ideas", content: "My ideas...", createdAt: Date())
try dbManager.add(newNote)

// 2. User attaches an image to the note
#if os(iOS) || os(tvOS) || os(watchOS)
let attachmentImage = UIImage(named: "sketch")!
#elseif os(macOS)
let attachmentImage = NSImage(named: "sketch")!
#endif
let imagePath = "notes/attachments/\(newNote.id).jpg"
let imageURL = try fileManager.save(image: attachmentImage, fileName: imagePath)

// 3. Update the note with the attachment info
var updatedNote = newNote
updatedNote.hasAttachment = true
updatedNote.attachmentPath = imagePath
try dbManager.add(updatedNote) // This will update the existing record

// 4. Store user viewing preferences
try prefsManager.set(true, forKey: "showAttachmentsInline")

// 5. Trigger sync if needed
syncManager.triggerManualSync()
```

## Requirements

- iOS 15.0+ / macOS 11.0+
- Swift 5.6+
- Xcode 13.0+

## Dependencies

### Core Dependencies

#### Database Dependencies (Choose One)

**Option 1: GRDB.swift with SQLCipher (Recommended for encrypted databases)**
- **GRDB.swift with SQLCipher**: [duckduckgo/GRDB.swift](https://github.com/duckduckgo/GRDB.swift) - A fork of GRDB with integrated SQLCipher Community Edition support, packaged as XCFramework for Swift Package Manager.
  - GRDB: 7.4.1
  - SQLCipher: 4.7.0
  - Package Version: 3.0.0
  - License: MIT
  - Features: Enterprise-grade AES-256 encryption, XCFramework packaging

**Option 2: Original GRDB.swift (For standard SQLite databases)**
- **GRDB.swift**: [groue/GRDB.swift](https://github.com/groue/GRDB.swift) - A toolkit for SQLite databases, with a focus on application development.
  - Latest Version: 7.5.0
  - License: MIT
  - Stars: 7.5k+ on GitHub
  - Features: Comprehensive SQLite toolkit, extensive documentation, active community

#### Sync Dependencies

- **Firebase/FirebaseStorage**: [firebase/firebase-ios-sdk](https://github.com/firebase/firebase-ios-sdk) - Required when using `.firebase()` sync option. Not required if you only use `.noSync()` or custom sync implementations.

### Optional Dependencies

- **Custom Implementations**: Not required if you only use custom database, preferences, file, or sync implementations that conform to the respective protocols (`FuseDatabaseManageable`, `FusePreferencesManageable`, `FuseFileManageable`, `FuseSyncManageable`).

### Choosing Between GRDB Versions

**Use DuckDuckGo GRDB.swift (`duckduckgo/GRDB.swift`) when:**
- You need database encryption (SQLCipher)
- You want XCFramework optimization
- You prefer a pre-packaged solution with SQLCipher integration

**Use Original GRDB.swift (`groue/GRDB.swift`) when:**
- You don't need database encryption
- You want the latest GRDB features and updates
- You prefer the original, actively maintained version with extensive community support
- You want access to the comprehensive documentation and examples from the original project

## Limitations

- `FuseStorageKit` provides a facade; the specific features and limitations of database operations, file handling, preferences, and synchronization depend entirely on the `FuseDatabaseManageable`, `FusePreferencesManageable`, `FuseFileManageable`, and `FuseSyncManageable` implementations provided or used by default.
- Error handling and conflict resolution strategies for synchronization are specific to the `FuseSyncManageable` implementation.
- When using the **default** GRDB database manager, your models must conform to `FuseDatabaseRecord` protocol.
- `FuseStorageKit` itself does not handle database migrations; this is the responsibility of the `FuseDatabaseManageable` implementation.
- The availability of certain file operations (like image handling) may depend on the platform and the specific `FuseFileManageable` implementation.
- Thread safety considerations:
  - **Database managers**: Thread-safe due to GRDB's use of database queues.
  - **File managers**: Not guaranteed to be thread-safe; consider using dispatch queues for concurrent access.
  - **Preferences managers**: UserDefaults is thread-safe for reading, but consider synchronization for rapid concurrent writes. Keychain operations are thread-safe.

## License and Legal Information

### License
FuseStorageKit is released under the MIT License. See the [LICENSE](LICENSE) file for the full license text.

### Third-Party Library Licenses
FuseStorageKit uses the following third-party libraries, each with their own licenses:

#### Database Libraries (Choose One)

1. **GRDB.swift with SQLCipher (DuckDuckGo Fork)**
   - License: MIT License
   - Source: https://github.com/duckduckgo/GRDB.swift
   - Original GRDB Source: https://github.com/groue/GRDB.swift
   - License Text: [GRDB.swift LICENSE](https://github.com/groue/GRDB.swift/blob/master/LICENSE)
   - SQLCipher: Community Edition (Public Domain)
   - Description: Fork of GRDB with integrated SQLCipher support for database encryption

2. **Original GRDB.swift**
   - License: MIT License
   - Source: https://github.com/groue/GRDB.swift
   - License Text: [GRDB.swift LICENSE](https://github.com/groue/GRDB.swift/blob/master/LICENSE)
   - Description: A toolkit for SQLite databases, with a focus on application development

#### Sync Libraries

3. **Firebase iOS SDK**
   - License: Apache License 2.0
   - Source: https://github.com/firebase/firebase-ios-sdk
   - License Text: [Firebase LICENSE](https://github.com/firebase/firebase-ios-sdk/blob/master/LICENSE)

For complete third-party notices and license texts, please refer to the [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md) file.

When using this library, you must comply with the licensing terms of these third-party libraries.

### Disclaimer
FuseStorageKit is provided "AS IS", without warranty of any kind, express or implied, including but not limited to the warranties of merchantability, fitness for a particular purpose and noninfringement. In no event shall the authors or copyright holders be liable for any claim, damages or other liability, whether in an action of contract, tort or otherwise, arising from, out of or in connection with the software or the use or other dealings in the software.
