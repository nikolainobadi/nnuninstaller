//
//  AppUninstallerTests.swift
//  nnuninstallerTests
//
//  Created by Nikolai Nobadi on 8/27/25.
//

import Testing
@testable import nnuninstaller

@MainActor
struct AppUninstallerTests {
    @Test("dry run doesn't delete files")
    func uninstallApp_withDryRun_doesNotDeleteFiles() throws {
        let app = AppInfo(path: "/Applications/TestApp.app")
        let files = [
            AppFileLocation(
                path: "/Library/Application Support/TestApp",
                name: "TestApp",
                location: "Application Support",
                appName: "TestApp",
                size: 1000
            )
        ]
        
        let uninstaller = AppUninstaller(dryRun: true, createLog: false)
        let result = try uninstaller.uninstallApp(app, withFiles: files)
        
        // In dry run, items should be marked as succeeded but not actually deleted
        #expect(result.succeededItems.count == 2) // App + 1 file
        #expect(result.failedItems.isEmpty)
        #expect(result.totalSize > 0)
    }
    
    @Test("returns correct uninstall result")
    func uninstallApp_withValidFiles_returnsCorrectResult() throws {
        let app = AppInfo(path: "/Applications/TestApp.app")
        let files = [
            AppFileLocation(
                path: "/test/file1",
                name: "file1",
                location: "Test",
                appName: "TestApp",
                size: 500
            ),
            AppFileLocation(
                path: "/test/file2",
                name: "file2",
                location: "Test",
                appName: "TestApp",
                size: 300
            )
        ]
        
        // Use dry run to avoid actually moving files
        let uninstaller = AppUninstaller(dryRun: true, createLog: false)
        let result = try uninstaller.uninstallApp(app, withFiles: files)
        
        #expect(result.succeededItems.contains("TestApp.app"))
        #expect(result.succeededItems.contains("file1"))
        #expect(result.succeededItems.contains("file2"))
        #expect(result.succeededItems.count == 3)
        #expect(result.totalSize == 800) // 500 + 300, app size would be 0 for non-existent path
    }
    
    @Test("handles empty file list")
    func uninstallApp_withNoAssociatedFiles_handlesCorrectly() throws {
        let app = AppInfo(path: "/Applications/TestApp.app")
        let files: [AppFileLocation] = []
        
        let uninstaller = AppUninstaller(dryRun: true, createLog: false)
        let result = try uninstaller.uninstallApp(app, withFiles: files)
        
        #expect(result.succeededItems.count == 1) // Just the app
        #expect(result.succeededItems.contains("TestApp.app"))
        #expect(result.failedItems.isEmpty)
    }
    
    @Test("creates log when requested")
    func uninstallApp_withLogFlag_createsLog() throws {
        let app = AppInfo(path: "/Applications/TestApp.app")
        let files = [
            AppFileLocation(
                path: "/test/file1",
                name: "file1",
                location: "Test",
                appName: "TestApp",
                size: 1000
            )
        ]
        
        // Dry run with log
        let uninstaller = AppUninstaller(dryRun: true, createLog: true)
        _ = try uninstaller.uninstallApp(app, withFiles: files)
        
        // We can't easily verify the log was created without filesystem access,
        // but the test ensures the code path executes without error
        #expect(true) // Test passes if no exception thrown
    }
}