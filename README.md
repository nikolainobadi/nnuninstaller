# nnuninstaller

A clean, safe macOS command-line tool for completely uninstalling non-Apple applications and their associated files.

## Features

- **Smart App Detection** - Automatically identifies non-Apple applications using code signatures
- **Complete File Discovery** - Finds associated files in common macOS locations (Library, Caches, Preferences, etc.)
- **Interactive Selection** - Choose which files to remove with an intuitive selection interface
- **Safe Operations** - Dry-run mode and trash-based deletion (files can be restored)
- **Size Calculation** - Shows space savings with accurate file size calculations
- **Comprehensive Logging** - Optional logging of all removal operations

## Installation

### Requirements

- macOS 14.0 or later
- Swift 6.0 or later (for building from source)

### Build from Source

```bash
git clone <repository-url>
cd nnuninstaller
swift build -c release
cp .build/release/nnuninstaller /usr/local/bin/
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
3. **User Choice** - Presents three options:
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
Remove all items, select specific items, or cancel? Remove all items
✅ Successfully removed 8 items (~380 MB)
Items have been moved to trash and can be restored if needed.
```

## Architecture

Built with Swift Package Manager using clean architecture principles:

- **Commands** - CLI interface using Swift ArgumentParser
- **Services** - Reusable business logic components
- **Helpers** - Utilities for file operations and system interaction
- **Models** - Data structures for applications and file information
- **Protocols** - Abstractions for dependency injection and testing

## Dependencies

- [swift-argument-parser](https://github.com/apple/swift-argument-parser) - Command-line interface
- [NnShellKit](https://github.com/nikolainobadi/NnShellKit) - Shell command execution
- [SwiftPicker](https://github.com/nikolainobadi/SwiftPicker) - Interactive selection interface

## Development

### Building

```bash
swift build
```

### Testing

```bash
swift test
```

### Running Specific Tests

```bash
# Run tests for a specific component
swift test --filter UninstallAppTests

# Run a single test
swift test --filter UninstallAppTests.dry_run_executes_without_deleting
```

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