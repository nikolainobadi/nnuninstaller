# nnuninstaller

![Build Status](https://github.com/nikolainobadi/nnuninstaller/actions/workflows/ci.yml/badge.svg)
![Swift Version](https://badgen.net/badge/swift/6.0%2B/purple)
![Platform](https://img.shields.io/badge/platform-macOS%2014-blue)
![License](https://img.shields.io/badge/license-MIT-lightgrey)

A clean, safe macOS command-line tool for completely uninstalling non-Apple applications and their associated files.

## Features

- **Smart App Detection** - Automatically identifies non-Apple applications using code signatures
- **Complete File Discovery** - Finds associated files in common macOS locations (Library, Caches, Preferences, etc.)
- **Interactive Selection** - Choose which files to remove with an intuitive selection interface
- **Safe Operations** - Dry-run mode and trash-based deletion (files can be restored)
- **Size Calculation** - Shows space savings with accurate file size calculations
- **Comprehensive Logging** - Optional logging of all removal operations

## Installation
```bash
brew tap nikolainobadi/nntools
brew install nnuninstaller
```

## Usage

### List Applications

Show all non-Apple applications that can be uninstalled:

```bash
nnuninstaller list-apps
```

### Check Associated Files

Interactively select an app and view its associated files:

```bash
nnuninstaller check-app-files
```

### Uninstall Application

Complete uninstall workflow with multiple options:

```bash
# Interactive uninstall (recommended)
nnuninstaller uninstall

# Dry run to see what would be deleted
nnuninstaller uninstall --dry-run

# Force removal without confirmation (dangerous!)
nnuninstaller uninstall --force

# Create a log of deleted items
nnuninstaller uninstall --log
```

## How it Works

1. **App Discovery** - Scans `/Applications` directory and filters out Apple-signed applications
2. **File Search** - Looks for associated files in standard macOS locations:
   - `~/Library/Application Support`
   - `~/Library/Caches`
   - `~/Library/Preferences`
   - `~/Library/Logs`
   - `~/Library/Containers`
   - `~/Library/Cookies`
3. **Smart User Interaction** - Context-aware prompts based on file count:
   - **0 files found**: "No additional files found. Would you like to uninstall the app?"
   - **1 file found**: "Only 1 additional file found. Would you like to include this file as well?"
   - **Multiple files found**: Choose from three options:
     - Remove all items
     - Select specific items to remove  
     - Cancel operation
4. **Safe Deletion** - Moves items to Trash (recoverable) rather than permanent deletion

## Safety Features

- **Dry Run Mode** - Preview operations without making changes
- **Trash-based Deletion** - All files moved to Trash, not permanently deleted
- **Apple App Protection** - Only non-Apple applications can be uninstalled
- **Confirmation Prompts** - Multiple confirmation steps before deletion
- **Size Verification** - Shows accurate file sizes before removal

## Examples

### Basic Usage

```bash
# See what apps can be uninstalled
$ nnuninstaller list-apps
Chrome.app
Discord.app
Steam.app
VSCode.app

# Check files for a specific app
$ nnuninstaller check-app-files
Select an application: Discord
Found 5 items associated with Discord:
  📦 Application: Discord.app (150 MB)
  📁 Application Support: Discord (45 MB)
  📁 Caches: com.hnc.Discord (12 MB)
  Total size: ~207 MB
```

### Safe Uninstall

```bash
# Dry run first to see what would be removed
$ nnuninstaller uninstall --dry-run
Select an application: Chrome
[DRY RUN] Would move 8 items to trash (~380 MB)

# Actual uninstall
$ nnuninstaller uninstall
Select an application: Chrome
3 additional files found. What would you like to do?
> Remove all items
  Select which items to remove
  Cancel
✅ Successfully removed 8 items (~380 MB)
Items have been moved to trash and can be restored if needed.
```

## Recent Improvements

- **Enhanced User Experience**: Context-aware prompts that adapt based on the number of associated files found
- **Improved Service Architecture**: Extracted reusable services (`UninstallService`, `UninstallDisplayFormatter`, `UninstallUserInteractionHandler`) for better separation of concerns
- **Better Error Handling**: Graceful handling of user cancellations and edge cases
- **Comprehensive Testing**: Full test coverage with mock objects for reliable testing

## Architecture

Built with Swift Package Manager using clean architecture principles:

### Core Structure
- **Commands** (`Sources/nnuninstaller/Commands/`) - CLI interface using Swift ArgumentParser
  - `ListApps` - Lists non-Apple applications  
  - `CheckAppFiles` - Interactive app selection and file discovery
  - `UninstallApp` - Complete uninstall workflow with context-aware prompts
- **Services** (`Sources/nnuninstaller/Services/`) - Reusable business logic components
  - `UninstallService` - Orchestrates the complete uninstall workflow
  - `UninstallDisplayFormatter` - Handles all UI display logic
  - `UninstallUserInteractionHandler` - Manages context-aware user prompts
- **Helpers** (`Sources/nnuninstaller/Helpers/`) - Utilities for file operations and system interaction
  - `AppLister` - App discovery and Apple signature filtering
  - `AppFileChecker` - Associated file discovery in standard macOS locations
  - `AppUninstaller` - Safe trash-based deletion with logging
  - `FileSizeCalculator` - Accurate size calculations and formatting
- **Models** (`Sources/nnuninstaller/Models/`) - Data structures for applications and file information
- **Protocols** (`Sources/nnuninstaller/Protocols/`) - Abstractions for dependency injection and testing

## Dependencies

- [swift-argument-parser](https://github.com/apple/swift-argument-parser) - Command-line interface
- [NnShellKit](https://github.com/nikolainobadi/NnShellKit) - Shell command execution
- [SwiftPicker](https://github.com/nikolainobadi/SwiftPicker) - Interactive selection interface

## License

See [LICENSE](LICENSE) file for details.

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Ensure all tests pass
6. Submit a pull request

## Safety Notice

⚠️ **Always use `--dry-run` first** to preview changes before performing actual uninstalls. While this tool moves files to Trash (allowing recovery), it's always better to verify operations beforehand.

This tool is designed for safety and will never:
- Delete Apple system applications
- Permanently delete files (uses Trash)
- Operate without user confirmation (unless `--force` is explicitly used)
