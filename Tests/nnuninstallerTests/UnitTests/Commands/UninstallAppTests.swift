//
//  UninstallAppTests.swift
//  nnuninstallerTests
//
//  Created by Nikolai Nobadi on 8/27/25.
//

import Testing
import NnShellKit
import ArgumentParser
@testable import nnuninstaller

@MainActor
struct UninstallAppTests {
    @Test("dry run executes without deleting")
    func run_withDryRunFlag_executesWithoutDeleting() throws {
        let shell = MockShell(results: [""])  // Non-Apple app
        let fileSystem = MockFileSystem(
            directoryContents: [
                "/Applications": ["TestApp.app"],
                "/home/Library/Application Support": ["TestApp"],
                "/home/Library/Caches": ["com.TestApp.cache"]
            ]
        )
        let picker = MockPicker(
            permissionResponses: [
                "⚠️  Confirmation: Move all 1 items to trash?": true
            ],
            selectionResponses: [
                "Select an application to uninstall:": 0,  // Select TestApp
                "Choose an action:": 0  // Select "Remove all items"
            ]
        )
        let context = MockContext(shell: shell, picker: picker, fileSystem: fileSystem)
        
        // Run with dry-run flag
        try Nnuninstaller.testRun(context: context, args: ["uninstall", "--dry-run"])
        
        // Verify picker interactions
        #expect(picker.selections.contains("Select an application to uninstall:"))
        #expect(picker.selections.contains("Choose an action:"))
        #expect(picker.permissions.contains("⚠️  Confirmation: Move all 1 items to trash?"))
    }
    
    @Test("force flag skips confirmations")
    func run_withForceFlag_skipsConfirmations() throws {
        let shell = MockShell(results: [""])
        let fileSystem = MockFileSystem(
            directoryContents: ["/Applications": ["TestApp.app"]]
        )
        let picker = MockPicker(
            selectionResponses: ["Select an application to uninstall:": 0]
        )
        let context = MockContext(shell: shell, picker: picker, fileSystem: fileSystem)
        
        // Run with force and dry-run flags (dry-run to avoid actual deletion)
        try Nnuninstaller.testRun(context: context, args: ["uninstall", "--force", "--dry-run"])
        
        // Should not ask for permission with force flag
        #expect(picker.permissions.isEmpty)
    }
    
    @Test("cancel option exits without changes")
    func run_withCancelOption_exitsWithoutChanges() throws {
        let shell = MockShell(results: [""])
        let fileSystem = MockFileSystem(
            directoryContents: ["/Applications": ["TestApp.app"]]
        )
        let picker = MockPicker(
            selectionResponses: [
                "Select an application to uninstall:": 0,
                "Choose an action:": 2  // Select "Cancel"
            ]
        )
        let context = MockContext(shell: shell, picker: picker, fileSystem: fileSystem)
        
        try Nnuninstaller.testRun(context: context, args: ["uninstall"])
        
        // Should have selected app and action
        #expect(picker.selections.contains("Select an application to uninstall:"))
        #expect(picker.selections.contains("Choose an action:"))
        // Should not have asked for confirmation
        #expect(picker.permissions.isEmpty)
    }
    
    @Test("select items option uses multi-selection")
    func run_withSelectItemsOption_usesMultiSelection() throws {
        let shell = MockShell(results: [""])
        let fileSystem = MockFileSystem(
            directoryContents: [
                "/Applications": ["TestApp.app"],
                "/home/Library/Caches": ["com.TestApp.cache"]
            ]
        )
        let picker = MockPicker(
            permissionResponses: [
                "Confirm: Move 1 selected items to trash?": true
            ],
            selectionResponses: [
                "Select an application to uninstall:": 0,
                "Choose an action:": 1,  // Select "Select which items to remove"
                "Select items to remove:": 0  // Select first item in multi-selection
            ]
        )
        let context = MockContext(shell: shell, picker: picker, fileSystem: fileSystem)
        
        try Nnuninstaller.testRun(context: context, args: ["uninstall", "--dry-run"])
        
        // Verify all selections were made
        #expect(picker.selections.contains("Select an application to uninstall:"))
        #expect(picker.selections.contains("Choose an action:"))
        #expect(picker.selections.contains("Select items to remove:"))
    }
    
    @Test("handles no apps found")
    func run_withNoApps_handlesGracefully() throws {
        let shell = MockShell()
        let fileSystem = MockFileSystem(directoryContents: ["/Applications": []])
        let picker = MockPicker()
        let context = MockContext(shell: shell, picker: picker, fileSystem: fileSystem)
        
        try Nnuninstaller.testRun(context: context, args: ["uninstall"])
        
        // Should not have made any selections
        #expect(picker.selections.isEmpty)
    }
    
    @Test("handles app lister error")
    func run_withAppListerError_throwsFailure() throws {
        let shell = MockShell()
        let fileSystem = MockFileSystem(shouldThrowError: true)
        let picker = MockPicker()
        let context = MockContext(shell: shell, picker: picker, fileSystem: fileSystem)
        
        #expect(throws: ExitCode.failure) {
            try Nnuninstaller.testRun(context: context, args: ["uninstall"])
        }
    }
}