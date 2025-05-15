import XCTest
@testable import FuseStorageKit

final class FuseStorageTests: XCTestCase {
    
    func testBasicSetup() throws {
        // 測試基本的 SDK 建構
        let kit = try FuseStorageBuilder().build()
        XCTAssertNotNil(kit)
    }
    
    func testPreferencesService() throws {
        // 測試偏好設定服務
        let kit = try FuseStorageBuilder().build()
        
        // 使用預設的 UserDefaults preferences manager
        let preferencesQuery = FusePreferencesBuilderOption.userDefaults()
        guard let preferencesManager = try kit.pref(preferencesQuery) else {
            XCTFail("無法取得 preferences manager")
            return
        }
        
        // 儲存與讀取
        let testString = "測試字串"
        try preferencesManager.set(testString, forKey: "testKey")
        let retrievedString: String? = preferencesManager.get(forKey: "testKey")
        
        XCTAssertEqual(testString, retrievedString)
        
        // 測試其他類型
        try preferencesManager.set(42, forKey: "testInt")
        let retrievedInt: Int? = preferencesManager.get(forKey: "testInt")
        XCTAssertEqual(42, retrievedInt)
        
        try preferencesManager.set(true, forKey: "testBool")
        let retrievedBool: Bool? = preferencesManager.get(forKey: "testBool")
        XCTAssertEqual(true, retrievedBool)
    }
    
    func testDatabaseService() throws {
        // 測試資料庫服務
        let kit = try FuseStorageBuilder().build()
        
        // 使用預設的 SQLite database manager
        let databaseQuery = FuseDatabaseBuilderOption.sqlite()
        guard let databaseManager = kit.db(databaseQuery) else {
            XCTFail("無法取得 database manager")
            return
        }
        
        XCTAssertNotNil(databaseManager)
        // 注意：詳細的資料庫測試在 FuseDatabaseManagerTests.swift 中
    }
    
    func testFileService() throws {
        // 測試檔案服務
        let kit = try FuseStorageBuilder().build()
        
        // 使用預設的 Document file manager
        let fileQuery = FuseFileBuilderOption.document()
        guard let fileManager = kit.file(fileQuery) else {
            XCTFail("無法取得 file manager")
            return
        }
        
        XCTAssertNotNil(fileManager)
        
        // 測試取得檔案 URL
        let testPath = "test/example.txt"
        let fileURL = fileManager.url(for: testPath)
        XCTAssertNotNil(fileURL)
    }
    
    func testSyncService() throws {
        // 測試同步服務
        let kit = try FuseStorageBuilder().build()
        
        // 使用預設的 NoSync manager
        let syncQuery = FuseSyncBuilderOption.noSync()
        guard let syncManager = kit.sync(syncQuery) else {
            XCTFail("無法取得 sync manager")
            return
        }
        
        XCTAssertNotNil(syncManager)
    }
    
    func testMultipleManagersWithCustomNames() throws {
        // 測試使用自定義名稱的多個管理器
        let kit = try FuseStorageBuilder()
            .with(preferences: .userDefaults("com.test.app"))
            .with(file: .document("CustomFolder"))
            .build()
        
        // 測試自定義偏好設定管理器
        let customPrefsQuery = FusePreferencesBuilderOption.userDefaults("com.test.app")
        guard let customPrefsManager = kit.pref(customPrefsQuery) else {
            XCTFail("無法取得自定義 preferences manager")
            return
        }
        
        try customPrefsManager.set("custom value", forKey: "customKey")
        let retrievedValue: String? = customPrefsManager.get(forKey: "customKey")
        XCTAssertEqual("custom value", retrievedValue)
        
        // 測試自定義檔案管理器
        let customFileQuery = FuseFileBuilderOption.document("CustomFolder")
        guard let customFileManager = kit.file(customFileQuery) else {
            XCTFail("無法取得自定義 file manager")
            return
        }
        
        XCTAssertNotNil(customFileManager)
    }
    
    // 更多測試可以在這裡擴展
} 
