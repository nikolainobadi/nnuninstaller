//
//  AppFileChecker.swift
//  nnuninstaller
//
//  Created by Nikolai Nobadi on 8/27/25.
//

import Foundation

struct AppFileChecker {
    private let fileSystem: any FileSystem
    private let homeDirectory: String
    
    init(fileSystem: any FileSystem = DefaultFileSystem(), homeDirectory: String = NSHomeDirectory()) {
        self.fileSystem = fileSystem
        self.homeDirectory = homeDirectory
    }
}


// MARK: - Actions
extension AppFileChecker {
    func findAssociatedFiles(for app: AppInfo) throws -> [AppFileLocation] {
        let searchLocations = getSearchLocations()
        var foundFiles: [AppFileLocation] = []
        
        for location in searchLocations {
            let files = try findFiles(for: app, in: location)
            foundFiles.append(contentsOf: files)
        }
        
        return foundFiles
    }
}


// MARK: - Private Methods
private extension AppFileChecker {
    func getSearchLocations() -> [SearchLocation] {
        return [
            SearchLocation(path: "\(homeDirectory)/Library/Application Support", name: "Application Support"),
            SearchLocation(path: "\(homeDirectory)/Library/Caches", name: "Caches"),
            SearchLocation(path: "\(homeDirectory)/Library/Logs", name: "Logs"),
            SearchLocation(path: "\(homeDirectory)/Library/Preferences", name: "Preferences"),
            SearchLocation(path: "\(homeDirectory)/Library/Containers", name: "Containers"),
            SearchLocation(path: "\(homeDirectory)/Library/Cookies", name: "Cookies")
        ]
    }
    
    func findFiles(for app: AppInfo, in location: SearchLocation) throws -> [AppFileLocation] {
        do {
            let contents = try fileSystem.contentsOfDirectory(atPath: location.path)
            let matchingItems = contents.filter { item in
                let lowercasedItem = item.lowercased()
                let lowercasedAppName = app.shortName.lowercased()
                return lowercasedItem.contains(lowercasedAppName)
            }
            
            return matchingItems.map { item in
                let fullPath = "\(location.path)/\(item)"
                return AppFileLocation(
                    path: fullPath,
                    name: item,
                    location: location.name,
                    appName: app.shortName
                )
            }
        } catch {
            // Directory doesn't exist or can't be read - return empty array
            return []
        }
    }
    
    func directoryExists(at path: String) -> Bool {
        var isDirectory: ObjCBool = false
        return FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory) && isDirectory.boolValue
    }
}


// MARK: - Supporting Types
struct SearchLocation {
    let path: String
    let name: String
}

struct AppFileLocation {
    let path: String
    let name: String
    let location: String
    let appName: String
}