//
//  CheckAppFilesTests.swift
//  nnuninstallerTests
//
//  Created by Nikolai Nobadi on 8/27/25.
//

import Testing
import NnShellKit
import ArgumentParser
@testable import nnuninstaller

@MainActor
struct CheckAppFilesTests {
    @Test("successfully executes with valid apps and finds associated files")
    func run_withValidAppsAndAssociatedFiles_executesSuccessfully() throws {
        let shell = MockShell(results: ["", "Apple Inc.", ""])
        let fileSystem = MockFileSystem(
            directoryContents: [
                "/Applications": ["Discord.app", "Safari.app", "Steam.app"],
                "/Users/test/Library/Application Support": ["Discord", "Steam"],
                "/Users/test/Library/Caches": ["com.discord.Discord"],
                "/Users/test/Library/Logs": ["Discord.log"]
            ]
        )
        let picker = MockPicker(selectionResponses: ["Select an application to check for associated files:": 0]) // Select Discord
        let context = MockContext(shell: shell, picker: picker, fileSystem: fileSystem)
        
        try runCommand(context: context)
        
        #expect(fileSystem.contentsOfDirectoryCalls.contains("/Applications"))
        #expect(picker.selections.contains("Select an application to check for associated files:"))
        #expect(shell.executedCommands.count == 3) // codesign checks for 3 apps
    }
    
    @Test("handles no apps found gracefully")
    func run_withNoApps_handlesGracefully() throws {
        let shell = MockShell()
        let fileSystem = MockFileSystem(directoryContents: ["/Applications": []])
        let picker = MockPicker()
        let context = MockContext(shell: shell, picker: picker, fileSystem: fileSystem)
        
        try runCommand(context: context)
        
        #expect(fileSystem.contentsOfDirectoryCalls == ["/Applications"])
        #expect(picker.selections.isEmpty) // No selection made since no apps found
        #expect(shell.executedCommands.isEmpty) // No codesign calls since no apps
    }
    
    @Test("handles app lister error")
    func run_withAppListerError_throwsFailure() throws {
        let shell = MockShell()
        let fileSystem = MockFileSystem(shouldThrowError: true)
        let picker = MockPicker()
        let context = MockContext(shell: shell, picker: picker, fileSystem: fileSystem)
        
        #expect(throws: ExitCode.failure) {
            try runCommand(context: context)
        }
        
        #expect(fileSystem.contentsOfDirectoryCalls == ["/Applications"])
    }
    
    @Test("handles picker cancellation")
    func run_withPickerCancellation_throwsFailure() throws {
        let shell = MockShell(results: [""])
        let fileSystem = MockFileSystem(
            directoryContents: ["/Applications": ["TestApp.app"]]
        )
        let picker = MockPicker() // No selection responses, will throw error
        let context = MockContext(shell: shell, picker: picker, fileSystem: fileSystem)
        
        #expect(throws: ExitCode.failure) {
            try runCommand(context: context)
        }
        
        #expect(picker.selections.contains("Select an application to check for associated files:"))
    }
    
    @Test("successfully handles app with no associated files")
    func run_withAppHavingNoAssociatedFiles_executesSuccessfully() throws {
        let shell = MockShell(results: [""])
        let fileSystem = MockFileSystem(
            directoryContents: [
                "/Applications": ["TestApp.app"],
                // No files in Library directories
            ]
        )
        let picker = MockPicker(selectionResponses: ["Select an application to check for associated files:": 0])
        let context = MockContext(shell: shell, picker: picker, fileSystem: fileSystem)
        
        try runCommand(context: context)
        
        #expect(picker.selections.contains("Select an application to check for associated files:"))
        // Should complete successfully even with no associated files found
    }
    
    @Test("correctly filters non-Apple apps before selection")
    func run_filtersNonAppleApps() throws {
        let shell = MockShell(results: ["Apple Inc.", "", "Apple Inc."]) // Safari and Mail are Apple signed
        let fileSystem = MockFileSystem(
            directoryContents: [
                "/Applications": ["Safari.app", "Discord.app", "Mail.app"]
            ]
        )
        let picker = MockPicker(selectionResponses: ["Select an application to check for associated files:": 0]) // Select first non-Apple app (Discord)
        let context = MockContext(shell: shell, picker: picker, fileSystem: fileSystem)
        
        try runCommand(context: context)
        
        #expect(shell.executedCommands.count == 3) // Checked all 3 apps
        #expect(picker.selections.contains("Select an application to check for associated files:")) // Made selection from filtered list
    }
}


// MARK: - Run
private extension CheckAppFilesTests {
    func runCommand(context: MockContext) throws {
        try Nnuninstaller.testRun(context: context, args: ["check-apps"])
    }
}
