//
//  FileSystemTests.swift
//  nnuninstallerTests
//
//  Created by Nikolai Nobadi on 8/27/25.
//

import Testing
import Foundation
@testable import nnuninstaller

struct FileSystemTests {
    @Test("DefaultFileSystem delegates to FileManager correctly")
    func defaultFileSystem_contentsOfDirectory_delegatesToFileManager() throws {
        let sut = DefaultFileSystem()
        let validPath = "/Applications"
        
        // Test that it doesn't throw for a valid system path
        // Note: This test assumes /Applications exists on the system
        #expect(throws: Never.self) {
            let contents = try sut.contentsOfDirectory(atPath: validPath)
            #expect(contents.count >= 0) // Should return an array (empty or with contents)
        }
    }
    
    @Test("DefaultFileSystem throws error with invalid path")
    func defaultFileSystem_withInvalidPath_throwsError() throws {
        let sut = DefaultFileSystem()
        let invalidPath = "/this/path/definitely/does/not/exist"
        
        #expect(throws: (any Error).self) {
            try sut.contentsOfDirectory(atPath: invalidPath)
        }
    }
    
    @Test("DefaultFileSystem returns empty array for empty directory")
    func defaultFileSystem_withEmptyDirectory_returnsEmptyArray() throws {
        let sut = DefaultFileSystem()
        
        // Create a temporary directory for testing
        let tempDir = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("nnuninstaller-test-\(UUID().uuidString)")
        
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer {
            try? FileManager.default.removeItem(at: tempDir)
        }
        
        let contents = try sut.contentsOfDirectory(atPath: tempDir.path)
        #expect(contents.isEmpty)
    }
    
    @Test("DefaultFileSystem returns correct contents for directory with files")
    func defaultFileSystem_withFilesInDirectory_returnsCorrectContents() throws {
        let sut = DefaultFileSystem()
        
        // Create a temporary directory with some files
        let tempDir = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("nnuninstaller-test-\(UUID().uuidString)")
        
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer {
            try? FileManager.default.removeItem(at: tempDir)
        }
        
        // Create test files
        let testFiles = ["TestApp1.app", "TestApp2.app", "NonApp.txt"]
        for fileName in testFiles {
            let fileURL = tempDir.appendingPathComponent(fileName)
            try FileManager.default.createDirectory(at: fileURL, withIntermediateDirectories: true)
        }
        
        let contents = try sut.contentsOfDirectory(atPath: tempDir.path)
        #expect(contents.count == testFiles.count)
        
        for fileName in testFiles {
            #expect(contents.contains(fileName))
        }
    }
}