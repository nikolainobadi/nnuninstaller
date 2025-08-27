//
//  AppFileCheckerTests.swift
//  nnuninstallerTests
//
//  Created by Nikolai Nobadi on 8/27/25.
//

import Testing
@testable import nnuninstaller

@MainActor
struct AppFileCheckerTests {
    @Test("finds matching files in all search locations")
    func findAssociatedFiles_withMatchingFiles_returnsAllMatches() throws {
        let app = AppInfo(path: "/Applications/Discord.app")
        let homeDirectory = "/Users/test"
        let fileSystem = MockFileSystem(directoryContents: [
            "\(homeDirectory)/Library/Application Support": ["Discord", "SomeOtherApp"],
            "\(homeDirectory)/Library/Caches": ["com.discord.Discord", "com.other.app"],
            "\(homeDirectory)/Library/Preferences": ["com.discord.plist", "discord-settings.plist"],
            "\(homeDirectory)/Library/Logs": ["Discord.log"],
            "\(homeDirectory)/Library/Containers": ["com.discord.Discord"],
            "\(homeDirectory)/Library/Cookies": []
        ])
        
        let checker = AppFileChecker(fileSystem: fileSystem, homeDirectory: homeDirectory)
        let results = try checker.findAssociatedFiles(for: app)
        
        #expect(results.count == 6)
        #expect(results.contains { $0.name == "Discord" && $0.location == "Application Support" })
        #expect(results.contains { $0.name == "com.discord.Discord" && $0.location == "Caches" })
        #expect(results.contains { $0.name == "com.discord.plist" && $0.location == "Preferences" })
        #expect(results.contains { $0.name == "discord-settings.plist" && $0.location == "Preferences" })
        #expect(results.contains { $0.name == "Discord.log" && $0.location == "Logs" })
        #expect(results.contains { $0.name == "com.discord.Discord" && $0.location == "Containers" })
    }
    
    @Test("returns empty array when no matching files found")
    func findAssociatedFiles_withNoMatches_returnsEmptyArray() throws {
        let app = AppInfo(path: "/Applications/Discord.app")
        let homeDirectory = "/Users/test"
        let fileSystem = MockFileSystem(directoryContents: [
            "\(homeDirectory)/Library/Application Support": ["SomeOtherApp", "AnotherApp"],
            "\(homeDirectory)/Library/Caches": ["com.other.app"],
            "\(homeDirectory)/Library/Preferences": ["com.other.plist"],
            "\(homeDirectory)/Library/Logs": [],
            "\(homeDirectory)/Library/Containers": [],
            "\(homeDirectory)/Library/Cookies": []
        ])
        
        let checker = AppFileChecker(fileSystem: fileSystem, homeDirectory: homeDirectory)
        let results = try checker.findAssociatedFiles(for: app)
        
        #expect(results.isEmpty)
    }
    
    @Test("handles missing directories gracefully")
    func findAssociatedFiles_withMissingDirectories_handlesGracefully() throws {
        let app = AppInfo(path: "/Applications/Discord.app")
        let homeDirectory = "/Users/test"
        let fileSystem = MockFileSystem(directoryContents: [
            "\(homeDirectory)/Library/Application Support": ["Discord"]
            // Other directories missing
        ])
        
        let checker = AppFileChecker(fileSystem: fileSystem, homeDirectory: homeDirectory)
        let results = try checker.findAssociatedFiles(for: app)
        
        #expect(results.count == 1)
        #expect(results.first?.name == "Discord")
        #expect(results.first?.location == "Application Support")
    }
    
    @Test("matches files case insensitively")
    func findAssociatedFiles_withCaseVariations_matchesCaseInsensitively() throws {
        let app = AppInfo(path: "/Applications/MyApp.app")
        let homeDirectory = "/Users/test"
        let fileSystem = MockFileSystem(directoryContents: [
            "\(homeDirectory)/Library/Application Support": ["myapp", "MYAPP", "MyApp", "MyApp-Data"]
        ])
        
        let checker = AppFileChecker(fileSystem: fileSystem, homeDirectory: homeDirectory)
        let results = try checker.findAssociatedFiles(for: app)
        
        #expect(results.count == 4)
        #expect(results.allSatisfy { $0.location == "Application Support" })
        let names = results.map(\.name).sorted()
        #expect(names == ["MYAPP", "MyApp", "MyApp-Data", "myapp"])
    }
    
    @Test("creates correct AppFileLocation objects")
    func findAssociatedFiles_createsCorrectAppFileLocation() throws {
        let app = AppInfo(path: "/Applications/TestApp.app")
        let homeDirectory = "/Users/test"
        let fileSystem = MockFileSystem(directoryContents: [
            "\(homeDirectory)/Library/Caches": ["com.TestApp.cache"]
        ])
        
        let checker = AppFileChecker(fileSystem: fileSystem, homeDirectory: homeDirectory)
        let results = try checker.findAssociatedFiles(for: app)
        
        #expect(results.count == 1)
        let result = results.first!
        #expect(result.name == "com.TestApp.cache")
        #expect(result.location == "Caches")
        #expect(result.appName == "TestApp")
        #expect(result.path == "\(homeDirectory)/Library/Caches/com.TestApp.cache")
    }
    
    @Test("handles file system errors gracefully")
    func findAssociatedFiles_withFileSystemError_handlesGracefully() throws {
        let app = AppInfo(path: "/Applications/TestApp.app")
        let homeDirectory = "/Users/test"
        let fileSystem = MockFileSystem(shouldThrowError: true)
        
        let checker = AppFileChecker(fileSystem: fileSystem, homeDirectory: homeDirectory)
        let results = try checker.findAssociatedFiles(for: app)
        
        // Should handle errors gracefully and return empty array
        #expect(results.isEmpty)
    }
}