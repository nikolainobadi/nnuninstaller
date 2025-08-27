//
//  CheckAppFiles.swift
//  nnuninstaller
//
//  Created by Nikolai Nobadi on 8/27/25.
//

import ArgumentParser
import Foundation
import NnShellKit
import SwiftPicker

struct CheckAppFiles: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "check-app-files",
        abstract: "Select an app and check for associated files and folders"
    )
    
    func run() throws {
        let shell = Nnuninstaller.makeShell()
        let fileSystem = Nnuninstaller.makeFileSystem()
        let picker = Nnuninstaller.makePicker()
        let appLister = AppLister(shell: shell, fileSystem: fileSystem)
        let appFileChecker = AppFileChecker(fileSystem: fileSystem)
        
        do {
            let apps = try appLister.listNonAppleApps()
            
            guard !apps.isEmpty else {
                print("No non-Apple applications found in the Applications folder.")
                return
            }
            
            let selectedApp = try picker.requiredSingleSelection("Select an application to check for associated files:", items: apps)
            
            print("\nSearching for files associated with \(selectedApp.shortName)...")
            let associatedFiles = try appFileChecker.findAssociatedFiles(for: selectedApp)
            
            if associatedFiles.isEmpty {
                print("No associated files found for \(selectedApp.shortName).")
            } else {
                print("\nFound \(associatedFiles.count) associated file(s)/folder(s):")
                displayResults(associatedFiles)
            }
            
        } catch {
            print("Error: \(error.localizedDescription)")
            throw ExitCode.failure
        }
    }
}


// MARK: - Private Methods
private extension CheckAppFiles {
    func displayResults(_ files: [AppFileLocation]) {
        let groupedFiles = Dictionary(grouping: files, by: \.location)
        
        for (location, items) in groupedFiles.sorted(by: { $0.key < $1.key }) {
            print("\n📁 \(location):")
            for item in items.sorted(by: { $0.name < $1.name }) {
                print("  • \(item.name)")
                print("    \(item.path)")
            }
        }
    }
}