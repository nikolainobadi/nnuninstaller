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
    
    @Test("displayName returns shortName for picker display")
    func displayName_returnsShortName() throws {
        let appInfo = AppInfo(path: "/Applications/Discord.app")
        
        #expect(appInfo.displayName == "Discord")
    }
    
    @Test("displayName handles empty path gracefully")
    func displayName_withEmptyPath_handlesGracefully() throws {
        let appInfo = AppInfo(path: "")
        
        #expect(appInfo.displayName == "")
    }
    
    @Test("shortName removes underscores and uses first component")
    func init_withUnderscoresInName_usesFirstComponent() throws {
        let appPath = "/Applications/CleanMyMac_5_MAS.app"
        
        let appInfo = AppInfo(path: appPath)
        
        #expect(appInfo.path == appPath)
        #expect(appInfo.fullName == "CleanMyMac_5_MAS.app")
        #expect(appInfo.shortName == "CleanMyMac")
        #expect(appInfo.displayName == "CleanMyMac")
    }
    
    @Test("shortName handles multiple underscores correctly")
    func init_withMultipleUnderscores_usesFirstComponent() throws {
        let appPath = "/Applications/My_App_Name_Version_2.app"
        
        let appInfo = AppInfo(path: appPath)
        
        #expect(appInfo.path == appPath)
        #expect(appInfo.fullName == "My_App_Name_Version_2.app")
        #expect(appInfo.shortName == "My")
        #expect(appInfo.displayName == "My")
    }
    
    @Test("shortName handles no underscores unchanged")
    func init_withNoUnderscores_remainsUnchanged() throws {
        let appPath = "/Applications/Safari.app"
        
        let appInfo = AppInfo(path: appPath)
        
        #expect(appInfo.path == appPath)
        #expect(appInfo.fullName == "Safari.app")
        #expect(appInfo.shortName == "Safari")
        #expect(appInfo.displayName == "Safari")
    }
    
    @Test("shortName handles underscore without app extension")
    func init_withUnderscoreNoAppExtension_usesFirstComponent() throws {
        let appPath = "/Applications/Some_File_Name"
        
        let appInfo = AppInfo(path: appPath)
        
        #expect(appInfo.path == appPath)
        #expect(appInfo.fullName == "Some_File_Name")
        #expect(appInfo.shortName == "Some")
        #expect(appInfo.displayName == "Some")
    }
}