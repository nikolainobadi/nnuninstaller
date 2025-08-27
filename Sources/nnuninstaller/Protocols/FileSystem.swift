//
//  FileSystem.swift
//  nnuninstaller
//
//  Created by Nikolai Nobadi on 8/27/25.
//

import Foundation

protocol FileSystem {
    func contentsOfDirectory(atPath path: String) throws -> [String]
}

struct DefaultFileSystem: FileSystem {
    func contentsOfDirectory(atPath path: String) throws -> [String] {
        return try FileManager.default.contentsOfDirectory(atPath: path)
    }
}