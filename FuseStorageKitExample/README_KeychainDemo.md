# FuseStorageKit Keychain 示例

本文件說明如何在 FuseStorageKitExample 中使用 Keychain 功能。

## 新增的檔案

### 1. UserInfo.swift
用戶資訊模型，包含：
- 基本用戶資料（ID、用戶名、電子郵件等）
- 用戶偏好設定
- 便利的工廠方法和更新方法

### 2. KeychainDemoView.swift
示範 Keychain 功能的完整 SwiftUI 視圖，包含：
- 用戶憑證保存/讀取
- 存取令牌管理
- 用戶資訊儲存
- 偏好設定同步
- 認證狀態檢查

## 修改的檔案

### AppStorage.swift 
添加了以下 Keychain 相關功能：

#### 1. Keychain 配置
```swift
// 在 FuseStorageBuilder 中添加 keychain 配置
.with(preferences: .keychain("com.fusestoragekit.user", accessibility: .whenUnlocked))

// 添加 keychain 屬性
var keychain: FusePreferencesManageable {
    return storageKit.pref(.keychain("com.fusestoragekit.user"))!
}
```

#### 2. 用戶認證相關方法
- `saveUserToken(_:)` - 儲存用戶登入令牌
- `getUserToken()` - 取得用戶登入令牌
- `saveUserPassword(_:for:)` - 儲存用戶密碼
- `getUserPassword(for:)` - 取得用戶密碼
- `saveUserInfo(_:)` - 儲存用戶資訊
- `getUserInfo()` - 取得用戶資訊
- `saveBiometricEnabled(_:)` - 儲存生物識別設定
- `getBiometricEnabled()` - 取得生物識別設定
- `clearUserAuth()` - 清除所有認證資訊
- `clearUserPassword(for:)` - 清除特定用戶密碼
- `isUserLoggedIn()` - 檢查登入狀態

### NotesListView.swift
添加了：
- Keychain Demo 按鈕（鑰匙圖標）
- 導航到 KeychainDemoView 的功能

## Keychain 功能特色

### 1. 安全性
- 使用 iOS Keychain 服務進行敏感資料儲存
- 支援不同的可訪問性選項（.whenUnlocked、.afterFirstUnlock 等）
- 自動加密和解密

### 2. 資料類型支援
FuseStorageKit 的 Keychain 管理器支援多種資料類型：
- 基本類型：String, Int, Double, Bool, Date, Data
- Codable 類型：自動 JSON 序列化/反序列化
- 複雜物件：如 UserInfo 結構

### 3. 類型安全
- 泛型方法確保類型安全
- 編譯時期檢查

## 使用示例

### 基本用法

```swift
// 儲存字串
AppStorage.shared.saveUserToken("abc123")

// 讀取字串
let token = AppStorage.shared.getUserToken()

// 儲存複雜物件
let user = UserInfo.demo
AppStorage.shared.saveUserInfo(user)

// 讀取複雜物件
let savedUser = AppStorage.shared.getUserInfo()
```

### 在 SwiftUI 中使用

```swift
@State private var token = ""

// 儲存
Button("Save Token") {
    AppStorage.shared.saveUserToken(token)
}

// 讀取
Button("Load Token") {
    if let savedToken = AppStorage.shared.getUserToken() {
        token = savedToken
    }
}
```

## Keychain vs UserDefaults

| 特性 | Keychain | UserDefaults |
|------|----------|--------------|
| 安全性 | 高（加密儲存） | 低（明文儲存） |
| 適用資料 | 密碼、令牌、敏感資訊 | 一般偏好設定 |
| 備份 | 可選擇是否備份 | 會被備份 |
| 存取控制 | 支援生物識別、密碼保護 | 無 |
| 效能 | 較慢（安全性換取） | 較快 |

## 最佳實踐

1. **敏感資料使用 Keychain**：密碼、API 金鑰、存取令牌
2. **一般設定使用 UserDefaults**：主題偏好、語言設定
3. **選擇適當的可訪問性**：根據應用需求選擇 .whenUnlocked 或 .afterFirstUnlock
4. **錯誤處理**：始終處理 Keychain 操作可能的錯誤
5. **資料清理**：登出時清除敏感資料

## 執行示例

1. 在 Xcode 中執行 FuseStorageKitExample
2. 點擊右上角的鑰匙圖標按鈕
3. 在 Keychain Demo 視圖中測試各種功能：
   - 輸入用戶名和密碼並儲存
   - 儲存和讀取存取令牌
   - 儲存示範用戶資訊
   - 測試偏好設定同步
   - 檢查認證狀態
   - 清除資料功能

這個示例展示了 FuseStorageKit 如何簡化 iOS Keychain 的使用，同時保持類型安全和現代 Swift 開發的最佳實踐。 