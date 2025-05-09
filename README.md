# FuseStorageKit

FuseStorageKit 是一個輕量級的 iOS/macOS 儲存解決方案，提供了統一的介面來處理：

- 本地資料庫儲存 (基於 GRDB)
- 檔案系統儲存
- 使用者偏好設定
- 雲端同步 (基於 Firebase Storage)

## 特色

- **輕量且強大**：開箱即用的儲存解決方案
- **模組化設計**：所有組件可單獨使用或組合使用
- **高度可擴展**：基於協議設計，可輕鬆替換實現
- **完全類型安全**：所有 API 都使用泛型和 Codable 協議

## 快速開始

### Swift Package Manager

將 FuseStorageKit 添加到你的 Package.swift：

```swift
dependencies: [
    .package(url: "https://github.com/yourusername/FuseStorageKit.git", from: "1.0.0")
]
```

### 基本使用方式

```swift
import FuseStorageKit

// 本地版本 - 不使用雲端同步
let localKit = try FuseStorageKitBuilder().build()

// 雲端版本 - 使用 Firebase 同步
FirebaseApp.configure(options: yourOptions)
let cloudKit = try FuseStorageKitBuilder()
                  .with(syncService: FirebaseSyncService())
                  .build()

// 完全自定義版本
let kit = try FuseStorageKitBuilder()
  .with(database: try GRDBDatabaseService(path: "custom.sqlite"))
  .with(preferences: DefaultPreferencesService(suiteName: "com.app.prefs"))
  .with(fileService: DefaultFileService.withBaseFolder("AppFiles"))
  .with(syncService: FirebaseSyncService())
  .build()
```

### 儲存資料範例

```swift
// 定義模型 (需符合 Codable & FetchableRecord & PersistableRecord)
struct Note: Codable, FetchableRecord, PersistableRecord {
    var id: String
    var title: String
    var content: String
    var createdAt: Date
}

// 新增記錄
let note = Note(id: UUID().uuidString, 
                title: "測試標題", 
                content: "這是測試內容", 
                createdAt: Date())

try kit.addRecord(note)

// 讀取記錄
let notes = try kit.fetchAll(of: Note.self)

// 儲存偏好設定
kit.setPreference(true, forKey: "isDarkMode")
let isDarkMode: Bool? = kit.getPreference(forKey: "isDarkMode")

// 儲存檔案
let image = UIImage(named: "photo")!
let url = try kit.saveImage(image, relativePath: "photos/profile.jpg")
```

## 需求

- iOS 13.0+ / macOS 11.0+
- Swift 5.6+
- Xcode 13.0+

## 依賴

- GRDB (本地資料庫)
- Firebase Storage (可選，用於雲端儲存) 