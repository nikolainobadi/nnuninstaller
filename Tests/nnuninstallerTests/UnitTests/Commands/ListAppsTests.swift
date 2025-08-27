//
//  ListAppsTests.swift
//  nnuninstallerTests
//
//  Created by Nikolai Nobadi on 8/27/25.
//

import Testing
import NnShellKit
import ArgumentParser
@testable import nnuninstaller

@MainActor
struct ListAppsTests {
    @Test("successfully executes with valid apps and calls expected dependencies")
    func run_withValidApps_callsExpectedDependencies() throws {
        let shell = MockShell(results: ["", "Apple Inc.", ""])
        let fileSystem = MockFileSystem(
            directoryContents: ["/Applications": ["VSCode.app", "Safari.app", "Steam.app"]]
        )
        let context = MockContext(shell: shell, fileSystem: fileSystem)
        
        // Test that command execution doesn't throw
        try runCommand(context: context)
        
        #expect(fileSystem.contentsOfDirectoryCalls == ["/Applications"])
        #expect(shell.executedCommands.count == 3)
        #expect(shell.executedCommands.allSatisfy { $0.contains("codesign") })
    }
    
    @Test("executes successfully when no apps are found")
    func run_withNoApps_executesSuccessfully() throws {
        let shell = MockShell()
        let fileSystem = MockFileSystem(directoryContents: ["/Applications": []])
        let context = MockContext(shell: shell, fileSystem: fileSystem)
        
        try runCommand(context: context)
        
        #expect(fileSystem.contentsOfDirectoryCalls == ["/Applications"])
        #expect(shell.executedCommands.isEmpty)
    }
    
    @Test("throws failure when file system error occurs")
    func run_withFileSystemError_throwsFailure() throws {
        let shell = MockShell()
        let fileSystem = MockFileSystem(shouldThrowError: true)
        let context = MockContext(shell: shell, fileSystem: fileSystem)
        
        #expect(throws: ExitCode.failure) {
            try runCommand(context: context)
        }
        
        #expect(fileSystem.contentsOfDirectoryCalls == ["/Applications"])
    }
    
    @Test("calls codesign for each app when mixed apps are present")
    func run_withMixedApps_callsCodesignForEachApp() throws {
        let shell = MockShell(results: ["", "Apple Inc.", "", "Apple Inc.", ""])
        let fileSystem = MockFileSystem(
            directoryContents: ["/Applications": ["Chrome.app", "Safari.app", "VSCode.app", "Mail.app", "Steam.app"]]
        )
        let context = MockContext(shell: shell, fileSystem: fileSystem)
        
        try runCommand(context: context)
        
        #expect(shell.executedCommands.count == 5)
        #expect(shell.executedCommands.allSatisfy { $0.contains("codesign") })
        #expect(shell.executedCommands.contains { $0.contains("Chrome.app") })
        #expect(shell.executedCommands.contains { $0.contains("Safari.app") })
        #expect(shell.executedCommands.contains { $0.contains("VSCode.app") })
        #expect(shell.executedCommands.contains { $0.contains("Mail.app") })
        #expect(shell.executedCommands.contains { $0.contains("Steam.app") })
    }
    
    @Test("uses default Applications directory path")
    func run_usesDefaultApplicationsDirectory() throws {
        let shell = MockShell(results: [""])
        let fileSystem = MockFileSystem(
            directoryContents: ["/Applications": ["TestApp.app"]]
        )
        let context = MockContext(shell: shell, fileSystem: fileSystem)
        
        try runCommand(context: context)
        
        #expect(fileSystem.contentsOfDirectoryCalls.contains("/Applications"))
    }
}


// MARK: - Run
private extension ListAppsTests {
    func runCommand(context: MockContext) throws {
        try Nnuninstaller.testRun(context: context, args: ["list-apps"])
    }
}
