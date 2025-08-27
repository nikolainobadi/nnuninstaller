//
//  ListApps.swift
//  nnuninstaller
//
//  Created by Nikolai Nobadi on 8/27/25.
//

import ArgumentParser
import Foundation
import NnShellKit

struct ListApps: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list-apps",
        abstract: "List non-Apple applications in the Applications folder"
    )
    
    func run() throws {
        let shell = Nnuninstaller.makeShell()
        let fileSystem = Nnuninstaller.makeFileSystem()
        let appLister = AppLister(shell: shell, fileSystem: fileSystem)
        
        do {
            let apps = try appLister.listNonAppleApps()
            for app in apps {
                print(app.fullName)
            }
        } catch {
            print("Error reading Applications directory: \(error.localizedDescription)")
            throw ExitCode.failure
        }
    }
}