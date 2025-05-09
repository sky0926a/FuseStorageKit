import XCTest
@testable import FuseStorageKit

final class FuseStorageKitTests: XCTestCase {
    
    func testBasicSetup() throws {
        // 測試基本的 SDK 建構
        let kit = try FuseStorageKitBuilder().build()
        XCTAssertNotNil(kit)
    }
    
    func testPreferencesService() throws {
        // 測試偏好設定服務
        let kit = try FuseStorageKitBuilder().build()
        
        // 儲存與讀取
        let testString = "測試字串"
        kit.preferences.set(testString, forKey: "testKey")
        let retrievedString: String? = kit.preferences.get(forKey: "testKey")
        
        XCTAssertEqual(testString, retrievedString)
    }
    
    // 更多測試可以在這裡擴展
} 
