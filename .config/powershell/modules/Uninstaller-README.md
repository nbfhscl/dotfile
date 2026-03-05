# Uninstaller.psm1 Module Documentation

## Overview

The **Uninstaller.psm1** module provides comprehensive uninstallation functionality for dotfile configurations on Windows. It consolidates all uninstall logic into a single, well-organized module with support for full uninstall, quick uninstall, and custom selective removal.

## Features

- **Three Uninstall Modes**: Full, Quick, and Custom uninstall options
- **Safe Operations**: Automatic backup before removal
- **Flexible Removal**: Selective component removal with granular control
- **Tool Management**: Integrated winget support for uninstalling development tools
- **Backup Management**: Track and manage uninstall backups
- **Error Handling**: Comprehensive error handling with clear messaging
- **Dry Run Support**: Preview changes before executing
- **Interactive & Quiet Modes**: Support for both -Force automation and interactive prompts

## Installation

The module is located at:
```
D:\develop\dotfile\.config\powershell\modules\Uninstaller.psm1
```

Import the module:
```powershell
Import-Module (Join-Path $PSScriptRoot 'modules\Uninstaller.psm1')
```

## Quick Start

### Full Uninstall (Remove Everything)
```powershell
Import-Module (Join-Path $PSScriptRoot 'modules\Uninstaller.psm1')

# Remove all configurations and tools
Invoke-FullUninstall -RemoveTools -Force

# Remove all but keep tools
Invoke-FullUninstall
```

### Quick Uninstall (Keep Tools)
```powershell
# Remove configurations only, preserve installed tools
Invoke-QuickUninstall

# Keep Neovim and Oh-My-Posh configs
Invoke-QuickUninstall -KeepNeovimConfig -KeepPoshTheme
```

### Custom Uninstall (Selective Removal)
```powershell
# Remove only repository and alias
Invoke-CustomUninstall -RemoveRepo -RemoveAlias -RemoveTracked

# Remove only configuration directories
Invoke-CustomUninstall -RemoveNeovim -RemovePoshTheme -RemoveWindowsTerminal
```

## Function Reference

### Main Uninstall Functions

#### `Invoke-FullUninstall`
Perform complete removal of all dotfile components.

**Parameters:**
- `-RemoveTools`: Also uninstall tools via winget (default: false)
- `-KeepBackups`: Keep backup files (default: false)
- `-DryRun`: Show what would be done without executing
- `-Force`: Suppress confirmation prompts

**Examples:**
```powershell
Invoke-FullUninstall                              # Keep tools
Invoke-FullUninstall -RemoveTools                 # Remove tools too
Invoke-FullUninstall -RemoveTools -Force          # No prompts
Invoke-FullUninstall -DryRun                      # Preview only
```

#### `Invoke-QuickUninstall`
Remove configurations while preserving installed tools.

**Parameters:**
- `-KeepNeovimConfig`: Preserve Neovim configuration
- `-KeepPoshTheme`: Preserve Oh-My-Posh theme
- `-KeepXDGVars`: Preserve XDG environment variables
- `-DryRun`: Show what would be done without executing
- `-Force`: Suppress confirmation prompts

**Examples:**
```powershell
Invoke-QuickUninstall                                     # Remove all configs
Invoke-QuickUninstall -KeepNeovimConfig                   # Keep Neovim
Invoke-QuickUninstall -KeepNeovimConfig -KeepPoshTheme    # Keep both
```

#### `Invoke-CustomUninstall`
Selective component removal with fine-grained control.

**Parameters:**
- `-RemoveRepo`: Remove dotfile bare repository
- `-RemoveAlias`: Remove dot alias from profiles
- `-RemoveTracked`: Remove all tracked files
- `-RemoveNeovim`: Remove Neovim configuration
- `-RemovePoshTheme`: Remove Oh-My-Posh theme
- `-RemoveWindowsTerminal`: Remove Windows Terminal settings
- `-RemoveXDG`: Remove XDG environment variables
- `-RemoveTools`: Uninstall tools via winget
- `-BackupBeforeRemove`: Create backup before removal (default: true)
- `-DryRun`: Show what would be done
- `-Force`: Suppress confirmation prompts

**Examples:**
```powershell
# Remove repo and alias only
Invoke-CustomUninstall -RemoveRepo -RemoveAlias

# Remove configurations only
Invoke-CustomUninstall -RemoveNeovim -RemovePoshTheme -RemoveXDG

# Remove tracked files and backup first
Invoke-CustomUninstall -RemoveTracked -RemoveRepo -BackupBeforeRemove
```

### Core Removal Functions

#### `Remove-DotfileRepo`
Remove the bare dotfile git repository.

**Parameters:**
- `-Force`: Suppress confirmation prompt

**Example:**
```powershell
Remove-DotfileRepo          # Prompts first
Remove-DotfileRepo -Force   # No prompt
```

#### `Remove-DotAlias`
Remove the 'dot' function alias from PowerShell profiles.

**Parameters:**
- `-ProfilePath`: Specific profile to clean
- `-AllProfiles`: Remove from all PowerShell profiles (default)
- `-Force`: Suppress confirmation prompts

**Examples:**
```powershell
Remove-DotAlias                           # All profiles with prompt
Remove-DotAlias -AllProfiles -Force       # All profiles, no prompt
Remove-DotAlias -ProfilePath $PROFILE     # Specific profile only
```

#### `Remove-PowerShellProfileConfig`
Remove dotfile-specific configuration from PowerShell profiles.

**Parameters:**
- `-ProfilePath`: Specific profile to clean (default: current user profile)
- `-Force`: Suppress confirmation prompts

**Example:**
```powershell
Remove-PowerShellProfileConfig
```

#### `Remove-XDGVariables`
Remove XDG Base Directory environment variables.

**Parameters:**
- `-FromProfile`: Remove from PowerShell profiles
- `-FromEnvironment`: Remove from system/user environment (requires admin)
- `-Force`: Suppress confirmation prompts

**Examples:**
```powershell
Remove-XDGVariables -FromProfile                              # Profiles only
Remove-XDGVariables -FromProfile -FromEnvironment             # Both
Remove-XDGVariables -FromProfile -FromEnvironment -Force      # No prompts
```

### Configuration Removal Functions

#### `Remove-NeovimConfig`
Remove Neovim configuration files from all locations.

**Parameters:**
- `-Force`: Suppress confirmation prompts

**Example:**
```powershell
Remove-NeovimConfig
```

**Locations Cleaned:**
- XDG_CONFIG_HOME/nvim
- LOCALAPPDATA/nvim
- XDG_DATA_HOME/nvim
- LOCALAPPDATA/nvim-data

#### `Remove-OhMyPoshTheme`
Remove Oh-My-Posh theme files.

**Parameters:**
- `-ThemeName`: Specific theme to remove (removes all custom themes if not specified)
- `-Force`: Suppress confirmation prompts

**Examples:**
```powershell
Remove-OhMyPoshTheme                              # All custom themes
Remove-OhMyPoshTheme -ThemeName "mytheme.omp.json"  # Specific theme
```

#### `Remove-WindowsTerminalSettings`
Remove Windows Terminal settings JSON file.

**Parameters:**
- `-Force`: Suppress confirmation prompts

**Warning:** This removes ALL Windows Terminal customizations.

**Example:**
```powershell
Remove-WindowsTerminalSettings
```

### Tool Uninstallation Functions

#### `Uninstall-Tools`
Uninstall development tools using winget.

**Parameters:**
- `-Tools`: Specific tools to uninstall (default: common tools)
- `-Keep`: Tools to keep even if in default list
- `-Force`: Suppress confirmation prompts

**Default Tools:**
- Microsoft.PowerShell
- Microsoft.WindowsTerminal
- Git.Git
- Neovim.Neovim
- JanDeDobbeleer.OhMyPosh
- Microsoft.VSCode
- GitHub.cli

**Examples:**
```powershell
Uninstall-Tools                                    # All default tools
Uninstall-Tools -Tools "Neovim.Neovim"             # Specific tool
Uninstall-Tools -Keep "Git.Git"                    # Keep Git
Uninstall-Tools -Force                             # No prompts
```

### Tracked Files Management

#### `Get-TrackedDotfiles`
Get list of files tracked by the dotfile repository.

**Returns:** String array of tracked file paths

**Example:**
```powershell
$files = Get-TrackedDotfiles
Write-Host "Found $($files.Count) tracked files"
```

#### `Backup-TrackedFiles`
Create a timestamped backup of all tracked files.

**Returns:** Path to backup directory

**Example:**
```powershell
$backupDir = Backup-TrackedFiles
Write-Host "Backup created at: $backupDir"
```

#### `Remove-TrackedFiles`
Remove all files tracked by the dotfile repository.

**Returns:** Number of files removed

**Example:**
```powershell
$removed = Remove-TrackedFiles
Write-Host "Removed $removed files"
```

### Backup Management Functions

#### `Get-UninstallBackupDir`
Get the uninstall backup directory path.

**Returns:** Path to backup root directory

**Example:**
```powershell
$backupDir = Get-UninstallBackupDir
Write-Host "Backups stored in: $backupDir"
```

#### `Remove-BackupFiles`
Remove old backup files.

**Parameters:**
- `-OlderThan`: Remove backups older than this date (default: 30 days)
- `-KeepCount`: Keep most recent N backups (alternative to OlderThan)
- `-Force`: Remove without confirmation

**Examples:**
```powershell
Remove-BackupFiles -OlderThan (Get-Date).AddDays(-30)  # Older than 30 days
Remove-BackupFiles -KeepCount 5                        # Keep 5 most recent
Remove-BackupFiles -KeepCount 3 -Force                 # Keep 3, no prompt
```

#### `Clear-UninstallBackups`
Remove ALL uninstall backups.

**Parameters:**
- `-Force`: Remove without confirmation

**Warning:** This removes all backups permanently.

**Example:**
```powershell
Clear-UninstallBackups          # Prompts first
Clear-UninstallBackups -Force   # No prompt
```

### Configuration Functions

#### `Get-UninstallConfig`
Get current uninstall configuration settings.

**Returns:** Hashtable with configuration

**Example:**
```powershell
$config = Get-UninstallConfig
Write-Host "DotDir: $($config.DotDir)"
Write-Host "AliasName: $($config.AliasName)"
```

**Configuration Keys:**
- `DotDir`: Dotfile repository path
- `WorkTree`: Working tree directory
- `AliasName`: Name of dot alias
- `BackupRoot`: Root backup directory
- `XDGConfigHome`: XDG config path
- `XDGDataHome`: XDG data path

#### `Set-UninstallConfig`
Set or update uninstall configuration.

**Parameters:**
- `-DotDir`: Dotfile repository directory
- `-WorkTree`: Working tree directory
- `-AliasName`: Alias name
- `-BackupRoot`: Backup root directory

**Example:**
```powershell
Set-UninstallConfig -DotDir "$env:USERPROFILE\.mydotfiles" -AliasName "dots"
```

## Usage Patterns

### Pattern 1: Interactive Uninstall
```powershell
Import-Module (Join-Path $PSScriptRoot 'modules\Uninstaller.psm1')

# Full uninstall with prompts at each step
Invoke-FullUninstall
```

### Pattern 2: Automated Uninstall
```powershell
Import-Module (Join-Path $PSScriptRoot 'modules\Uninstaller.psm1')

# Full uninstall without prompts
Invoke-FullUninstall -RemoveTools -Force
```

### Pattern 3: Dry Run Preview
```powershell
Import-Module (Join-Path $PSScriptRoot 'modules\Uninstaller.psm1')

# See what would be removed
Invoke-FullUninstall -DryRun

# Then execute for real
Invoke-FullUninstall
```

### Pattern 4: Selective Removal
```powershell
Import-Module (Join-Path $PSScriptRoot 'modules\Uninstaller.psm1')

# Remove only tracked files and repository
Invoke-CustomUninstall -RemoveTracked -RemoveRepo -BackupBeforeRemove -Force
```

### Pattern 5: Configuration Reset
```powershell
Import-Module (Join-Path $PSScriptRoot 'modules\Uninstaller.psm1')

# Remove configs, keep tools and data
Invoke-QuickUninstall -KeepNeovimConfig -KeepXDGVars -Force
```

### Pattern 6: Backup Management
```powershell
Import-Module (Join-Path $PSScriptRoot 'modules\Uninstaller.psm1')

# Keep only last 5 backups
Remove-BackupFiles -KeepCount 5 -Force

# Remove backups older than 90 days
Remove-BackupFiles -OlderThan (Get-Date).AddDays(-90) -Force

# View backup directory
$backupDir = Get-UninstallBackupDir
Get-ChildItem $backupDir | Sort-Object LastWriteTime -Descending
```

## Module Dependencies

The Uninstaller module requires:
- **Common.psm1**: Shared utility functions
- **PowerShell 7+**: For modern syntax and features
- **git**: For dotfile repository operations
- **winget**: For tool uninstallation (optional)

## Error Handling

All functions include comprehensive error handling:
- Try-catch blocks for file operations
- Clear error messages with context
- Graceful degradation when components are missing
- Return values for operation status checking

**Example:**
```powershell
$result = Remove-DotfileRepo -Force
if ($result) {
    Write-Host "Repository removed successfully"
} else {
    Write-Host "Failed to remove repository"
}
```

## Safety Features

1. **Automatic Backups**: Tracked files are backed up before removal
2. **Confirmation Prompts**: All destructive operations prompt by default
3. **Dry Run Mode**: Preview operations before executing
4. **Validation**: Checks for valid repositories and paths
5. **Rollback Safety**: Backups are preserved unless explicitly removed

## Best Practices

1. **Always Dry Run First**: Use `-DryRun` to preview changes
2. **Use -Force Carefully**: Only in scripts/automation, not interactively
3. **Keep Backups**: Don't remove backups until you're sure everything works
4. **Selective Removal**: Use custom uninstall for partial cleanup
5. **Check Return Values**: Verify operations succeeded

## Troubleshooting

### Repository Not Found
```
[WARN] Dotfile repository not found at: C:\Users\Username\.dotfile
```
**Solution**: Verify the dotfile repository exists or update config with `Set-UninstallConfig`

### Git Not Available
```
[ERROR] git command not found
```
**Solution**: Install Git or ensure it's in your PATH

### Winget Not Available
```
[ERROR] winget is not available. Cannot uninstall tools.
```
**Solution**: Install Windows Package Manager or skip `-RemoveTools`

### Permission Denied
```
[ERROR] Failed to remove file: Access to the path is denied
```
**Solution**: Run PowerShell as Administrator or check file permissions

## Integration with Scripts

### Standalone Uninstall Script
```powershell
#!/usr/bin/env pwsh
[CmdletBinding()]
param(
    [switch]$Force,
    [switch]$RemoveTools
)

Import-Module (Join-Path $PSScriptRoot '.config\powershell\modules\Uninstaller.psm1')

if ($RemoveTools) {
    Invoke-FullUninstall -RemoveTools -Force:$Force
} else {
    Invoke-QuickUninstall -Force:$Force
}
```

### Integration with install.ps1
```powershell
# In install.ps1
if ($Uninstall) {
    $uninstallModule = Join-Path $ScriptDir ".config\powershell\modules\Uninstaller.psm1"
    Import-Module $uninstallModule
    Invoke-QuickUninstall -Force
    exit 0
}
```

## Function List (19 total)

### Main Uninstall (3)
- `Invoke-FullUninstall`
- `Invoke-QuickUninstall`
- `Invoke-CustomUninstall`

### Core Removal (4)
- `Remove-DotfileRepo`
- `Remove-DotAlias`
- `Remove-PowerShellProfileConfig`
- `Remove-XDGVariables`

### Configuration Removal (3)
- `Remove-NeovimConfig`
- `Remove-OhMyPoshTheme`
- `Remove-WindowsTerminalSettings`

### Tools (1)
- `Uninstall-Tools`

### Tracked Files (3)
- `Get-TrackedDotfiles`
- `Backup-TrackedFiles`
- `Remove-TrackedFiles`

### Backup Management (3)
- `Get-UninstallBackupDir`
- `Remove-BackupFiles`
- `Clear-UninstallBackups`

### Configuration (2)
- `Get-UninstallConfig`
- `Set-UninstallConfig`

## Help
```powershell
Import-Module '.\modules\Uninstaller.psm1'

# Get function help
Get-Help Invoke-FullUninstall -Full
Get-Help Remove-DotfileRepo -Examples
Get-Help Uninstall-Tools -Parameter Tools

# List all functions
Get-Command -Module Uninstaller

# View module info
Get-Module Uninstaller
```

## Stats
- 19 exported functions
- 1,440 lines of well-documented code
- Consolidates uninstall logic from multiple scripts
- Supports 3 uninstall modes (Full, Quick, Custom)
- Comprehensive backup and restore functionality
- Full parameter validation and error handling
- Dry run and force modes supported
