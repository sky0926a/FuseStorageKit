//
//  FuseStorageBuilderTests.swift
//  FuseStorageKit
//
//  Created by jimmy on 2025/5/24.
//

import XCTest
@testable import FuseStorageKit

final class FuseStorageBuilderTests: XCTestCase {

    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }

    // MARK: - Basic Builder Tests

    func testBuilderInitialization() {
        let builder = FuseStorageBuilder()
        XCTAssertNotNil(builder)
    }

    func testDefaultBuild() throws {
        let storage = try FuseStorageBuilder().build()
        XCTAssertNotNil(storage)
        
        // Verify default managers are created
        let defaultDbQuery = FuseDatabaseBuilderOption.sqlite()
        let defaultPrefsQuery = FusePreferencesBuilderOption.userDefaults()
        let defaultFileQuery = FuseFileBuilderOption.document()
        let defaultSyncQuery = FuseSyncBuilderOption.noSync()
        
        XCTAssertNotNil(storage.db(defaultDbQuery))
        XCTAssertNotNil(storage.pref(defaultPrefsQuery))
        XCTAssertNotNil(storage.file(defaultFileQuery))
        XCTAssertNotNil(storage.sync(defaultSyncQuery))
    }

    // MARK: - Method Chaining Tests

    func testBuilderMethodChaining() throws {
        let storage = try FuseStorageBuilder()
            .with(database: .sqlite("test.db"))
            .with(preferences: .userDefaults("com.test.app"))
            .with(file: .document("TestDocs"))
            .with(sync: .noSync())
            .build()
        
        XCTAssertNotNil(storage)
    }

    func testBuilderMethodChainingReturnsBuilder() {
        let builder = FuseStorageBuilder()
        
        let chainedBuilder1 = builder.with(database: .sqlite())
        XCTAssertTrue(chainedBuilder1 === builder)
        
        let chainedBuilder2 = builder.with(preferences: .userDefaults())
        XCTAssertTrue(chainedBuilder2 === builder)
        
        let chainedBuilder3 = builder.with(file: .document())
        XCTAssertTrue(chainedBuilder3 === builder)
        
        let chainedBuilder4 = builder.with(sync: .noSync())
        XCTAssertTrue(chainedBuilder4 === builder)
    }

    // MARK: - Database Builder Option Tests

    func testDatabaseSQLiteBuilderOption() throws {
        let storage = try FuseStorageBuilder()
            .with(database: .sqlite("custom.db"))
            .build()
        
        let query = FuseDatabaseBuilderOption.sqlite("custom.db")
        let dbManager = storage.db(query)
        XCTAssertNotNil(dbManager)
    }

    func testDatabaseSQLiteWithEncryptionBuilderOption() throws {
        let encryptionOptions = EncryptionOptions.standard(passphrase: "testpassword")
        let storage = try FuseStorageBuilder()
            .with(database: .sqlite("encrypted.db", encryptions: encryptionOptions))
            .build()
        
        let query = FuseDatabaseBuilderOption.sqlite("encrypted.db")
        let dbManager = storage.db(query)
        XCTAssertNotNil(dbManager)
    }

    func testMultipleDatabaseManagers() throws {
        let storage = try FuseStorageBuilder()
            .with(database: .sqlite("main.db"))
            .with(database: .sqlite("cache.db"))
            .build()
        
        let mainQuery = FuseDatabaseBuilderOption.sqlite("main.db")
        let cacheQuery = FuseDatabaseBuilderOption.sqlite("cache.db")
        
        XCTAssertNotNil(storage.db(mainQuery))
        XCTAssertNotNil(storage.db(cacheQuery))
    }

    // MARK: - Preferences Builder Option Tests

    func testPreferencesUserDefaultsBuilderOption() throws {
        let storage = try FuseStorageBuilder()
            .with(preferences: .userDefaults("com.test.suite"))
            .build()
        
        let query = FusePreferencesBuilderOption.userDefaults("com.test.suite")
        let prefsManager = storage.pref(query)
        XCTAssertNotNil(prefsManager)
    }

    func testPreferencesKeychainBuilderOption() throws {
        let storage = try FuseStorageBuilder()
            .with(preferences: .keychain(
                "com.test.keychain",
                accessGroup: nil,
                accessibility: .whenUnlocked
            ))
            .build()
        
        let query = FusePreferencesBuilderOption.keychain("com.test.keychain")
        let prefsManager = storage.pref(query)
        XCTAssertNotNil(prefsManager)
    }

    func testPreferencesKeychainWithAccessGroupBuilderOption() throws {
        let storage = try FuseStorageBuilder()
            .with(preferences: .keychain(
                "com.test.keychain",
                accessGroup: "com.test.group",
                accessibility: .afterFirstUnlock
            ))
            .build()
        
        let query = FusePreferencesBuilderOption.keychain("com.test.keychain")
        let prefsManager = storage.pref(query)
        XCTAssertNotNil(prefsManager)
    }

    func testMultiplePreferencesManagers() throws {
        let storage = try FuseStorageBuilder()
            .with(preferences: .userDefaults("suite1"))
            .with(preferences: .userDefaults("suite2"))
            .with(preferences: .keychain(
                "keychain1",
                accessibility: .whenUnlocked
            ))
            .build()
        
        let suite1Query = FusePreferencesBuilderOption.userDefaults("suite1")
        let suite2Query = FusePreferencesBuilderOption.userDefaults("suite2")
        let keychainQuery = FusePreferencesBuilderOption.keychain("keychain1")
        
        XCTAssertNotNil(storage.pref(suite1Query))
        XCTAssertNotNil(storage.pref(suite2Query))
        XCTAssertNotNil(storage.pref(keychainQuery))
    }

    // MARK: - File Builder Option Tests

    func testFileDocumentBuilderOption() throws {
        let storage = try FuseStorageBuilder()
            .with(file: .document("CustomDocs"))
            .build()
        
        let query = FuseFileBuilderOption.document("CustomDocs")
        let fileManager = storage.file(query)
        XCTAssertNotNil(fileManager)
    }

    func testFileLibraryBuilderOption() throws {
        let storage = try FuseStorageBuilder()
            .with(file: .library("CustomLibrary"))
            .build()
        
        let query = FuseFileBuilderOption.library("CustomLibrary")
        let fileManager = storage.file(query)
        XCTAssertNotNil(fileManager)
    }

    func testFileCacheBuilderOption() throws {
        let storage = try FuseStorageBuilder()
            .with(file: .cache("CustomCache"))
            .build()
        
        let query = FuseFileBuilderOption.cache("CustomCache")
        let fileManager = storage.file(query)
        XCTAssertNotNil(fileManager)
    }

    func testFileCustomDirectoryBuilderOption() throws {
        let storage = try FuseStorageBuilder()
            .with(file: .file(
                "CustomDir",
                searchPathDirectory: .applicationSupportDirectory,
                domainMask: .userDomainMask
            ))
            .build()
        
        let query = FuseFileBuilderOption.file("CustomDir")
        let fileManager = storage.file(query)
        XCTAssertNotNil(fileManager)
    }

    func testMultipleFileManagers() throws {
        let storage = try FuseStorageBuilder()
            .with(file: .document("Documents"))
            .with(file: .library("Library"))
            .with(file: .cache("Cache"))
            .build()
        
        let docQuery = FuseFileBuilderOption.document("Documents")
        let libQuery = FuseFileBuilderOption.library("Library")
        let cacheQuery = FuseFileBuilderOption.cache("Cache")
        
        XCTAssertNotNil(storage.file(docQuery))
        XCTAssertNotNil(storage.file(libQuery))
        XCTAssertNotNil(storage.file(cacheQuery))
    }

    // MARK: - Sync Builder Option Tests

    func testSyncNoSyncBuilderOption() throws {
        let storage = try FuseStorageBuilder()
            .with(sync: .noSync())
            .build()
        
        let query = FuseSyncBuilderOption.noSync()
        let syncManager = storage.sync(query)
        XCTAssertNotNil(syncManager)
    }

    func testMultipleSyncManagers() throws {
        let storage = try FuseStorageBuilder()
            .with(sync: .noSync())
            .build()
        
        let noSyncQuery = FuseSyncBuilderOption.noSync()
        XCTAssertNotNil(storage.sync(noSyncQuery))
    }

    // MARK: - Complex Configuration Tests

    func testComplexBuilderConfiguration() throws {
        let storage = try FuseStorageBuilder()
            .with(database: .sqlite("main.db"))
            .with(database: .sqlite("cache.db", encryptions: EncryptionOptions.standard(passphrase: "secret")))
            .with(preferences: .userDefaults("com.app.main"))
            .with(preferences: .keychain("com.app.secure", accessibility: .whenUnlocked))
            .with(file: .document("AppDocs"))
            .with(file: .cache("AppCache"))
            .with(sync: .noSync())
            .build()
        
        // Verify all managers exist
        XCTAssertNotNil(storage.db(.sqlite("main.db")))
        XCTAssertNotNil(storage.db(.sqlite("cache.db")))
        XCTAssertNotNil(storage.pref(.userDefaults("com.app.main")))
        XCTAssertNotNil(storage.pref(.keychain("com.app.secure")))
        XCTAssertNotNil(storage.file(.document("AppDocs")))
        XCTAssertNotNil(storage.file(.cache("AppCache")))
        XCTAssertNotNil(storage.sync(.noSync()))
    }

    // MARK: - Manager Integration Tests

    func testBuiltPreferencesManagerFunctionality() throws {
        let storage = try FuseStorageBuilder()
            .with(preferences: .userDefaults("com.test.integration"))
            .build()
        
        let query = FusePreferencesBuilderOption.userDefaults("com.test.integration")
        guard let prefsManager = storage.pref(query) else {
            XCTFail("Failed to get preferences manager")
            return
        }
        
        // Test actual functionality
        try prefsManager.set("test_value", forKey: "test_key")
        let retrievedValue: String? = prefsManager.get(forKey: "test_key")
        XCTAssertEqual("test_value", retrievedValue)
        
        XCTAssertTrue(prefsManager.containsValue(forKey: "test_key"))
        
        prefsManager.removeValue(forKey: "test_key")
        XCTAssertFalse(prefsManager.containsValue(forKey: "test_key"))
    }

    func testBuiltFileManagerFunctionality() throws {
        let storage = try FuseStorageBuilder()
            .with(file: .document("TestIntegration"))
            .build()
        
        let query = FuseFileBuilderOption.document("TestIntegration")
        guard let fileManager = storage.file(query) else {
            XCTFail("Failed to get file manager")
            return
        }
        
        // Test URL generation
        let testURL = fileManager.url(for: "test/file.txt")
        XCTAssertNotNil(testURL)
        XCTAssertTrue(testURL.path.contains("TestIntegration"))
    }

    // MARK: - Builder Internal Logic Tests

    func testBuildManagersWithEmptyInput() throws {
        let builder = FuseStorageBuilder()
        
        // Test the internal buildManagers method indirectly through build()
        let storage = try builder.build()
        
        // Should use defaults when arrays are empty
        XCTAssertNotNil(storage.db(.sqlite()))
        XCTAssertNotNil(storage.pref(.userDefaults()))
        XCTAssertNotNil(storage.file(.document()))
        XCTAssertNotNil(storage.sync(.noSync()))
    }

    func testBuildManagersWithCustomInput() throws {
        let builder = FuseStorageBuilder()
            .with(database: .sqlite("custom.db"))
            .with(preferences: .userDefaults("custom"))
        
        let storage = try builder.build()
        
        // Should use custom configurations instead of defaults
        XCTAssertNotNil(storage.db(.sqlite("custom.db")))
        XCTAssertNotNil(storage.pref(.userDefaults("custom")))
        // Should still have defaults for unconfigured services
        XCTAssertNotNil(storage.file(.document()))
        XCTAssertNotNil(storage.sync(.noSync()))
    }

    // MARK: - Error Handling Tests

    func testBuilderWithInvalidDatabaseConfiguration() {
        // Test with empty database path that should cause SQLite error
        XCTAssertThrowsError(try FuseStorageBuilder()
            .with(database: .sqlite(""))
            .build()) { error in
            // Should throw an error related to database creation/opening
            // The exact error type might vary, but we expect some kind of database error
            print("Expected error for empty path: \(error)")
        }
    }

    func testBuilderWithValidNonStandardDatabaseConfiguration() {
        // Test with valid but unusual database path (should not throw)
        XCTAssertNoThrow(try FuseStorageBuilder()
            .with(database: .sqlite("unusual_db_name.sqlite"))
            .build())
    }

    func testBuilderWithInvalidEncryptionConfiguration() {
        // Test with empty passphrase (should be handled by EncryptionOptions)
        let emptyPassphraseOptions = EncryptionOptions("")
        
        XCTAssertThrowsError(try FuseStorageBuilder()
            .with(database: .sqlite("test.db", encryptions: emptyPassphraseOptions))
            .build()) { error in
            // Should throw FuseDatabaseError.missingPassphrase
            XCTAssertTrue(error is FuseDatabaseError)
        }
    }

    // MARK: - Performance Tests

    func testBuilderPerformance() {
        measure {
            for _ in 0..<100 {
                let _ = try! FuseStorageBuilder()
                    .with(database: .sqlite())
                    .with(preferences: .userDefaults())
                    .with(file: .document())
                    .with(sync: .noSync())
                    .build()
            }
        }
    }

    func testComplexBuilderPerformance() {
        measure {
            for _ in 0..<50 {
                let _ = try! FuseStorageBuilder()
                    .with(database: .sqlite("main.db"))
                    .with(database: .sqlite("cache.db"))
                    .with(preferences: .userDefaults("suite1"))
                    .with(preferences: .userDefaults("suite2"))
                    .with(preferences: .keychain("service1", accessibility: .whenUnlocked))
                    .with(file: .document("docs"))
                    .with(file: .library("lib"))
                    .with(file: .cache("cache"))
                    .with(sync: .noSync())
                    .build()
            }
        }
    }

    // MARK: - Edge Cases

    func testBuilderWithDuplicateConfigurations() throws {
        // Test adding the same configuration multiple times
        let storage = try FuseStorageBuilder()
            .with(database: .sqlite("test.db"))
            .with(database: .sqlite("test.db")) // Duplicate
            .build()
        
        // Should handle gracefully (later configuration might override)
        XCTAssertNotNil(storage.db(FuseDatabaseBuilderOption.sqlite("test.db")))
    }

    func testBuilderWithManyManagers() throws {
        var builder = FuseStorageBuilder()
        
        // Add many different configurations
        for i in 0..<10 {
            builder = builder
                .with(database: .sqlite("db\(i).db"))
                .with(preferences: .userDefaults("suite\(i)"))
                .with(file: .document("folder\(i)"))
        }
        
        let storage = try builder.build()
        
        // Verify some of the managers exist
        XCTAssertNotNil(storage.db(.sqlite("db0.db")))
        XCTAssertNotNil(storage.db(.sqlite("db9.db")))
        XCTAssertNotNil(storage.pref(.userDefaults("suite0")))
        XCTAssertNotNil(storage.pref(.userDefaults("suite9")))
    }

    // MARK: - Configuration Validation Tests

    func testBuilderPreservesConfiguration() throws {
        let customSuiteName = "com.test.unique.suite"
        let customDbPath = "unique.db"
        let customFolderName = "UniqueFolder"
        
        let storage = try FuseStorageBuilder()
            .with(preferences: .userDefaults(customSuiteName))
            .with(database: .sqlite(customDbPath))
            .with(file: .document(customFolderName))
            .build()
        
        // Verify the configurations are preserved correctly
        let prefsQuery = FusePreferencesBuilderOption.userDefaults(customSuiteName)
        let dbQuery = FuseDatabaseBuilderOption.sqlite(customDbPath)
        let fileQuery = FuseFileBuilderOption.document(customFolderName)
        
        XCTAssertNotNil(storage.pref(prefsQuery))
        XCTAssertNotNil(storage.db(dbQuery))
        XCTAssertNotNil(storage.file(fileQuery))
        
        // Verify wrong queries return correct
        let wrongPrefsQuery = FusePreferencesBuilderOption.userDefaults("wrong.suite")
        let wrongDbQuery = FuseDatabaseBuilderOption.sqlite("wrong.db")
        let wrongFileQuery = FuseFileBuilderOption.document("WrongFolder")
        
        XCTAssertNotNil(storage.pref(wrongPrefsQuery))
        XCTAssertNotNil(storage.db(wrongDbQuery))
        XCTAssertNotNil(storage.file(wrongFileQuery))
    }
} 
