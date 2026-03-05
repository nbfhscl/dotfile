# Config.psm1 - Configuration Module Summary

## Overview

A comprehensive **Config.psm1** module has been created to serve as the single source of truth for all configuration data in the dotfile management system. This eliminates hardcoded values scattered across multiple modules and provides a centralized, maintainable configuration system.

## Files Created

### 1. **Config.psm1** (Main Module)
**Location:** `D:\develop\dotfile\.config\powershell\modules\Config.psm1`

The core PowerShell module containing all configuration data and functions.

**Features:**
- 11 tool definitions (Git, Node.js, Neovim, PowerShell, etc.)
- 3 PowerShell module definitions (PSReadLine, Terminal-Icons, PSFzf)
- XDG Base Directory configuration for Windows
- Offline deployment settings
- UI and color scheme configuration
- Validation rules and system requirements
- Logging configuration
- Manual installation URLs

**Exported Functions:** 23 functions organized by category:
- Tool Configuration: `Get-ToolDefinitions`, `Get-ModuleDefinitions`, `Get-RuntimeDefinitions`
- Path Configuration: `Get-DotfileConfiguration`, `Get-XDGConfiguration`, `Get-ConfigurationPaths`
- Deployment Configuration: `Get-OfflineDeploymentConfiguration`, `Get-OneClickInstallConfiguration`
- UI Configuration: `Get-UIConfiguration`, `Get-ManualInstallationUrls`
- System Configuration: `Get-ValidationRules`, `Get-LoggingConfiguration`
- Utility Functions: `Get-AllConfiguration`, `Export-ConfigurationToJson`, `Test-ConfigurationIntegrity`, `Show-ConfigurationHelp`

### 2. **Config.md** (Documentation)
**Location:** `D:\develop\dotfile\.config\powershell\modules\Config.md`

Comprehensive documentation covering:
- Quick start guide
- All available functions with examples
- Configuration data structure
- Usage examples for common scenarios
- Migration guide from hardcoded values
- Best practices
- Testing and troubleshooting

### 3. **Config-Examples.ps1** (Example Code)
**Location:** `D:\develop\dotfile\.config\powershell\modules\Config-Examples.ps1`

Practical examples demonstrating:
- Basic module usage
- Refactoring existing modules to use Config
- Installing required tools
- Verifying tool installation
- Using XDG paths
- Creating custom tool installers
- Generating installation reports
- Using validation rules
- Using UI configuration
- Complete installation workflow

### 4. **configuration-export-sample.json** (Sample Export)
**Location:** `D:\develop\dotfile\.config\powershell\modules\configuration-export-sample.json`

Sample JSON export of the complete configuration for reference.

## Configuration Data Structure

### Tool Definitions
Each tool includes:
```powershell
Name                # Internal identifier
DisplayName         # Human-readable name
WingetId            # Package ID for winget
MinVersion          # Minimum required version
Command             # CLI command to verify installation
DownloadUrl         # Manual installation URL
Required            # Required or optional
Category            # Development, System, Productivity
Dependencies        # List of required runtimes
InstallScript       # Installation command
VerificationCommand # Version check command
Description         # Tool description
```

### Tools Defined (11 total)

**Required Tools (5):**
1. Git - Version control
2. Node.js - JavaScript runtime
3. Neovim - Text editor
4. PowerShell 7 - Shell
5. Oh-My-Posh - Theme engine

**Optional Tools (6):**
1. Windows Terminal - Terminal emulator
2. Zoxide - Smart cd command
3. Python - Programming language
4. .NET SDK - Development framework
5. Docker Desktop - Container platform
6. Visual Studio Code - Code editor

### PowerShell Modules (3)
1. PSReadLine v2.2.0 - Command-line editing
2. Terminal-Icons v0.7.0 - File/folder icons
3. PSFzf v2.2.0 - Fuzzy finder

### XDG Base Directory Paths
- Config Home: `$USERPROFILE\.local\config`
- Data Home: `$USERPROFILE\.local\data`
- State Home: `$USERPROFILE\.local\state`
- Cache Home: `$USERPROFILE\.cache`
- Application-specific paths for Neovim and Vim

## Usage Example

### Before (Hardcoded)
```powershell
function Install-Git {
    Install-Package -PackageName "Git" -WingetId "Git.Git" -Required
}
```

### After (Using Config)
```powershell
function Install-Git {
    $tools = Get-ToolDefinitions
    $git = $tools.Git
    Install-Package -PackageName $git.Name -WingetId $git.WingetId -Required:$git.Required
}
```

## Benefits

1. **Single Source of Truth**
   - All configuration in one place
   - No duplicated definitions
   - Easy to find and update

2. **Maintainability**
   - Update tool versions in one location
   - Add new tools consistently
   - Change paths centrally

3. **Consistency**
   - All modules use same data
   - No mismatches between scripts
   - Standardized tool properties

4. **Validation**
   - Built-in integrity checking
   - Type-safe configuration
   - Export for inspection

5. **Documentation**
   - Self-documenting structure
   - Comprehensive examples
   - Clear property definitions

## Testing

The module has been tested and verified:

```powershell
# Test import
Import-Module Config.psm1 -Force

# Test integrity
Test-ConfigurationIntegrity
# Result: Tools defined: 11, Modules defined: 3, Errors found: 0

# Test tool access
$tools = Get-ToolDefinitions
$tools.Git.DisplayName
# Result: Git for Windows

# Test export
Export-ConfigurationToJson -OutputPath "test.json"
# Result: Configuration exported successfully
```

## Integration with Existing Modules

The Config module should be imported by:
- **ToolInstaller.psm1** - For tool installation
- **DotfileInstaller.psm1** - For repository settings
- **ConfigDeployer.psm1** - For path configuration
- **Verifier.psm1** - For validation rules
- **UI.psm1** - For manual installation URLs
- **Package-Offline-Installer.ps1** - For offline package configuration

### Recommended Import Order
```powershell
# Import Config first
Import-Module (Join-Path $PSScriptRoot 'Config.psm1') -ErrorAction Stop

# Then import other modules that depend on Config
Import-Module (Join-Path $PSScriptRoot 'UI.psm1') -ErrorAction Stop
Import-Module (Join-Path $PSScriptRoot 'ToolInstaller.psm1') -ErrorAction Stop
```

## Next Steps

To fully integrate the Config module:

1. **Refactor existing modules**
   - Update `ToolInstaller.psm1` to use `Get-ToolDefinitions()`
   - Update `DotfileInstaller.psm1` to use `Get-DotfileConfiguration()`
   - Update `UI.psm1` to use `Get-ManualInstallationUrls()`
   - Update `Verifier.psm1` to use `Get-ValidationRules()`

2. **Update scripts**
   - Modify `Install-Tools.ps1` to use Config module
   - Modify `Deploy-Dotfiles.ps1` to use Config module
   - Modify `Verify-Configuration.ps1` to use Config module

3. **Test changes**
   - Verify all tools install correctly
   - Check path resolution works
   - Validate configuration integrity

4. **Document changes**
   - Update README files
   - Add examples to documentation
   - Create migration guide for users

## File Locations

```
D:\develop\dotfile\.config\powershell\modules\
├── Config.psm1                        # Main configuration module
├── Config.md                          # Complete documentation
├── Config-Examples.ps1                # Usage examples
└── configuration-export-sample.json   # Sample JSON export
```

## Quick Reference

```powershell
# Import the module
Import-Module Config.psm1

# Get tools
$tools = Get-ToolDefinitions

# Get paths
$paths = Get-ConfigurationPaths

# Get XDG configuration
$xdg = Get-XDGConfiguration

# Validate configuration
Test-ConfigurationIntegrity

# Export configuration
Export-ConfigurationToJson -OutputPath "config.json"

# Show help
Show-ConfigurationHelp
```

## Validation Status

✅ Module imports successfully
✅ All 11 tools defined correctly
✅ All 3 modules defined correctly
✅ Configuration integrity check passes
✅ JSON export works correctly
✅ All functions exported properly
✅ Documentation complete
✅ Examples tested

## Version

**Config Module Version:** 1.0.0
**Last Updated:** 2025-01-06
**Status:** Production Ready
