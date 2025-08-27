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
        let applicationsPath = "/Applications"
        
        do {
            let apps = try FileManager.default.contentsOfDirectory(atPath: applicationsPath)
                .filter { $0.hasSuffix(".app") }
                .map { "\(applicationsPath)/\($0)" }
            
            for appPath in apps {
                if !isAppleSigned(appPath: appPath, shell: shell) {
                    let appName = URL(fileURLWithPath: appPath).lastPathComponent
                    print(appName)
                }
            }
        } catch {
            print("Error reading Applications directory: \(error.localizedDescription)")
            throw ExitCode.failure
        }
    }
    
    private func isAppleSigned(appPath: String, shell: any Shell) -> Bool {
        do {
            let result = try shell.bash("codesign -dv \"\(appPath)\" 2>&1")
            return result.contains("Apple")
        } catch {
            return false
        }
    }
}