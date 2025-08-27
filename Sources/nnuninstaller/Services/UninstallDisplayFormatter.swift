//
//  UninstallDisplayFormatter.swift
//  nnuninstaller
//
//  Created by Nikolai Nobadi on 8/27/25.
//

import Foundation

protocol UninstallDisplayFormatterProtocol {
    func displayFoundItems(app: AppInfo, appSize: Int64, files: [AppFileLocation], totalSize: String)
    func displayResult(_ result: AppUninstaller.UninstallResult, appName: String, dryRun: Bool)
}

struct UninstallDisplayFormatter: UninstallDisplayFormatterProtocol {
    private let sizeCalculator: FileSizeCalculator
    
    init(sizeCalculator: FileSizeCalculator = FileSizeCalculator()) {
        self.sizeCalculator = sizeCalculator
    }
    
    func displayFoundItems(app: AppInfo, appSize: Int64, files: [AppFileLocation], totalSize: String) {
        if files.isEmpty {
            displayAppOnly(app: app, appSize: appSize, totalSize: totalSize)
        } else {
            displayAppWithFiles(app: app, appSize: appSize, files: files, totalSize: totalSize)
        }
    }
    
    func displayResult(_ result: AppUninstaller.UninstallResult, appName: String, dryRun: Bool) {
        if !result.failedItems.isEmpty {
            displayFailedItems(result.failedItems)
        }
        
        if !result.succeededItems.isEmpty {
            displaySuccessfulItems(result, dryRun: dryRun)
        }
    }
}

// MARK: - Private Methods
private extension UninstallDisplayFormatter {
    func displayAppOnly(app: AppInfo, appSize: Int64, totalSize: String) {
        print("\n📦 Application:")
        print("  • \(app.fullName) (\(sizeCalculator.formatSize(appSize)))")
        print("    \(app.path)")
        print("\nNo additional files found.")
        print("\nTotal size: \(totalSize)")
    }
    
    func displayAppWithFiles(app: AppInfo, appSize: Int64, files: [AppFileLocation], totalSize: String) {
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
    
    func displayFailedItems(_ failedItems: [(path: String, error: Error)]) {
        print("\n⚠️  Could not remove \(failedItems.count) item(s):")
        for item in failedItems {
            let fileName = URL(fileURLWithPath: item.path).lastPathComponent
            print("  • \(fileName)")
        }
        print("\nYou may need to quit the app or restart your Mac to remove these items.")
    }
    
    func displaySuccessfulItems(_ result: AppUninstaller.UninstallResult, dryRun: Bool) {
        let sizeStr = sizeCalculator.formatSize(result.totalSize)
        let action = dryRun ? "Would have removed" : "Successfully removed"
        print("\n✅ \(action) \(result.succeededItems.count) item(s) (~\(sizeStr))")
        
        if !dryRun {
            print("\nItems have been moved to trash and can be restored from there if needed.")
        }
    }
}