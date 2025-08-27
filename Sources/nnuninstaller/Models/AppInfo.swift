//
//  AppInfo.swift
//  nnuninstaller
//
//  Created by Nikolai Nobadi on 8/27/25.
//

import Foundation

struct AppInfo {
    let fullName: String
    let shortName: String
    let path: String
    
    init(path: String) {
        self.path = path
        self.fullName = URL(fileURLWithPath: path).lastPathComponent
        self.shortName = fullName.hasSuffix(".app") ? String(fullName.dropLast(4)) : fullName
    }
}