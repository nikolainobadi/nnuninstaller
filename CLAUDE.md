# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

### Building and Testing
```bash
# Build the project
swift build

# Run tests
swift test

# Run the executable directly
swift run nnuninstaller <command>

# Build and run specific commands
swift run nnuninstaller list-apps
swift run nnuninstaller check-app-files
```

### Running Single Tests
```bash
# Run a specific test function
swift test --filter ListAppsTests.run_withValidApps_callsExpectedDependencies

# Run all tests in a specific test file
swift test --filter ListAppsTests
```

## Architecture

This is a Swift Package Manager CLI tool for uninstalling non-Apple applications on macOS. The project follows a clean architecture with dependency injection.

### Core Components

**Main Entry Point**: `Nnuninstaller.swift` - Uses Swift ArgumentParser for command-line interface with subcommands

**Dependency Injection**: The main struct provides factory methods through `NnContext` protocol:
- `makeShell()` - Returns `NnShell` from NnShellKit for shell command execution
- `makePicker()` - Returns `InteractivePicker` from SwiftPicker for user selection
- `makeFileSystem()` - Returns `DefaultFileSystem` for file operations

**Commands**: Located in `Sources/nnuninstaller/Commands/`
- Each command implements `ParsableCommand` from ArgumentParser
- Commands use dependency injection through the main `Nnuninstaller` factory methods

**Core Logic**: 
- `AppLister` - Scans `/Applications` directory and identifies non-Apple signed apps using `codesign` shell commands
- `AppInfo` - Model representing application metadata (path, full name, short name), implements `DisplayablePickerItem`
- `AppFileChecker` - Searches common macOS locations for files associated with applications
- `FileSystem` protocol - Abstraction for file system operations (testable)

### Dependencies
- **NnShellKit**: Custom shell command execution wrapper
- **SwiftPicker**: Interactive command-line selection interface  
- **ArgumentParser**: Apple's command-line argument parsing

### Testing Strategy
Uses Swift Testing framework with comprehensive mocking:
- `MockFileSystem` - Mock file system operations
- `MockShell` - Mock shell command execution
- `MockContext` - Mock dependency injection context
- Tests use `Nnuninstaller.testRun()` for command execution testing

The architecture enables easy testing through protocol-based dependency injection and clear separation of concerns between CLI parsing, business logic, and system interactions.