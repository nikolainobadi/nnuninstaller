//
//  AppListerTests.swift
//  nnuninstallerTests
//
//  Created by Nikolai Nobadi on 8/27/25.
//

import Testing
import NnShellKit
@testable import nnuninstaller

struct AppListerTests {
    @Test("returns filtered list with mixed Apple and non-Apple apps")
    func listNonAppleApps_withValidApps_returnsFilteredList() throws {
        let (sut, shell, fileSystem) = makeSUT(
            directoryContents: ["/Applications": ["VSCode.app", "Safari.app", "Steam.app"]],
            codesignResults: ["", "Apple Inc.", ""]
        )
        
        let result = try sut.listNonAppleApps()
        
        #expect(result.count == 2)
        #expect(result[0].fullName == "VSCode.app")
        #expect(result[1].fullName == "Steam.app")
        #expect(fileSystem.contentsOfDirectoryCalls == ["/Applications"])
        #expect(shell.executedCommands.count == 3)
    }
    
    @Test("returns empty array when Applications directory is empty")
    func listNonAppleApps_withNoApps_returnsEmptyArray() throws {
        let (sut, _, fileSystem) = makeSUT(
            directoryContents: ["/Applications": []]
        )
        
        let result = try sut.listNonAppleApps()
        
        #expect(result.isEmpty)
        #expect(fileSystem.contentsOfDirectoryCalls == ["/Applications"])
    }
    
    @Test("returns empty array when only Apple apps are present")
    func listNonAppleApps_withOnlyAppleApps_returnsEmptyArray() throws {
        let (sut, shell, _) = makeSUT(
            directoryContents: ["/Applications": ["Safari.app", "Mail.app"]],
            codesignResults: ["Apple Inc.", "Apple Inc."]
        )
        
        let result = try sut.listNonAppleApps()
        
        #expect(result.isEmpty)
        #expect(shell.executedCommands.count == 2)
    }
    
    @Test("returns all apps when only non-Apple apps are present")
    func listNonAppleApps_withOnlyNonAppleApps_returnsAllApps() throws {
        let (sut, shell, _) = makeSUT(
            directoryContents: ["/Applications": ["VSCode.app", "Steam.app", "Chrome.app"]],
            codesignResults: ["", "", ""]
        )
        
        let result = try sut.listNonAppleApps()
        
        #expect(result.count == 3)
        #expect(result[0].fullName == "VSCode.app")
        #expect(result[1].fullName == "Steam.app")
        #expect(result[2].fullName == "Chrome.app")
        #expect(shell.executedCommands.count == 3)
    }
    
    @Test("treats apps as non-Apple when codesign command fails")
    func listNonAppleApps_withCodesignFailure_treatAsNonApple() throws {
        let (sut, shell, _) = makeSUT(
            directoryContents: ["/Applications": ["BrokenApp.app", "ValidApp.app"]],
            codesignResults: [],
            shellShouldThrowError: true
        )
        
        let result = try sut.listNonAppleApps()
        
        #expect(result.count == 2)
        #expect(result[0].fullName == "BrokenApp.app")
        #expect(result[1].fullName == "ValidApp.app")
        #expect(shell.executedCommands.count == 2)
    }
    
    @Test("uses provided custom applications path")
    func listNonAppleApps_withCustomPath_usesProvidedPath() throws {
        let customPath = "/System/Applications"
        let (sut, _, fileSystem) = makeSUT(
            applicationsPath: customPath,
            directoryContents: [customPath: ["Calculator.app"]],
            codesignResults: ["Apple Inc."]
        )
        
        let result = try sut.listNonAppleApps()
        
        #expect(result.isEmpty)
        #expect(fileSystem.contentsOfDirectoryCalls == [customPath])
    }
    
    @Test("throws error when file system fails to read directory")
    func listNonAppleApps_withFileSystemError_throwsError() throws {
        let (sut, _, _) = makeSUT(
            fileSystemShouldThrowError: true
        )
        
        #expect(throws: (any Error).self) {
            try sut.listNonAppleApps()
        }
    }
    
    @Test("filters out files without .app extension")
    func listNonAppleApps_withNonAppFiles_filtersOutNonAppFiles() throws {
        let (sut, shell, _) = makeSUT(
            directoryContents: ["/Applications": ["VSCode.app", "README.txt", "script.sh", "Steam.app"]],
            codesignResults: ["", ""]
        )
        
        let result = try sut.listNonAppleApps()
        
        #expect(result.count == 2)
        #expect(result[0].fullName == "VSCode.app")
        #expect(result[1].fullName == "Steam.app")
        #expect(shell.executedCommands.count == 2)
    }
    
    @Test("detects Apple signature regardless of case")
    func listNonAppleApps_withMixedCaseAppleSignature_detectsApple() throws {
        let (sut, _, _) = makeSUT(
            directoryContents: ["/Applications": ["Safari.app", "Mail.app", "TextEdit.app"]],
            codesignResults: ["apple inc.", "APPLE INC.", "Apple Inc"]
        )
        
        let result = try sut.listNonAppleApps()
        
        #expect(result.isEmpty)
    }
    
    @Test("treats apps as non-Apple when codesign returns empty output")
    func listNonAppleApps_withEmptyCodesignOutput_treatAsNonApple() throws {
        let (sut, _, _) = makeSUT(
            directoryContents: ["/Applications": ["UnsignedApp.app"]],
            codesignResults: [""]
        )
        
        let result = try sut.listNonAppleApps()
        
        #expect(result.count == 1)
        #expect(result[0].fullName == "UnsignedApp.app")
    }
}

// MARK: - SUT
private extension AppListerTests {
    func makeSUT(
        applicationsPath: String = "/Applications",
        directoryContents: [String: [String]] = [:],
        codesignResults: [String] = [],
        shellShouldThrowError: Bool = false,
        fileSystemShouldThrowError: Bool = false
    ) -> (sut: AppLister, shell: MockShell, fileSystem: MockFileSystem) {
        let shell = MockShell(
            results: codesignResults,
            shouldThrowError: shellShouldThrowError
        )
        let fileSystem = MockFileSystem(
            directoryContents: directoryContents,
            shouldThrowError: fileSystemShouldThrowError
        )
        let sut = AppLister(
            shell: shell,
            fileSystem: fileSystem,
            applicationsPath: applicationsPath
        )
        
        return (sut, shell, fileSystem)
    }
}