//
//  MockFileSystem.swift
//  nnuninstallerTests
//
//  Created by Nikolai Nobadi on 8/27/25.
//

import Foundation
@testable import nnuninstaller

final class MockFileSystem: FileSystem, @unchecked Sendable {
    private let directoryContents: [String: [String]]
    private let shouldThrowError: Bool
    private let errorToThrow: Error?
    
    private let lock = NSLock()
    private var _contentsOfDirectoryCalls: [String] = []
    
    var contentsOfDirectoryCalls: [String] {
        lock.lock()
        defer { lock.unlock() }
        return _contentsOfDirectoryCalls
    }
    
    init(
        directoryContents: [String: [String]] = [:],
        shouldThrowError: Bool = false,
        errorToThrow: Error? = nil
    ) {
        self.directoryContents = directoryContents
        self.shouldThrowError = shouldThrowError
        self.errorToThrow = errorToThrow
    }
    
    func contentsOfDirectory(atPath path: String) throws -> [String] {
        lock.lock()
        _contentsOfDirectoryCalls.append(path)
        lock.unlock()
        
        if shouldThrowError {
            throw errorToThrow ?? MockFileSystemError.directoryNotFound(path)
        }
        
        return directoryContents[path] ?? []
    }
}

enum MockFileSystemError: Error {
    case directoryNotFound(String)
}