# FuseStorageKit 示範應用程式

這是一個使用 FuseStorageKit 的筆記應用程式，展示了 FuseStorageKit 主要功能的實際使用方式。

## 功能展示

1. **本地資料庫 (GRDB)**
   - 筆記的增刪改查操作
   - 標題搜尋功能

2. **檔案管理服務**
   - 儲存和讀取筆記圖片附件
   - 檔案管理和檔案路徑處理

3. **使用者偏好設定**
   - 暗黑/淺色主題設定
   - 設定的持久化儲存

4. **整合介面**
   - 使用 FuseStorageKit Builder 模式
   - 模組化架構設計

## 應用程式架構

本應用程式使用 MVVM 架構：

- **Models**: 定義資料結構和商業邏輯
  - `Note.swift`: 筆記模型
  - `AppDatabase.swift`: 擴展 GRDBDatabaseService
  - `AppStorage.swift`: 整合 FuseStorageKit 的核心服務

- **ViewModels**: 處理 UI 邏輯和資料流
  - `NotesViewModel.swift`: 管理筆記列表與操作

- **Views**: 使用者介面
  - `NotesListView.swift`: 主筆記列表頁面
  - `AddNoteView.swift`: 新增筆記頁面
  - `NoteRow.swift`: 筆記列表項目

## 如何執行

1. 確保您已 clone FuseStorageKit 儲存庫
2. 開啟 `FuseStorageKitExample.xcodeproj` 專案
3. 選擇模擬器或實體裝置
4. 運行應用程式

## 注意事項

- 本應用程式僅使用本地存儲，未啟用雲端同步功能
- 如果您要啟用 Firebase 同步，需要在 AppStorage.swift 中進行相應配置 