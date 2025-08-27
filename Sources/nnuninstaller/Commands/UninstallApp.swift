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
            displayFoundItems(app: selectedApp, appSize: appSize, files: associatedFiles, totalSize: formattedTotalSize)
            
            // Step 4: Get user choice (unless force flag is used)
            let action: UninstallAction
            if force {
                action = .removeAll
                print("\n⚠️  Force flag enabled - removing all items without confirmation")
            } else {
                action = try getUserChoice(picker: picker, fileCount: associatedFiles.count)
            }
            
            // Step 5: Execute based on choice
            switch action {
            case .removeAll:
                try handleRemoveAll(app: selectedApp, files: associatedFiles, picker: picker)
            case .selectItems:
                try handleSelectItems(app: selectedApp, files: associatedFiles, picker: picker)
            case .cancel:
                print("\nUninstall cancelled. No changes were made.")
            }
            
        } catch {
            print("Error: \(error.localizedDescription)")
            throw ExitCode.failure
        }
    }
}


// MARK: - Private Types
private enum UninstallAction {
    case removeAll
    case selectItems
    case cancel
}


// MARK: - Private Methods
private extension UninstallApp {
    func displayFoundItems(app: AppInfo, appSize: Int64, files: [AppFileLocation], totalSize: String) {
        let sizeCalculator = FileSizeCalculator()
        
        if files.isEmpty {
            print("\n📦 Application:")
            print("  • \(app.fullName) (\(sizeCalculator.formatSize(appSize)))")
            print("    \(app.path)")
            print("\nNo additional files found.")
            print("\nTotal size: \(totalSize)")
        } else {
            print("\nFound \(files.count + 1) items associated with \(app.shortName):")
            
            print("\n📦 Application:")
            print("  • \(app.fullName) (\(sizeCalculator.formatSize(appSize)))")
            print("    \(app.path)")
            
            let groupedFiles = Dictionary(grouping: files, by: \.location)
            for (location, items) in groupedFiles.sorted(by: { $0.key < $1.key }) {
                print("\n📁 \(location):")
                for item in items.sorted(by: { $0.name < $1.name }) {
                    let sizeStr = item.formattedSize.isEmpty ? "" : " (\(item.formattedSize))"
                    print("  • \(item.name)\(sizeStr)")
                    print("    \(item.path)")
                }
            }
            
            print("\nTotal size: ~\(totalSize)")
        }
    }
    
    func getUserChoice(picker: any CommandLinePicker, fileCount: Int) throws -> UninstallAction {
        let options = [
            "Remove all items",
            "Select which items to remove",
            "Cancel"
        ]
        
        if fileCount == 1 {
            try picker.requiredPermission("Only 1 file found. Would you like to move it to the trash?")
            
            return .removeAll
        }
        
        let selected = try picker.requiredSingleSelection("\(fileCount) additional files found. What would you like to do?", items: options)
        
        switch selected {
        case "Remove all items":
            return .removeAll
        case "Select which items to remove":
            return .selectItems
        case "Cancel":
            return .cancel
        default:
            return .cancel
        }
    }
    
    func handleRemoveAll(app: AppInfo, files: [AppFileLocation], picker: any CommandLinePicker) throws {
        if !force {
            let itemCount = files.count + 1 // +1 for the app itself
            let confirmPrompt = "⚠️  Confirmation: Move all \(itemCount) items to trash?"
            
            guard picker.getPermission(prompt: confirmPrompt) else {
                print("\nUninstall cancelled.")
                return
            }
        }
        
        print("\n\(dryRun ? "[DRY RUN] Would move" : "Moving") items to trash...")
        
        let uninstaller = AppUninstaller(dryRun: dryRun, createLog: log)
        let result = try uninstaller.uninstallApp(app, withFiles: files)
        
        displayResult(result, appName: app.shortName)
    }
    
    func handleSelectItems(app: AppInfo, files: [AppFileLocation], picker: any CommandLinePicker) throws {
        // Create selectable items including the app
        let appItem = AppFileLocation(
            path: app.path,
            name: app.fullName,
            location: "Applications",
            appName: app.shortName,
            size: FileSizeCalculator().calculateSize(at: app.path)
        )
        
        let allItems = [appItem] + files
        
        print("\nSelect items to remove (use arrow keys and space to toggle, enter to confirm):")
        let selectedItems = picker.multiSelection(title: "Select items to remove:", items: allItems)
        
        guard !selectedItems.isEmpty else {
            print("\nNo items selected. Uninstall cancelled.")
            return
        }
        
        // Calculate selected size
        let sizeCalculator = FileSizeCalculator()
        let selectedSize = selectedItems.reduce(0) { $0 + ($1.size ?? 0) }
        let formattedSize = sizeCalculator.formatSize(selectedSize)
        
        print("\nSelected \(selectedItems.count) of \(allItems.count) items (~\(formattedSize))")
        
        if !force {
            let confirmPrompt = "Confirm: Move \(selectedItems.count) selected items to trash?"
            guard picker.getPermission(prompt: confirmPrompt) else {
                print("\nUninstall cancelled.")
                return
            }
        }
        
        print("\n\(dryRun ? "[DRY RUN] Would move" : "Moving") selected items to trash...")
        
        // Separate app from other files
        let selectedApp = selectedItems.first { $0.path == app.path } != nil ? app : nil
        let selectedFiles = selectedItems.filter { $0.path != app.path }
        
        if let selectedApp = selectedApp {
            // If app is selected, uninstall it with selected files
            let uninstaller = AppUninstaller(dryRun: dryRun, createLog: log)
            let result = try uninstaller.uninstallApp(selectedApp, withFiles: selectedFiles)
            displayResult(result, appName: app.shortName)
        } else {
            // If app is not selected, only remove selected files
            let uninstaller = AppUninstaller(dryRun: dryRun, createLog: log)
            var succeededItems: [String] = []
            var failedItems: [(path: String, error: Error)] = []
            
            for file in selectedFiles {
                do {
                    try uninstaller.moveToTrash(path: file.path)
                    succeededItems.append(file.name)
                    if !dryRun {
                        print("✓ Moved \(file.name) to trash")
                    } else {
                        print("[DRY RUN] Would move \(file.name) to trash")
                    }
                } catch {
                    failedItems.append((path: file.path, error: error))
                    print("⚠️  Failed to remove \(file.name): \(error.localizedDescription)")
                }
            }
            
            let result = AppUninstaller.UninstallResult(
                succeededItems: succeededItems,
                failedItems: failedItems,
                totalSize: selectedSize
            )
            displayResult(result, appName: app.shortName)
        }
    }
    
    func displayResult(_ result: AppUninstaller.UninstallResult, appName: String) {
        let sizeCalculator = FileSizeCalculator()
        
        if !result.failedItems.isEmpty {
            print("\n⚠️  Could not remove \(result.failedItems.count) item(s):")
            for item in result.failedItems {
                let fileName = URL(fileURLWithPath: item.path).lastPathComponent
                print("  • \(fileName)")
            }
            print("\nYou may need to quit the app or restart your Mac to remove these items.")
        }
        
        if !result.succeededItems.isEmpty {
            let sizeStr = sizeCalculator.formatSize(result.totalSize)
            let action = dryRun ? "Would have removed" : "Successfully removed"
            print("\n✅ \(action) \(result.succeededItems.count) item(s) (~\(sizeStr))")
            
            if !dryRun {
                print("\nItems have been moved to trash and can be restored from there if needed.")
            }
        }
    }
}

extension String {
    func pluralized(for count: Int) -> String {
        count == 1 ? self : self + "s"
    }
}
