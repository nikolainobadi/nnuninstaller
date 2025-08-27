//
//  File.swift
//  nnuninstaller
//
//  Created by Nikolai Nobadi on 8/26/25.
//

import ArgumentParser

@main
struct Nnuninstaller: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "",
        version: "0.1.0",
        subcommands: [
            
        ]
    )
    
    nonisolated(unsafe) static var context: NnContext = DefaultContext()
}

extension Nnuninstaller {
    static func makeShell() -> any Shell {
        return context.makeShell()
    }
    
    static func makePicker() -> any CommandLinePicker {
        return context.makePicker()
    }
}

import NnShellKit
import SwiftPicker

protocol NnContext {
    func makeShell() -> any Shell
    func makePicker() -> any CommandLinePicker
}

struct DefaultContext: NnContext {
    func makeShell() -> any Shell {
        return NnShell()
    }
    
    func makePicker() -> any CommandLinePicker {
        return InteractivePicker()
    }
}
