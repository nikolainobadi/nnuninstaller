//
//  AppLister.swift
//  nnuninstaller
//
//  Created by Nikolai Nobadi on 8/27/25.
//

import Foundation
import NnShellKit

struct AppLister {
    private let shell: any Shell
    private let fileSystem: any FileSystem
    private let applicationsPath: String
    
    init(shell: any Shell, fileSystem: any FileSystem = DefaultFileSystem(), applicationsPath: String = "/Applications") {
        self.shell = shell
        self.fileSystem = fileSystem
        self.applicationsPath = applicationsPath
    }
}


// MARK: - Actions
extension AppLister {
    func listNonAppleApps() throws -> [AppInfo] {
        let apps = try fileSystem.contentsOfDirectory(atPath: applicationsPath)
            .filter { $0.hasSuffix(".app") }
            .map { "\(applicationsPath)/\($0)" }
        
        var nonAppleApps: [AppInfo] = []
        
        for appPath in apps {
            if !isAppleSigned(appPath: appPath) {
                nonAppleApps.append(AppInfo(path: appPath))
            }
        }
        
        return nonAppleApps
    }
}


// MARK: - Private Methods
private extension AppLister {
    func isAppleSigned(appPath: String) -> Bool {
        do {
            let result = try shell.bash("codesign -dv \"\(appPath)\" 2>&1")
            return result.lowercased().contains("apple")
        } catch {
            return false
        }
    }
}
