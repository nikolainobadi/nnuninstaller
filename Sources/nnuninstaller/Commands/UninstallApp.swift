//
//  UninstallApp.swift
//  nnuninstaller
//
//  Created by Nikolai Nobadi on 8/27/25.
//

import ArgumentParser
import Foundation
import NnShellKit
import SwiftPicker

struct UninstallApp: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "uninstall",
        abstract: "Uninstall an app and remove its associated files"
    )
    
    @Flag(name: .shortAndLong, help: "Dry run - show what would be deleted without deleting")
    var dryRun = false
    
    @Flag(name: .long, help: "Skip confirmation prompts (dangerous!)")
    var force = false
    
    @Flag(name: .long, help: "Create a log of deleted items")
    var log = false
    
    private var uninstallService: UninstallServiceProtocol {
        UninstallService()
    }
    
    private var displayFormatter: UninstallDisplayFormatterProtocol {
        UninstallDisplayFormatter()
    }
    
    func run() throws {
        let shell = Nnuninstaller.makeShell()
        let fileSystem = Nnuninstaller.makeFileSystem()
        let picker = Nnuninstaller.makePicker()
        let appLister = AppLister(shell: shell, fileSystem: fileSystem)
        let appFileChecker = AppFileChecker(fileSystem: fileSystem)
        
        do {
            // Step 1: Select app
            let apps = try appLister.listNonAppleApps()
            
            guard !apps.isEmpty else {
                print("No non-Apple applications found in the Applications folder.")
                return
            }
            
            let selectedApp = try picker.requiredSingleSelection("Select an application to uninstall:", items: apps)
            
            // Step 2: Find associated files
            print("\nSearching for files associated with \(selectedApp.shortName)...")
            var associatedFiles = try appFileChecker.findAssociatedFiles(for: selectedApp)
            
            // Calculate sizes for all files
            let sizeCalculator = FileSizeCalculator()
            for index in associatedFiles.indices {
                associatedFiles[index].size = sizeCalculator.calculateSize(at: associatedFiles[index].path)
            }
            
            // Calculate total size including app
            let appSize = sizeCalculator.calculateSize(at: selectedApp.path)
            let totalSize = appSize + associatedFiles.reduce(0) { $0 + ($1.size ?? 0) }
            let formattedTotalSize = sizeCalculator.formatSize(totalSize)
            
            // Step 3: Display found items
            displayFormatter.displayFoundItems(app: selectedApp, appSize: appSize, files: associatedFiles, totalSize: formattedTotalSize)
            
            // Step 4: Perform uninstall using service
            let options = UninstallOptions(dryRun: dryRun, force: force, createLog: log)
            let result = try uninstallService.performUninstall(
                app: selectedApp,
                associatedFiles: associatedFiles,
                options: options,
                picker: picker
            )
            
            // Step 5: Handle result
            if result.cancelled {
                print("\nUninstall cancelled. No changes were made.")
            } else if let uninstallerResult = result.uninstallerResult {
                displayFormatter.displayResult(uninstallerResult, appName: selectedApp.shortName, dryRun: dryRun)
            }
            
        } catch {
            print("Error: \(error.localizedDescription)")
            throw ExitCode.failure
        }
    }
}

extension String {
    func pluralized(for count: Int) -> String {
        count == 1 ? self : self + "s"
    }
}
