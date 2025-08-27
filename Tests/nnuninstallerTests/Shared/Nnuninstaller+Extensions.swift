//
//  Nnuninstaller+Extensions.swift
//  nnuninstallerTests
//
//  Created by Nikolai Nobadi on 8/27/25.
//

import ArgumentParser
import NnShellKit
import SwiftPicker
import Dispatch
@testable import nnuninstaller

extension Nnuninstaller {
    @discardableResult
    static func testRun(context: NnContext, args: [String]) throws -> String {
        // Create a temporary context for this test run
        let originalContext = Nnuninstaller.context
        
        // Use a synchronization mechanism to avoid race conditions
        let semaphore = DispatchSemaphore(value: 1)
        var error: Error?
        
        semaphore.wait()
        defer { semaphore.signal() }
        
        Nnuninstaller.context = context
        defer { Nnuninstaller.context = originalContext }
        
        do {
            // Parse and run the command
            let parsedCommand = try Nnuninstaller.parseAsRoot(args)
            
            // Execute the command with the mock context already set
            var command = parsedCommand
            try command.run()
        } catch let e {
            error = e
        }
        
        if let error = error {
            throw error
        }
        
        return ""
    }
}

struct MockContext: NnContext {
    private let shell: any Shell
    private let picker: any CommandLinePicker
    private let fileSystem: any FileSystem
    
    init(
        shell: any Shell = MockShell(), 
        picker: any CommandLinePicker = MockPicker(),
        fileSystem: any FileSystem = MockFileSystem()
    ) {
        self.shell = shell
        self.picker = picker
        self.fileSystem = fileSystem
    }
    
    func makeShell() -> any Shell {
        return shell
    }
    
    func makePicker() -> any CommandLinePicker {
        return picker
    }
    
    func makeFileSystem() -> any FileSystem {
        return fileSystem
    }
}

final class MockPicker: CommandLinePicker {
    private let inputResponses: [String: String]
    private let permissionResponses: [String: Bool] 
    private let selectionResponses: [String: Int]
    
    private(set) var inputs: [String] = []
    private(set) var permissions: [String] = []
    private(set) var selections: [String] = []
    
    init(
        inputResponses: [String: String] = [:],
        permissionResponses: [String: Bool] = [:],
        selectionResponses: [String: Int] = [:]
    ) {
        self.inputResponses = inputResponses
        self.permissionResponses = permissionResponses
        self.selectionResponses = selectionResponses
    }
    
    // MARK: - CommandLineInput
    
    func getInput(prompt: any PickerPrompt) -> String {
        inputs.append(prompt.title)
        return inputResponses[prompt.title] ?? ""
    }
    
    func getRequiredInput(prompt: any PickerPrompt) throws -> String {
        let result = getInput(prompt: prompt)
        if result.isEmpty {
            throw SwiftPickerError.inputRequired
        }
        return result
    }
    
    // MARK: - CommandLinePermission
    
    func getPermission(prompt: any PickerPrompt) -> Bool {
        permissions.append(prompt.title)
        return permissionResponses[prompt.title] ?? false
    }
    
    func requiredPermission(prompt: any PickerPrompt) throws {
        if !getPermission(prompt: prompt) {
            throw SwiftPickerError.selectionCancelled
        }
    }
    
    // MARK: - CommandLineSelection
    
    func singleSelection<Item: DisplayablePickerItem>(title: any PickerPrompt, items: [Item]) -> Item? {
        selections.append(title.title)
        guard let index = selectionResponses[title.title], 
              index < items.count else {
            return nil
        }
        return items[index]
    }
    
    func requiredSingleSelection<Item: DisplayablePickerItem>(title: any PickerPrompt, items: [Item]) throws -> Item {
        guard let result = singleSelection(title: title, items: items) else {
            throw SwiftPickerError.selectionCancelled
        }
        return result
    }
    
    func multiSelection<Item: DisplayablePickerItem>(title: any PickerPrompt, items: [Item]) -> [Item] {
        selections.append(title.title)
        guard let index = selectionResponses[title.title], 
              index < items.count else {
            return []
        }
        return [items[index]]
    }
    
}
