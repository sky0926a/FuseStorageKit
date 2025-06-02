# FuseStorageKit 模組系統改進

## 改進概述

我們對 FuseStorageKit 進行了重大改進，消除了冗餘代碼並實現了自動模組初始化，讓用戶體驗更加順暢。同時統一了註冊表系統，簡化了架構。

## 主要改進

### 1. 自動模組初始化系統

**之前**: 用戶需要手動調用 `FuseStorageSQLCipher.ensureInitialized()`
```swift
// 舊的方式 - 需要手動初始化
import FuseStorageSQLCipher
FuseStorageSQLCipher.ensureInitialized()
let dbManager = try FuseDatabaseManager()
```

**現在**: 模組在導入時自動註冊和初始化
```swift
// 新的方式 - 自動初始化
import FuseStorageSQLCipher
let dbManager = try FuseDatabaseManager() // 自動工作！
```

### 2. 統一的註冊表系統

**移除了多餘的註冊表**:
- 刪除了 `FuseDatabaseFactoryRegistry`
- 統一使用 `FuseStorageModuleRegistry` 管理所有服務

**新的統一註冊表**提供：
- **模組管理**: 自動模組發現和初始化
- **服務註冊**: 統一管理數據庫工廠、文件管理器等服務
- **可擴展性**: 未來的服務可以輕鬆集成

### 3. 移除冗餘代碼

**移除的重複組件**:
- 刪除了 `GRDBDatabaseFactory` (在 FuseStorageCore 中)
- 刪除了 `FuseDatabaseFactoryRegistry` (功能合併到 `FuseStorageModuleRegistry`)
- 簡化了 `FuseDatabaseManager` 的初始化邏輯
- 移除了 `ensureDatabaseFactoryAvailable()` 方法

**保留的組件**:
- `GRDBSQLCipherDatabaseFactory` (在 FuseStorageSQLCipher 中) - 實際的 GRDB 實現
- 所有的 wrapper 類別，提供完整的抽象層

### 4. 改進的統一服務管理

**新的統一註冊表**:
```swift
// 統一的 FuseStorageModuleRegistry 管理所有服務
public class FuseStorageModuleRegistry {
    // 模組管理
    static func registerModule(_ moduleType: FuseStorageModule.Type)
    static func initializeAllModules()
    
    // 數據庫工廠管理
    static func setDefaultDatabaseFactory(_ factory: FuseDatabaseFactory)
    static func getDefaultDatabaseFactory() throws -> FuseDatabaseFactory
    
    // 未來可以擴展其他服務...
}
```

## 新的架構優勢

### 1. 用戶體驗改進
- **零配置**: 導入模組即可使用
- **直觀性**: 不需要了解內部初始化邏輯
- **錯誤減少**: 消除了忘記初始化的問題

### 2. 開發者體驗改進
- **代碼簡潔**: 更少的樣板代碼
- **統一介面**: 所有服務通過統一註冊表管理
- **清晰的責任分離**: 每個組件都有明確的職責
- **更好的可測試性**: 統一的 `clearAll()` 方法清理所有註冊

### 3. 可維護性改進
- **單一註冊表**: 減少了複雜性，一個地方管理所有服務
- **可擴展**: 新服務可以輕鬆添加到統一註冊表
- **向後兼容**: 舊的 `ensureInitialized()` 方法仍然可用

## 技術實現詳情

### 統一模組協定
```swift
public protocol FuseStorageModule {
    static var moduleName: String { get }
    static func initialize()
    static var initialized: Bool { get }
}
```

### 統一註冊表
```swift
public class FuseStorageModuleRegistry {
    // 模組註冊
    private static var registeredModules: [String: FuseStorageModule.Type] = [:]
    private static var initializedModules: Set<String> = []
    
    // 服務註冊
    private static var defaultDatabaseFactory: FuseDatabaseFactory?
    
    // 統一管理所有註冊和初始化
}
```

### 自動註冊機制
```swift
// 在 FuseStorageSQLCipher 模組載入時自動執行
private let _fuseStorageSQLCipherModuleInitialized: Bool = {
    FuseStorageModuleRegistry.registerModule(FuseStorageSQLCipher.self)
    FuseStorageSQLCipher.initialize()
    return true
}()
```

### 智能初始化
```swift
public func ensureDatabaseModulesInitialized() {
    FuseStorageModuleRegistry.initializeAllModules()
    
    if !FuseStorageModuleRegistry.hasDefaultDatabaseFactory() {
        print("Warning: No database factory registered...")
    }
}
```

## 遷移指南

### 對於現有用戶

如果您之前使用 `ensureInitialized()`，無需更改任何代碼 - 它仍然有效：
```swift
// 這仍然有效（為了向後兼容）
FuseStorageSQLCipher.ensureInitialized()
let dbManager = try FuseDatabaseManager()
```

### 對於新用戶

只需導入模組即可：
```swift
import FuseStorageSQLCipher
let dbManager = try FuseDatabaseManager()
```

## 架構對比

### 之前的架構
```
FuseStorageModuleRegistry (模組管理)
        ↓
FuseDatabaseFactoryRegistry (數據庫工廠管理)
        ↓
FuseDatabaseManager
```

### 現在的架構
```
FuseStorageModuleRegistry (統一管理模組和服務)
        ↓
FuseDatabaseManager
```

## 測試改進

統一註冊表提供了更好的測試支援：
```swift
// 測試前清理所有註冊
FuseStorageModuleRegistry.clearAll()

// 測試後可以檢查狀態
XCTAssertTrue(FuseStorageModuleRegistry.isModuleInitialized("FuseStorageSQLCipher"))
XCTAssertTrue(FuseStorageModuleRegistry.hasDefaultDatabaseFactory())
```

## 未來擴展

這個統一的註冊表系統為未來的擴展奠定了更好的基礎：
```swift
// 未來可以輕鬆添加新的服務類型
FuseStorageModuleRegistry.setDefaultFileFactory(...)
FuseStorageModuleRegistry.setDefaultSyncFactory(...)
FuseStorageModuleRegistry.setDefaultCacheFactory(...)
```

每個新模組只需實現 `FuseStorageModule` 協定並在統一註冊表中註冊即可。 