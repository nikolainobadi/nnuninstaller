//
//  AppUninstaller.swift
//  nnuninstaller
//
//  Created by Nikolai Nobadi on 8/27/25.
//

import Foundation

struct AppUninstaller {
    struct UninstallResult {
        let succeededItems: [String]
        let failedItems: [(path: String, error: Error)]
        let totalSize: Int64
    }
    
    private let fileManager: FileManager
    private let dryRun: Bool
    private let createLog: Bool
    
    init(fileManager: FileManager = .default, dryRun: Bool = false, createLog: Bool = false) {
        self.fileManager = fileManager
        self.dryRun = dryRun
        self.createLog = createLog
    }
}


// MARK: - Actions
extension AppUninstaller {
    func uninstallApp(_ app: AppInfo, withFiles files: [AppFileLocation]) throws -> UninstallResult {
        var succeededItems: [String] = []
        var failedItems: [(path: String, error: Error)] = []
        var totalSize: Int64 = 0
        
        // Always include the app itself
        let appLocation = AppFileLocation(
            path: app.path,
            name: app.fullName,
            location: "Applications",
            appName: app.shortName,
            size: FileSizeCalculator().calculateSize(at: app.path)
        )
        
        let allItems = [appLocation] + files
        
        if createLog {
            createUninstallLog(app: app, items: allItems)
        }
        
        for item in allItems {
            do {
                if !dryRun {
                    try moveToTrash(path: item.path)
                }
                succeededItems.append(item.name)
                totalSize += item.size ?? 0
                
                if !dryRun {
                    print("✓ Moved \(item.name) to trash")
                } else {
                    print("[DRY RUN] Would move \(item.name) to trash")
                }
            } catch {
                failedItems.append((path: item.path, error: error))
                print("⚠️  Failed to remove \(item.name): \(error.localizedDescription)")
            }
        }
        
        return UninstallResult(
            succeededItems: succeededItems,
            failedItems: failedItems,
            totalSize: totalSize
        )
    }
    
    func moveToTrash(path: String) throws {
        guard !dryRun else { return }
        
        let url = URL(fileURLWithPath: path)
        try fileManager.trashItem(at: url, resultingItemURL: nil)
    }
}


// MARK: - Private Methods
private extension AppUninstaller {
    func createUninstallLog(app: AppInfo, items: [AppFileLocation]) {
        guard createLog else { return }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd-HH-mm-ss"
        let timestamp = formatter.string(from: Date())
        
        let logDir = "\(NSHomeDirectory())/Library/Logs/nnuninstaller"
        let logPath = "\(logDir)/\(timestamp)-\(app.shortName)-uninstall.log"
        
        // Create log directory if it doesn't exist
        try? fileManager.createDirectory(atPath: logDir, withIntermediateDirectories: true)
        
        var logContent = "Uninstall Log for \(app.fullName)\n"
        logContent += "Date: \(Date())\n"
        logContent += "Dry Run: \(dryRun)\n\n"
        logContent += "Items to remove:\n"
        
        for item in items {
            let sizeStr = item.formattedSize.isEmpty ? "" : " (\(item.formattedSize))"
            logContent += "  - \(item.name)\(sizeStr)\n"
            logContent += "    Path: \(item.path)\n"
        }
        
        try? logContent.write(toFile: logPath, atomically: true, encoding: .utf8)
        
        if !dryRun {
            print("\n📝 Log created at: \(logPath)")
        }
    }
}