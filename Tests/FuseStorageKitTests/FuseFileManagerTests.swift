//
//  FuseFileManagerTests.swift
//  FuseStorageKit
//
//  Created by jimmy on 2025/1/4.
//

import XCTest
@testable import FuseStorageKit
import Foundation

#if os(iOS) || os(tvOS) || os(watchOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

final class FuseFileManagerTests: XCTestCase {
    
    var fileManager: FuseFileManager!
    var tempDirectoryURL: URL!
    let testFolderName = "FuseFileManagerTests"
    
    override func setUp() {
        super.setUp()
        
        // Create a temporary directory for testing
        tempDirectoryURL = FileManager.default.temporaryDirectory()
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        
        // Initialize with temporary directory for testing
        fileManager = FuseFileManager(
            mainFolderName: testFolderName,
            searchPathDirectory: .cachesDirectory,
            domainMask: .userDomainMask
        )
        
        // Ensure test directory exists
        try? FileManager.default.createDirectory(
            at: tempDirectoryURL,
            withIntermediateDirectories: true,
            attributes: nil
        )
    }
    
    override func tearDown() {
        // Clean up test files and directories
        if let baseURL = fileManager?.url(for: "") {
            try? FileManager.default.removeItem(at: baseURL.deletingLastPathComponent())
        }
        
        if FileManager.default.fileExists(atPath: tempDirectoryURL.path) {
            try? FileManager.default.removeItem(at: tempDirectoryURL)
        }
        
        fileManager = nil
        tempDirectoryURL = nil
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testDefaultInitialization() {
        let defaultManager = FuseFileManager()
        let url = defaultManager.url(for: "test.txt")
        
        // Should create URL in Documents directory with default folder name
        XCTAssertTrue(url.path.contains("Documents"))
        XCTAssertTrue(url.path.contains("FuseStorageKit"))
    }
    
    func testCustomInitialization() {
        let customManager = FuseFileManager(
            mainFolderName: "CustomFolder",
            searchPathDirectory: .libraryDirectory,
            domainMask: .userDomainMask
        )
        
        let url = customManager.url(for: "test.txt")
        
        // Should create URL in Library directory with custom folder name
        XCTAssertTrue(url.path.contains("Library"))
        XCTAssertTrue(url.path.contains("CustomFolder"))
    }
    
    // MARK: - URL Generation Tests
    
    func testURLGeneration() {
        let relativePath = "subfolder/test.txt"
        let url = fileManager.url(for: relativePath)
        
        XCTAssertTrue(url.path.hasSuffix(relativePath))
        XCTAssertTrue(url.path.contains(testFolderName))
    }
    
    func testURLGenerationWithSpecialCharacters() {
        let relativePath = "special folder/file with spaces.txt"
        let url = fileManager.url(for: relativePath)
        
        XCTAssertTrue(url.path.contains("special folder"))
        XCTAssertTrue(url.path.contains("file with spaces.txt"))
    }
    
    // MARK: - Data Saving Tests
    
    func testSaveDataSuccess() throws {
        let testData = "Hello, World!".data(using: .utf8)!
        let relativePath = "test/data.txt"
        
        let savedURL = try fileManager.save(data: testData, relativePath: relativePath)
        
        // Verify file was saved
        XCTAssertTrue(FileManager.default.fileExists(atPath: savedURL.path))
        
        // Verify content is correct
        let retrievedData = try Data(contentsOf: savedURL)
        XCTAssertEqual(testData, retrievedData)
        
        // Verify URL matches expected path
        XCTAssertEqual(savedURL, fileManager.url(for: relativePath))
    }
    
    func testSaveDataWithNestedDirectories() throws {
        let testData = "Nested data".data(using: .utf8)!
        let relativePath = "deep/nested/folder/structure/file.json"
        
        let savedURL = try fileManager.save(data: testData, relativePath: relativePath)
        
        // Verify file was saved
        XCTAssertTrue(FileManager.default.fileExists(atPath: savedURL.path))
        
        // Verify content is correct
        let retrievedData = try Data(contentsOf: savedURL)
        XCTAssertEqual(testData, retrievedData)
    }
    
    func testSaveDataOverwritesExistingFile() throws {
        let relativePath = "overwrite/test.txt"
        
        // Save initial data
        let initialData = "Initial data".data(using: .utf8)!
        _ = try fileManager.save(data: initialData, relativePath: relativePath)
        
        // Overwrite with new data
        let newData = "New data".data(using: .utf8)!
        let savedURL = try fileManager.save(data: newData, relativePath: relativePath)
        
        // Verify new content
        let retrievedData = try Data(contentsOf: savedURL)
        XCTAssertEqual(newData, retrievedData)
        XCTAssertNotEqual(initialData, retrievedData)
    }
    
    // MARK: - Image Saving Tests
    
    func testSaveImageAsPNG() throws {
        let image = createTestImage()
        let fileName = "test_image.png"
        
        let savedURL = try fileManager.save(image: image, fileName: fileName)
        
        // Verify file was saved
        XCTAssertTrue(FileManager.default.fileExists(atPath: savedURL.path))
        
        // Verify it's a PNG file by reading header
        let data = try Data(contentsOf: savedURL)
        XCTAssertGreaterThan(data.count, 8)
        
        // PNG file signature: 89 50 4E 47 0D 0A 1A 0A
        let pngSignature = data.prefix(8)
        let expectedSignature = Data([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A])
        XCTAssertEqual(pngSignature, expectedSignature)
    }
    
    func testSaveImageAsJPEG() throws {
        let image = createTestImage()
        let fileName = "test_image.jpg"
        
        let savedURL = try fileManager.save(image: image, fileName: fileName)
        
        // Verify file was saved
        XCTAssertTrue(FileManager.default.fileExists(atPath: savedURL.path))
        
        // Verify it's a JPEG file by reading header
        let data = try Data(contentsOf: savedURL)
        XCTAssertGreaterThan(data.count, 2)
        
        // JPEG file signature: FF D8
        let jpegSignature = data.prefix(2)
        let expectedSignature = Data([0xFF, 0xD8])
        XCTAssertEqual(jpegSignature, expectedSignature)
    }
    
    func testSaveImageWithoutExtensionDefaultsToJPEG() throws {
        let image = createTestImage()
        let fileName = "test_image_no_extension"
        
        let savedURL = try fileManager.save(image: image, fileName: fileName)
        
        // Verify file was saved
        XCTAssertTrue(FileManager.default.fileExists(atPath: savedURL.path))
        
        // Should default to JPEG format
        let data = try Data(contentsOf: savedURL)
        let jpegSignature = data.prefix(2)
        let expectedSignature = Data([0xFF, 0xD8])
        XCTAssertEqual(jpegSignature, expectedSignature)
    }
    
    func testSaveImageWithUnsupportedExtensionDefaultsToJPEG() throws {
        let image = createTestImage()
        let fileName = "test_image.bmp"
        
        let savedURL = try fileManager.save(image: image, fileName: fileName)
        
        // Should default to JPEG format for unsupported extensions
        let data = try Data(contentsOf: savedURL)
        let jpegSignature = data.prefix(2)
        let expectedSignature = Data([0xFF, 0xD8])
        XCTAssertEqual(jpegSignature, expectedSignature)
    }
    
    // MARK: - File Deletion Tests
    
    func testDeleteExistingFile() throws {
        let testData = "Delete me".data(using: .utf8)!
        let relativePath = "delete/test.txt"
        
        // First, save a file
        let savedURL = try fileManager.save(data: testData, relativePath: relativePath)
        XCTAssertTrue(FileManager.default.fileExists(atPath: savedURL.path))
        
        // Then delete it
        try fileManager.delete(relativePath: relativePath)
        
        // Verify file is deleted
        XCTAssertFalse(FileManager.default.fileExists(atPath: savedURL.path))
    }
    
    func testDeleteNonExistentFileDoesNotThrow() {
        let relativePath = "nonexistent/file.txt"
        
        // Should not throw an error when deleting non-existent file
        XCTAssertNoThrow(try fileManager.delete(relativePath: relativePath))
    }
    
    func testDeleteMultipleFiles() throws {
        let testData = "Test data".data(using: .utf8)!
        let paths = ["file1.txt", "folder/file2.txt", "deep/nested/file3.txt"]
        
        // Save multiple files
        var savedURLs: [URL] = []
        for path in paths {
            let url = try fileManager.save(data: testData, relativePath: path)
            savedURLs.append(url)
        }
        
        // Verify all files exist
        for url in savedURLs {
            XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
        }
        
        // Delete all files
        for path in paths {
            try fileManager.delete(relativePath: path)
        }
        
        // Verify all files are deleted
        for url in savedURLs {
            XCTAssertFalse(FileManager.default.fileExists(atPath: url.path))
        }
    }
    
    // MARK: - Integration Tests
    
    func testCompleteWorkflow() throws {
        let image = createTestImage()
        let fileName = "workflow_test.png"
        
        // Save image
        let savedURL = try fileManager.save(image: image, fileName: fileName)
        XCTAssertTrue(FileManager.default.fileExists(atPath: savedURL.path))
        
        // Verify URL generation
        let generatedURL = fileManager.url(for: fileName)
        XCTAssertEqual(savedURL, generatedURL)
        
        // Delete image
        try fileManager.delete(relativePath: fileName)
        XCTAssertFalse(FileManager.default.fileExists(atPath: savedURL.path))
    }
    
    func testWorkflowWithComplexPath() throws {
        let testData = "Complex path test".data(using: .utf8)!
        let relativePath = "users/123/profiles/avatar/image_v2.json"
        
        // Save data
        let savedURL = try fileManager.save(data: testData, relativePath: relativePath)
        XCTAssertTrue(FileManager.default.fileExists(atPath: savedURL.path))
        
        // Verify content
        let retrievedData = try Data(contentsOf: savedURL)
        XCTAssertEqual(testData, retrievedData)
        
        // Verify URL
        let generatedURL = fileManager.url(for: relativePath)
        XCTAssertEqual(savedURL, generatedURL)
        
        // Delete
        try fileManager.delete(relativePath: relativePath)
        XCTAssertFalse(FileManager.default.fileExists(atPath: savedURL.path))
    }
    
    // MARK: - Helper Methods
    
    private func createTestImage() -> FuseImage {
        #if os(iOS) || os(tvOS) || os(watchOS)
        // Create a simple 1x1 pixel image for testing
        let size = CGSize(width: 1, height: 1)
        UIGraphicsBeginImageContext(size)
        let context = UIGraphicsGetCurrentContext()!
        context.setFillColor(UIColor.red.cgColor)
        context.fill(CGRect(origin: .zero, size: size))
        let image = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return image
        #elseif os(macOS)
        // Create a simple 1x1 pixel image for testing
        let size = NSSize(width: 1, height: 1)
        let image = NSImage(size: size)
        image.lockFocus()
        NSColor.red.setFill()
        NSRect(origin: .zero, size: size).fill()
        image.unlockFocus()
        return image
        #endif
    }
} 