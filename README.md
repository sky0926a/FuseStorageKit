# FuseStorageKit

FuseStorageKit is a lightweight storage solution for iOS and macOS, providing a unified, abstracted interface for handling:

- Local Database Storage
- File System Storage
- User Preferences
- Cloud Synchronization (optional)

It allows developers to interact with various storage mechanisms through a single facade, abstracting away the complexities of underlying implementations like GRDB or Firebase Storage.

## Features

- **Unified API**: Access database, file, preferences, and sync operations through a single `FuseStorageKit` instance.
- **Abstraction**: Users do not need to interact directly with underlying storage manager classes (e.g., GRDB managers) or import their libraries (like GRDB) for basic usage.
- **Modular Design**: Components are pluggable via protocols.
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

## Usage

### Initialization

Initialize `FuseStorageKit` using the `FuseStorageKitBuilder`. FuseStorageKit provides default implementations for database (`FuseDatabaseManager`), preferences (`FusePreferencesManager`), and file management (`FuseFileManager`). You can use these defaults, or provide your own custom implementations by conforming to the respective protocols (`FuseDatabaseManageable`, `FusePreferencesManageable`, `FuseFileManageable`, `FuseSyncManageable`).

```swift
import FuseStorageKit

// Local Version - Uses all default managers (database, preferences, and file). No sync.
let localKit = try FuseStorageKitBuilder().build()

// Cloud Version - Uses default database, preferences, and file managers, with a custom sync manager.
// Ensure your FirebaseApp is configured elsewhere in your application lifecycle.
// FirebaseApp.configure() // Example: Configure FirebaseApp in your AppDelegate or App struct
let cloudKit = try FuseStorageKitBuilder()
                  .with(sync: FirebaseSyncManager()) // Example: Explicitly use the default sync manager
                //.with(sync: MyCustomSyncManager()) // Provide your FuseSyncManageable implementation
                  .build()

// Fully Customized Version - Provide custom implementations or use default managers explicitly for any component.
let customKit = try FuseStorageKitBuilder()
  .with(database: FuseDatabaseManager())   // Example: Explicitly use the default database manager
//.with(database: MyCustomDatabaseManager()) // Example: Use a custom database manager
  .with(preferences: FusePreferencesManager()) // Example: Explicitly use the default preferences manager
//.with(preferences: MyCustomPreferencesManager()) // Example: Use a custom preferences manager
  .with(file: FuseFileManager())       // Example: Explicitly use the default file manager
// .with(file: MyCustomFileManager()) // Example: Use a custom file manager
  .with(sync: FirebaseSyncManager())       // Example: Explicitly use the default sync manager
//.with(sync: MyCustomSyncManager()) // Provide your FuseSyncManageable implementation
  .build()
```
*Note: Replace `MyCustomDatabaseManager`, `MyCustomPreferencesManager`, `MyCustomFileManager`, and `MyCustomSyncManager` with the actual names of your custom implementations that conform to the respective protocols. Uncomment the lines with default managers if you prefer to use them explicitly.*

### Accessing Storage Functionality

Interact with the different storage types through the properties of the `FuseStorageKit` instance: `.database`, `.preferences`, `.file`, and `.sync`.

## Detailed Usage Guide

### 1. FuseDatabaseManager

The `FuseDatabaseManager` provides a type-safe SQLite database implementation using GRDB. It handles table creation, data retrieval, and record manipulation.

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
// Check if table exists
let tableExists = try kit.database.tableExists("notes")

// Create table from model definition
try kit.database.createTable(Note.tableDefinition())
```

#### Database Encryption

FuseStorageKit 支援使用 SQLCipher 對資料庫進行加密。啟用加密功能需要以下步驟：

```swift
// 使用預設加密配置初始化加密選項
// 1. 標準安全級別 (推薦)
let standardEncryption = EncryptionOptions.standard(passphrase: "YourSecurePassphrase")

// 2. 高安全級別 (更安全但性能較低)
let highSecurityEncryption = EncryptionOptions.high(passphrase: "YourSecurePassphrase")

// 3. 性能優先 (安全性較低但性能較好)
let performanceEncryption = EncryptionOptions.performance(passphrase: "YourSecurePassphrase")

// 或手動設定自訂加密選項
let customEncryption = EncryptionOptions("YourSecurePassphrase")
    .pageSize(4096)           // 設定頁面大小
    .kdfIter(64000)           // 設定 KDF 迭代次數
    .memorySecurity(true)     // 啟用記憶體安全
    .defaultPageSize(4096)    // 設定預設頁面大小
    .defaultKdfIter(64000)    // 設定預設 KDF 迭代次數

// 使用加密選項初始化資料庫管理器
let encryptedDbManager = try FuseDatabaseManager(
    path: "encrypted.sqlite", 
    encryptions: standardEncryption
)

// 然後使用此加密資料庫管理器建立 FuseStorageKit 實例
let secureKit = try FuseStorageKitBuilder()
    .with(database: encryptedDbManager)
    .build()
```

SQLCipher 加密選項說明：
- `pageSize`: 設定資料庫頁面大小 (page size)，影響性能與加密強度，常用值: 4096 (與系統頁面大小對齊)
- `kdfIter`: 金鑰推導函數 (Key Derivation Function) 的迭代次數，越高越安全但速度越慢
- `memorySecurity`: 啟用記憶體安全 (memory security)，防止敏感資料留在記憶體中
- `defaultPageSize`: 設定新資料庫的預設頁面大小
- `defaultKdfIter`: 設定新資料庫的預設 KDF 迭代次數

預設配置說明：
- `standard`: 均衡的安全性和性能（頁面大小 4096，KDF 迭代 64,000，啟用記憶體安全）
- `high`: 高安全性配置（頁面大小 4096，KDF 迭代 200,000，啟用記憶體安全）
- `performance`: 性能優先配置（頁面大小 4096，KDF 迭代 10,000，不啟用記憶體安全）

注意事項：
- 加密和未加密的資料庫互不相容，請確保正確管理加密金鑰
- 如果使用加密資料庫後忘記金鑰，資料將無法恢復
- 加密可能會對性能產生輕微影響，但提供更高的資料安全性

#### Record Operations

```swift
// Create a new record
let newNote = Note(id: UUID().uuidString,
                  title: "Sample Title",
                  content: "This is sample content.",
                  createdAt: Date())

// Add a record to the database
try kit.database.add(newNote)

// Fetch all records of a type
let allNotes: [Note] = try kit.database.fetch(of: Note.self)

// Fetch with filtering
let filters = [FuseQueryFilter.equals(field: "hasAttachment", value: true)]
let notesWithAttachments: [Note] = try kit.database.fetch(
    of: Note.self,
    filters: filters
)

// Fetch with sorting and pagination
let sortedNotes: [Note] = try kit.database.fetch(
    of: Note.self,
    sort: FuseQuerySort(field: "createdAt", ascending: false),
    limit: 10,
    offset: 0
)

// Delete a record
try kit.database.delete(note)
```

#### Advanced Queries

For complex operations, you can use the `FuseQuery` API:

```swift
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
let recentNotes: [Note] = try kit.database.read(query)

// Custom UPDATE query
let updateQuery = FuseQuery(
    table: "notes",
    action: .update(
        values: ["title": "Updated Title"],
        filters: [FuseQueryFilter.equals(field: "id", value: note.id)]
    )
)
try kit.database.write(updateQuery)
```

### 2. FuseFileManager

The `FuseFileManager` provides a simple interface for file operations, including saving and retrieving images and data files.

#### Initialization

```swift
// Initialize with default directory (Documents/FuseStorageKit)
let fileManager = FuseFileManager()

// Initialize with custom base directory
let customFileManager = FuseFileManager.withBaseFolder("MyAppFiles")
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

// Save an image (format determined by file extension)
let imagePath = "profiles/user123.jpg"
let savedImageURL = try kit.file.save(image: image, relativePath: imagePath)

// Get URL for an image
let imageURL = kit.file.url(for: imagePath)
```

#### Working with Data Files

```swift
// Save data to a file
let jsonData = try JSONEncoder().encode(["key": "value"])
let dataPath = "configuration/settings.json"
let savedDataURL = try kit.file.save(data: jsonData, relativePath: dataPath)

// Reading data
// Note: You'll need to use Foundation APIs to read the data
let fileURL = kit.file.url(for: dataPath)
let data = try Data(contentsOf: fileURL)

// Delete a file
try kit.file.delete(relativePath: dataPath)
```

### 3. FusePreferencesManager

The `FusePreferencesManager` provides a type-safe wrapper around UserDefaults, optimized for storing both primitive and complex types.

#### Initialization

```swift
// Initialize with standard UserDefaults
let preferencesManager = FusePreferencesManager()

// Initialize with custom UserDefaults suite
let customPreferencesManager = FusePreferencesManager(suiteName: "com.myapp.preferences")

// Initialize with custom date encoding/decoding strategies
let dateFormatter = DateFormatter()
dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
let dateFormattedManager = FusePreferencesManager(
    suiteName: nil,
    dateEncodingStrategy: .formatted(dateFormatter),
    dateDecodingStrategy: .formatted(dateFormatter)
)
```

#### Storing and Retrieving Preferences

```swift
// Store values
kit.preferences.set(true, forKey: "isDarkModeEnabled")
kit.preferences.set(42, forKey: "lastSelectedTab")
kit.preferences.set("English", forKey: "preferredLanguage")

// Store complex objects
struct UserPreferences: Codable {
    var theme: String
    var fontSize: Int
    var notifications: Bool
}

let preferences = UserPreferences(theme: "Dark", fontSize: 14, notifications: true)
kit.preferences.set(preferences, forKey: "userPreferences")

// Retrieve values
let isDarkMode: Bool? = kit.preferences.get(forKey: "isDarkModeEnabled")
let lastTab: Int? = kit.preferences.get(forKey: "lastSelectedTab")
let language: String? = kit.preferences.get(forKey: "preferredLanguage")
let userPrefs: UserPreferences? = kit.preferences.get(forKey: "userPreferences")

// Check if a preference exists
let hasThemeSettings = kit.preferences.containsValue(forKey: "userPreferences")

// Remove a preference
kit.preferences.removeValue(forKey: "temporarySetting")
```

### Using Multiple Managers Together

The real power of FuseStorageKit comes from using all managers together through the unified facade:

```swift
import FuseStorageKit

// Create and configure a FuseStorageKit instance
let storageKit = try FuseStorageKitBuilder().build()

// Example workflow with multiple storage types:
// 1. User creates a note
let newNote = Note(id: UUID().uuidString, title: "Project Ideas", content: "My ideas...", createdAt: Date())
try storageKit.database.add(newNote)

// 2. User attaches an image to the note
#if os(iOS) || os(tvOS) || os(watchOS)
let attachmentImage = UIImage(named: "sketch")!
#elseif os(macOS)
let attachmentImage = NSImage(named: "sketch")!
#endif
let imagePath = "notes/attachments/\(newNote.id).jpg"
let imageURL = try storageKit.file.save(image: attachmentImage, relativePath: imagePath)

// 3. Update the note with the attachment info
var updatedNote = newNote
updatedNote.hasAttachment = true
updatedNote.attachmentPath = imagePath
try storageKit.database.add(updatedNote) // This will update the existing record

// 4. Store user viewing preferences
storageKit.preferences.set(true, forKey: "showAttachmentsInline")

// 5. Trigger sync if needed
storageKit.sync.triggerManualSync()
```

## Requirements

- iOS 15.0+ / macOS 11.0+
- Swift 5.6+
- Xcode 13.0+

## Dependencies

- [GRDB.swift](https://github.com/groue/GRDB.swift): Required if you use the **default** database manager implementation. Not required if you provide your own `FuseDatabaseManageable`.
- [Firebase/FirebaseStorage](https://github.com/firebase/firebase-ios-sdk): Required if you use the **default** Firebase sync manager implementation. Not required if you provide your own `FuseSyncManageable` or no sync manager.

## Limitations

- `FuseStorageKit` provides a facade; the specific features and limitations of database operations, file handling, preferences, and synchronization depend entirely on the `FuseDatabaseManageable`, `FusePreferencesManageable`, `FuseFileManageable`, and `FuseSyncManageable` implementations provided or used by default.
- Error handling and conflict resolution strategies for synchronization are specific to the `FuseSyncManageable` implementation.
- When using the **default** GRDB database manager, your models must conform to `FetchableRecord` and `PersistableRecord` from the GRDB library.
- `FuseStorageKit` itself does not handle database migrations; this is the responsibility of the `FuseDatabaseManageable` implementation.
- The availability of certain file operations (like image handling) may depend on the platform and the specific `FuseFileManageable` implementation.
- Thread safety considerations:
  - **FuseDatabaseManager**: Thread-safe due to GRDB's use of database queues.
  - **FuseFileManager**: Not guaranteed to be thread-safe; consider using dispatch queues for concurrent access.
  - **FusePreferencesManager**: UserDefaults is thread-safe for reading, but consider synchronization for rapid concurrent writes.

## License and Legal Information

### License
FuseStorageKit is released under the MIT License. See the [LICENSE](LICENSE) file for the full license text.

### Third-Party Library Licenses
FuseStorageKit uses the following third-party libraries, each with their own licenses:

1. **GRDB.swift**
   - License: MIT License
   - Source: https://github.com/groue/GRDB.swift
   - License Text: [GRDB.swift LICENSE](https://github.com/groue/GRDB.swift/blob/master/LICENSE)

2. **Firebase iOS SDK**
   - License: Apache License 2.0
   - Source: https://github.com/firebase/firebase-ios-sdk
   - License Text: [Firebase LICENSE](https://github.com/firebase/firebase-ios-sdk/blob/master/LICENSE)

For complete third-party notices and license texts, please refer to the [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md) file.

When using this library, you must comply with the licensing terms of these third-party libraries.

### Disclaimer
FuseStorageKit is provided "AS IS", without warranty of any kind, express or implied, including but not limited to the warranties of merchantability, fitness for a particular purpose and noninfringement. In no event shall the authors or copyright holders be liable for any claim, damages or other liability, whether in an action of contract, tort or otherwise, arising from, out of or in connection with the software or the use or other dealings in the software.