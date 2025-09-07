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
swift run nnuninstaller uninstall --dry-run  # Safe testing mode
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
- `ListApps` - Lists non-Apple applications in `/Applications`
- `CheckAppFiles` - Interactive app selection and file discovery workflow  
- `UninstallApp` - Complete uninstall workflow with context-aware user interaction:
  - 0 files: Simple yes/no confirmation for app-only removal
  - 1 file: Ask to include the single additional file
  - Multiple files: Three-option flow (remove all/select items/cancel)
  - Supports dry-run, force, and logging flags
- Each command implements `ParsableCommand` from ArgumentParser
- Commands use dependency injection through the main `Nnuninstaller` factory methods

**Core Logic** (Located in `Sources/nnuninstaller/Helpers/`):
- `AppLister` - Scans `/Applications` directory and identifies non-Apple signed apps using `codesign` shell commands
- `AppFileChecker` - Searches common macOS locations for files associated with applications:
  - `~/Library/Application Support`, `~/Library/Caches`, `~/Library/Preferences`
  - `~/Library/Logs`, `~/Library/Containers`, `~/Library/Cookies`
- `AppUninstaller` - Handles safe deletion to trash with dry-run support and logging
- `FileSizeCalculator` - Calculates and formats file/directory sizes accurately

**Models** (Located in `Sources/nnuninstaller/Models/`):
- `AppInfo` - Application metadata, handles underscore-separated names (e.g., CleanMyMac_5_MAS.app → CleanMyMac)
- `AppFileLocation` - Represents associated files with path, size, and location metadata

**Protocols** (Located in `Sources/nnuninstaller/Protocols/`):
- `FileSystem` protocol - Abstraction for file system operations (enables testable code)

**Reusable Services** (Located in `Sources/nnuninstaller/Services/`):
- `UninstallService` - Orchestrates the complete uninstall workflow, handles force flag and result processing
- `UninstallDisplayFormatter` - Handles all UI display logic for found items and uninstall results
- `UninstallUserInteractionHandler` - **NEW**: Context-aware user interaction logic:
  - 0 files: `getPermission()` with "No additional files found. Would you like to uninstall the app?"
  - 1 file: `getPermission()` with "Only 1 additional file found. Would you like to include this file as well?"  
  - Multiple files: Traditional three-option selection menu
  - Returns appropriate `UninstallAction` (.removeAll, .selectItems, .cancel)
- These services promote code reusability and separation of concerns, making commands clean and testable

### Dependencies
- **NnShellKit**: Custom shell command execution wrapper
- **SwiftPicker**: Interactive command-line selection interface  
- **ArgumentParser**: Apple's command-line argument parsing

### Recent Changes (Latest Commits)
- **Enhanced User Interaction**: Fixed delete confirmation bug - prompts now adapt based on file count (0/1/multiple)
- **Service Architecture**: Extracted reusable services from commands for better separation of concerns
- **Improved Error Handling**: Graceful cancellation handling using `getPermission()` instead of `requiredPermission()`
- **Test Coverage**: Updated all tests to reflect new context-aware behavior

### Testing Strategy
Uses Swift Testing framework with comprehensive mocking:
- `MockFileSystem` - Mock file system operations with configurable directory contents
- `MockShell` - Mock shell command execution with predictable results  
- `MockContext` - Mock dependency injection context for isolated testing
- `MockPicker` - Mock user interactions with configurable responses for both permissions and selections
- Tests use `Nnuninstaller.testRun()` for end-to-end command execution testing
- **Test Coverage**: All scenarios covered including 0/1/multiple file cases and cancellation flows

The architecture enables easy testing through protocol-based dependency injection and clear separation of concerns between CLI parsing, business logic, and system interactions.