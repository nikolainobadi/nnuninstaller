//
//  FileSizeCalculator.swift
//  nnuninstaller
//
//  Created by Nikolai Nobadi on 8/27/25.
//

import Foundation

struct FileSizeCalculator {
    func calculateSize(at path: String) -> Int64 {
        let fileManager = FileManager.default
        var isDirectory: ObjCBool = false
        
        guard fileManager.fileExists(atPath: path, isDirectory: &isDirectory) else {
            return 0
        }
        
        if isDirectory.boolValue {
            return calculateDirectorySize(at: path)
        } else {
            return calculateFileSize(at: path)
        }
    }
    
    func formatSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        formatter.includesUnit = true
        formatter.isAdaptive = true
        return formatter.string(fromByteCount: bytes)
    }
}


// MARK: - Private Methods
private extension FileSizeCalculator {
    func calculateFileSize(at path: String) -> Int64 {
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: path)
            return attributes[.size] as? Int64 ?? 0
        } catch {
            return 0
        }
    }
    
    func calculateDirectorySize(at path: String) -> Int64 {
        let fileManager = FileManager.default
        var totalSize: Int64 = 0
        
        guard let enumerator = fileManager.enumerator(
            at: URL(fileURLWithPath: path),
            includingPropertiesForKeys: [.fileSizeKey],
            options: [.skipsHiddenFiles, .skipsPackageDescendants]
        ) else {
            return 0
        }
        
        for case let fileURL as URL in enumerator {
            do {
                let resourceValues = try fileURL.resourceValues(forKeys: [.fileSizeKey])
                totalSize += Int64(resourceValues.fileSize ?? 0)
            } catch {
                // Skip files we can't read
                continue
            }
        }
        
        return totalSize
    }
}