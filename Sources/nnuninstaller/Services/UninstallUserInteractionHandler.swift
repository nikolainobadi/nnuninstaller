//
//  UninstallUserInteractionHandler.swift
//  nnuninstaller
//
//  Created by Nikolai Nobadi on 8/27/25.
//

import Foundation
import SwiftPicker

protocol UninstallUserInteractionHandlerProtocol {
    func getUserChoice(picker: any CommandLinePicker, fileCount: Int) throws -> UninstallAction
}

struct UninstallUserInteractionHandler: UninstallUserInteractionHandlerProtocol {
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
}