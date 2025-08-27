//
//  UninstallService.swift
//  nnuninstaller
//
//  Created by Nikolai Nobadi on 8/27/25.
//

import Foundation
import SwiftPicker

protocol UninstallServiceProtocol {
    func performUninstall(
        app: AppInfo,
        associatedFiles: [AppFileLocation],
        options: UninstallOptions,
        picker: any CommandLinePicker
    ) throws -> UninstallResult
}

struct UninstallOptions {
    let dryRun: Bool
    let force: Bool
    let createLog: Bool
    
    init(dryRun: Bool = false, force: Bool = false, createLog: Bool = false) {
        self.dryRun = dryRun
        self.force = force
        self.createLog = createLog
    }
}

enum UninstallAction {
    case removeAll
    case selectItems
    case cancel
}

struct UninstallResult {
    let action: UninstallAction
    let uninstallerResult: AppUninstaller.UninstallResult?
    let cancelled: Bool
    
    var wasSuccessful: Bool {
        !cancelled && uninstallerResult != nil
    }
}

struct UninstallService: UninstallServiceProtocol {
    private let userInteractionHandler: UninstallUserInteractionHandler
    
    init(userInteractionHandler: UninstallUserInteractionHandler = UninstallUserInteractionHandler()) {
        self.userInteractionHandler = userInteractionHandler
    }
    
    func performUninstall(
        app: AppInfo,
        associatedFiles: [AppFileLocation],
        options: UninstallOptions,
        picker: any CommandLinePicker
    ) throws -> UninstallResult {
        
        // Step 1: Get user choice (unless force flag is used)
        let action: UninstallAction
        if options.force {
            action = .removeAll
            print("\n⚠️  Force flag enabled - removing all items without confirmation")
        } else {
            action = try userInteractionHandler.getUserChoice(
                picker: picker,
                fileCount: associatedFiles.count
            )
        }
        
        // Step 2: Execute based on choice
        switch action {
        case .removeAll:
            let result = try handleRemoveAll(
                app: app,
                files: associatedFiles,
                options: options,
                picker: picker
            )
            return UninstallResult(action: action, uninstallerResult: result, cancelled: false)
            
        case .selectItems:
            let result = try handleSelectItems(
                app: app,
                files: associatedFiles,
                options: options,
                picker: picker
            )
            return UninstallResult(action: action, uninstallerResult: result, cancelled: false)
            
        case .cancel:
            return UninstallResult(action: action, uninstallerResult: nil, cancelled: true)
        }
    }
}

// MARK: - Private Methods
private extension UninstallService {
    func handleRemoveAll(
        app: AppInfo,
        files: [AppFileLocation],
        options: UninstallOptions,
        picker: any CommandLinePicker
    ) throws -> AppUninstaller.UninstallResult? {
        
        if !options.force {
            let itemCount = files.count + 1 // +1 for the app itself
            let confirmPrompt = "⚠️  Confirmation: Move all \(itemCount) items to trash?"
            
            guard picker.getPermission(prompt: confirmPrompt) else {
                print("\nUninstall cancelled.")
                return nil
            }
        }
        
        print("\n\(options.dryRun ? "[DRY RUN] Would move" : "Moving") items to trash...")
        
        let uninstaller = AppUninstaller(dryRun: options.dryRun, createLog: options.createLog)
        return try uninstaller.uninstallApp(app, withFiles: files)
    }
    
    func handleSelectItems(
        app: AppInfo,
        files: [AppFileLocation],
        options: UninstallOptions,
        picker: any CommandLinePicker
    ) throws -> AppUninstaller.UninstallResult? {
        
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
            return nil
        }
        
        // Calculate selected size
        let sizeCalculator = FileSizeCalculator()
        let selectedSize = selectedItems.reduce(0) { $0 + ($1.size ?? 0) }
        let formattedSize = sizeCalculator.formatSize(selectedSize)
        
        print("\nSelected \(selectedItems.count) of \(allItems.count) items (~\(formattedSize))")
        
        if !options.force {
            let confirmPrompt = "Confirm: Move \(selectedItems.count) selected items to trash?"
            guard picker.getPermission(prompt: confirmPrompt) else {
                print("\nUninstall cancelled.")
                return nil
            }
        }
        
        print("\n\(options.dryRun ? "[DRY RUN] Would move" : "Moving") selected items to trash...")
        
        // Separate app from other files
        let selectedApp = selectedItems.first { $0.path == app.path } != nil ? app : nil
        let selectedFiles = selectedItems.filter { $0.path != app.path }
        
        let uninstaller = AppUninstaller(dryRun: options.dryRun, createLog: options.createLog)
        
        if let selectedApp = selectedApp {
            // If app is selected, uninstall it with selected files
            return try uninstaller.uninstallApp(selectedApp, withFiles: selectedFiles)
        } else {
            // If app is not selected, only remove selected files
            var succeededItems: [String] = []
            var failedItems: [(path: String, error: Error)] = []
            
            for file in selectedFiles {
                do {
                    try uninstaller.moveToTrash(path: file.path)
                    succeededItems.append(file.name)
                    if !options.dryRun {
                        print("✓ Moved \(file.name) to trash")
                    } else {
                        print("[DRY RUN] Would move \(file.name) to trash")
                    }
                } catch {
                    failedItems.append((path: file.path, error: error))
                    print("⚠️  Failed to remove \(file.name): \(error.localizedDescription)")
                }
            }
            
            return AppUninstaller.UninstallResult(
                succeededItems: succeededItems,
                failedItems: failedItems,
                totalSize: selectedSize
            )
        }
    }
}