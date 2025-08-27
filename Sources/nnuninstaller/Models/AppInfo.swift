//
//  AppInfo.swift
//  nnuninstaller
//
//  Created by Nikolai Nobadi on 8/27/25.
//

import Foundation
import SwiftPicker

struct AppInfo {
    let fullName: String
    let shortName: String
    let path: String
    
    init(path: String) {
        self.path = path
        if path.isEmpty {
            self.fullName = ""
            self.shortName = ""
        } else {
            self.fullName = URL(fileURLWithPath: path).lastPathComponent
            let baseName = fullName.hasSuffix(".app") ? String(fullName.dropLast(4)) : fullName
            self.shortName = baseName.components(separatedBy: "_").first ?? baseName
        }
    }
}


// MARK: - DisplayablePickerItem
extension AppInfo: DisplayablePickerItem {
    var displayName: String {
        return shortName
    }
}