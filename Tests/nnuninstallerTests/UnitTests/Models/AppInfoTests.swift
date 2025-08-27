//
//  AppInfoTests.swift
//  nnuninstallerTests
//
//  Created by Nikolai Nobadi on 8/27/25.
//

import Testing
@testable import nnuninstaller

struct AppInfoTests {
    @Test("sets correct full and short names for app with .app extension")
    func init_withAppExtension_setsCorrectNames() throws {
        let appPath = "/Applications/Visual Studio Code.app"
        
        let appInfo = AppInfo(path: appPath)
        
        #expect(appInfo.path == appPath)
        #expect(appInfo.fullName == "Visual Studio Code.app")
        #expect(appInfo.shortName == "Visual Studio Code")
    }
    
    @Test("handles app name without .app extension gracefully")
    func init_withoutAppExtension_handlesGracefully() throws {
        let appPath = "/Applications/SomeFile"
        
        let appInfo = AppInfo(path: appPath)
        
        #expect(appInfo.path == appPath)
        #expect(appInfo.fullName == "SomeFile")
        #expect(appInfo.shortName == "SomeFile")
    }
    
    @Test("extracts app name correctly from complex file path")
    func init_withComplexPath_extractsNameCorrectly() throws {
        let appPath = "/System/Applications/Utilities/Terminal.app"
        
        let appInfo = AppInfo(path: appPath)
        
        #expect(appInfo.path == appPath)
        #expect(appInfo.fullName == "Terminal.app")
        #expect(appInfo.shortName == "Terminal")
    }
    
    @Test("handles app with multiple dots in name correctly")
    func init_withMultipleDotsInName_handlesCorrectly() throws {
        let appPath = "/Applications/DB Browser for SQLite.app"
        
        let appInfo = AppInfo(path: appPath)
        
        #expect(appInfo.path == appPath)
        #expect(appInfo.fullName == "DB Browser for SQLite.app")
        #expect(appInfo.shortName == "DB Browser for SQLite")
    }
    
    @Test("handles edge case with .app in middle of filename")
    func init_withAppInMiddleOfFilename_handlesCorrectly() throws {
        let appPath = "/Applications/MyApp.app.backup"
        
        let appInfo = AppInfo(path: appPath)
        
        #expect(appInfo.path == appPath)
        #expect(appInfo.fullName == "MyApp.app.backup")
        #expect(appInfo.shortName == "MyApp.app.backup")
    }
    
    @Test("handles empty path gracefully")
    func init_withEmptyPath_handlesGracefully() throws {
        let appPath = ""
        
        let appInfo = AppInfo(path: appPath)
        
        #expect(appInfo.path == appPath)
        #expect(appInfo.fullName == "")
        #expect(appInfo.shortName == "")
    }
    
    @Test("handles path with only filename")
    func init_withOnlyFilename_handlesCorrectly() throws {
        let appPath = "TextEdit.app"
        
        let appInfo = AppInfo(path: appPath)
        
        #expect(appInfo.path == appPath)
        #expect(appInfo.fullName == "TextEdit.app")
        #expect(appInfo.shortName == "TextEdit")
    }
}