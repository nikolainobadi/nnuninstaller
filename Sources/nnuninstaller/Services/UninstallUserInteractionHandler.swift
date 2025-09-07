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
        if fileCount == 0 {
            let shouldProceed = picker.getPermission(prompt: "No additional files found. Would you like to uninstall the app?")
            return shouldProceed ? .removeAll : .cancel
        }
        
        if fileCount == 1 {
            let shouldProceed = picker.getPermission(prompt: "Only 1 additional file found. Would you like to include this file as well?")
            return shouldProceed ? .removeAll : .cancel
        }
        
        let options = [
            "Remove all items",
            "Select which items to remove",
            "Cancel"
        ]
        
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