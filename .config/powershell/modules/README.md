# Common PowerShell Module

A comprehensive utility module that eliminates boilerplate code across all PowerShell scripts in the dotfile repository.

## Overview

The `Common.psm1` module consolidates 30+ lines of repeated code into a single, well-documented module. It provides:

- **Color-coded output functions** - Consistent, readable console output
- **Validation functions** - Check admin privileges, PowerShell version, command availability
- **XDG base directory support** - Cross-platform configuration paths
- **Backup functionality** - Timestamped file and directory backups
- **Error handling patterns** - Standardized try/catch with logging
- **User interaction** - Confirmation prompts with -Force support
- **Path utilities** - Safe path resolution, relative paths, temp directories
- **Logging functions** - File-based logging with severity levels

## Installation

The module is located at:
```
D:\develop\dotfile\.config\powershell\modules\Common.psm1
```

## Quick Start

```powershell
# Import the module
Import-Module (Join-Path $PSScriptRoot 'modules\Common.psm1')

# Use the functions
Write-SectionHeader "My Script"
Write-Info "Starting operation..."
Write-Success "Operation completed!"

# Validate prerequisites
if (-not (Test-Administrator)) {
    Write-ErrorCustom "This script requires administrator privileges"
    exit 1
}

# Handle errors gracefully
$result = Invoke-CommandWithErrorHandling {
    Copy-Item $source $destination
} -ErrorMessage "Failed to copy file" -SuccessMessage "File copied successfully"
```

## Function Reference

### Output Functions

#### `Write-Info`
Write informational messages in cyan.

```powershell
Write-Info "Processing file..."
Write-Info "Plain message" -NoPrefix  # Without [INFO] prefix
```

#### `Write-Success`
Write success messages in green.

```powershell
Write-Success "Installation completed!"
Write-Success "Done!" -NoPrefix
```

#### `Write-WarningCustom`
Write warning messages in yellow.

```powershell
Write-WarningCustom "Configuration file not found, using defaults"
```

#### `Write-ErrorCustom`
Write error messages in red.

```powershell
Write-ErrorCustom "Failed to connect to server"
```

#### `Write-SectionHeader`
Display a section header for grouping related operations.

```powershell
Write-SectionHeader "Installing Tools"
Write-SectionHeader "Configuration" -Character "-" -Width 50
```

#### `Write-SectionComplete`
Display a completion message.

```powershell
Write-SectionComplete "Tools installation completed"
```

### Validation Functions

#### `Test-Administrator`
Check if running with administrator privileges.

```powershell
if (Test-Administrator) {
    Write-Success "Running as admin"
} else {
    Write-WarningCustom "Not running as admin"
}
```

#### `Test-PowerShellVersion`
Check PowerShell version meets requirements.

```powershell
if (-not (Test-PowerShellVersion -MinimumVersion 7.0)) {
    Write-ErrorCustom "PowerShell 7+ required"
    exit 1
}

# Warn only, don't fail
Test-PowerShellVersion -MinimumVersion 7.2 -WarnOnly
```

#### `Test-CommandAvailable`
Check if a command is available in PATH.

```powershell
if (Test-CommandAvailable "git") {
    Write-Success "Git is installed"
} else {
    Write-WarningCustom "Git not found"
}
```

### XDG Base Directory Support

The module provides XDG Base Directory specification support for Windows:

- `XDG_CONFIG_HOME` → Default: `%USERPROFILE%\.local\config`
- `XDG_DATA_HOME` → Default: `%USERPROFILE%\.local\data`

#### `Get-XDGConfigPath`
Get XDG config directory path.

```powershell
$nvimConfig = Get-XDGConfigPath "nvim"
# Returns: C:\Users\Username\.local\config\nvim

$configHome = Get-XDGConfigPath
# Returns: C:\Users\Username\.local\config
```

#### `Get-XDGDataPath`
Get XDG data directory path.

```powershell
$vimData = Get-XDGDataPath "vim-data"
# Returns: C:\Users\Username\.local\data\vim-data
```

#### `Initialize-XDGPaths`
Initialize XDG directories and optionally set environment variables.

```powershell
# Create directories if they don't exist
Initialize-XDGPaths

# Create and set environment variables for current session
Initialize-XDGPaths -SetEnvironment

Write-Info "XDG_CONFIG_HOME: $env:XDG_CONFIG_HOME"
Write-Info "XDG_DATA_HOME: $env:XDG_DATA_HOME"
```

### Backup Functions

#### `Backup-File`
Create timestamped backup of a file.

```powershell
# Backup to same directory
$backup = Backup-File "C:\Users\Username\.gitconfig"
# Creates: C:\Users\Username\.gitconfig.backup_20250106_143022

# Backup to specific directory
$backup = Backup-File "C:\Users\Username\.gitconfig" -BackupDirectory "C:\Backups"
# Creates: C:\Backups\.gitconfig.backup_20250106_143022
```

#### `Backup-Directory`
Create timestamped backup of a directory.

```powershell
# Backup to parent directory
$backup = Backup-Directory "C:\Users\Username\.vim"
# Creates: C:\Users\Username\.vim.backup_20250106_143022

# Backup to specific location
$backup = Backup-Directory "C:\Users\Username\.vim" -BackupRootDirectory "C:\Backups"
# Creates: C:\Backups\.vim.backup_20250106_143022

# Include directory name in backup
$backup = Backup-Directory "C:\Users\Username\.vim" -IncludePathInName
# Creates: C:\Users\Username\.vim.backup_20250106_143022
```

### Error Handling Functions

#### `Invoke-CommandWithErrorHandling`
Execute script block with standardized error handling.

```powershell
# Basic usage
$result = Invoke-CommandWithErrorHandling {
    Copy-Item $source $destination
} -ErrorMessage "Failed to copy file"

if ($result) {
    Write-Success "File copied"
}

# With success message
Invoke-CommandWithErrorHandling {
    Install-Module MyModule
} -ErrorMessage "Installation failed" -SuccessMessage "Module installed"

# With return output
$date = Invoke-CommandWithErrorHandling {
    Get-Date
} -ErrorMessage "Failed to get date" -ReturnOutput

# Throw on error
Invoke-CommandWithErrorHandling {
    & installer.exe
} -ErrorMessage "Installation failed" -ThrowOnError
```

### User Interaction Functions

#### `Confirm-Action`
Prompt user for confirmation with -Force support.

```powershell
# Simple confirmation
if (Confirm-Action "Delete all backups?") {
    Remove-Item $backupPath -Recurse
}

# Default to Yes
if (Confirm-Action "Continue?" -DefaultToYes) {
    # Continue
}

# Using -Force flag (for automation/silent scripts)
$global:Force = $true
if (Confirm-Action "This will be auto-confirmed") {
    # Automatically confirmed
}
```

### Path Utility Functions

#### `New-TemporaryDirectory`
Create a temporary directory.

```powershell
# Create in system temp
$tempDir = New-TemporaryDirectory
# Creates: C:\Users\Username\AppData\Local\Temp\tmp-20250106143022-1234

# With custom prefix
$tempDir = New-TemporaryDirectory -Prefix "myscript"

# In specific base path
$tempDir = New-TemporaryDirectory -BasePath "C:\Temp"

# Use it
Copy-Item $source $tempDir

# Cleanup when done
Remove-Item $tempDir -Recurse
```

#### `Get-RelativePath`
Calculate relative path from base to target.

```powershell
$relative = Get-RelativePath "C:\Users\Username" "C:\Users\Username\.config\nvim"
# Returns: .config\nvim

$relative = Get-RelativePath "C:\Project" "C:\Project\src\main.ts"
# Returns: src\main.ts
```

#### `Resolve-PathSafely`
Resolve path without throwing errors.

```powershell
# Returns resolved path or null (not error)
$resolved = Resolve-PathSafely "C:\Windows"
if ($resolved) {
    Write-Success "Found: $resolved"
}

$notFound = Resolve-PathSafely "C:\Nonexistent"
if ($null -eq $notFound) {
    Write-WarningCustom "Path doesn't exist"
}

# Resolve relative path from base
$resolved = Resolve-PathSafely "config.json" -RelativeToBase "C:\MyApp"
```

### Logging Functions

#### `Initialize-Logging`
Initialize file-based logging.

```powershell
# Initialize with default settings
$logFile = Initialize-Logging -LogName "MyScript"
# Creates: C:\Users\Username\.dotfile\logs\MyScript_20250106.log

# Custom directory
$logFile = Initialize-Logging -LogDirectory "C:\Logs" -LogName "Install"

# With log level
$logFile = Initialize-Logging -Level Debug

# Without date in filename
$logFile = Initialize-Logging -IncludeDateInName:$false
```

#### `Write-Log`
Write timestamped message to log file.

```powershell
# Basic logging
Write-Log "Script started" -LogFile $logFile -Level Info
Write-Log "Warning detected" -LogFile $logFile -Level Warning
Write-Log "Operation failed" -LogFile $logFile -Level Error

# Log to file and console
Write-Log "Important message" -LogFile $logFile -Level Info -PassThru
```

## Script Template

Here's a complete template showing best practices:

```powershell
<#
.SYNOPSIS
    Short description of your script.

.DESCRIPTION
    Detailed description of what your script does.

.EXAMPLE
    .\MyScript.ps1 -Force -Verbose
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [switch]$Force,
    [string]$ConfigPath
)

# Import Common module
Import-Module (Join-Path $PSScriptRoot 'modules\Common.psm1')

# Set global Force flag for Confirm-Action
$global:Force = $Force

# Initialize logging
$logFile = Initialize-Logging -LogName "MyScript"
Write-Log "Script started" -LogFile $logFile -Level Info

# Validate prerequisites
Write-SectionHeader "Validating Prerequisites"

if (-not (Test-PowerShellVersion -MinimumVersion 7.0)) {
    Write-Log "PowerShell version check failed" -LogFile $logFile -Level Error
    return 1
}

if (-not (Test-CommandAvailable "git")) {
    Write-Log "Git not found" -LogFile $logFile -Level Error
    Write-ErrorCustom "Git is required"
    return 1
}

Write-Success "Prerequisites validated"
Write-Log "Prerequisites validated" -LogFile $logFile -Level Info

# Main operation
Write-SectionHeader "Main Operation"

$result = Invoke-CommandWithErrorHandling {
    # Your main logic here
    Write-Info "Processing..."

    # Use XDG paths for cross-platform compatibility
    $configPath = Get-XDGConfigPath "myapp"
    Initialize-XDGPaths -SetEnvironment

    # Backup existing config if it exists
    if (Test-Path $configPath) {
        Write-Info "Backing up existing configuration..."
        Backup-Directory $configPath | Out-Null
        Write-Log "Configuration backed up" -LogFile $logFile -Level Info
    }

    # Confirm action
    if (-not (Confirm-Action "Continue with installation?")) {
        Write-Info "Installation cancelled by user"
        return $false
    }

    # Continue with your logic...
    Write-Info "Installing application..."

    return $true

} -ErrorMessage "Operation failed" -SuccessMessage "Operation completed successfully"

# Cleanup and exit
Write-SectionHeader "Cleanup"

if ($result) {
    Write-Success "Script completed successfully"
    Write-Log "Script completed successfully" -LogFile $logFile -Level Info
    return 0
} else {
    Write-ErrorCustom "Script failed"
    Write-Log "Script failed" -LogFile $logFile -Level Error
    return 1
}
```

## Migration Guide

### Before (Boilerplate Code)

```powershell
# Old way - 30+ lines of boilerplate
function Write-Info {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor Cyan
}

function Write-Success {
    param([string]$Message)
    Write-Host "[SUCCESS] $Message" -ForegroundColor Green
}

function Write-Warning {
    param([string]$Message)
    Write-Host "[WARN] $Message" -ForegroundColor Yellow
}

function Write-Error {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
}

$currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
$isAdmin = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

# ... and so on
```

### After (Using Common Module)

```powershell
# New way - 1 line
Import-Module (Join-Path $PSScriptRoot 'modules\Common.psm1')

# All functions available immediately
Write-Info "Starting..."
if (Test-Administrator) {
    Write-Success "Running as admin"
}
```

## Examples

See `Common-Examples.ps1` for comprehensive examples of all functions:

```powershell
# Run all examples
.\Common-Examples.ps1

# Run specific example
.\Common-Examples.ps1 -Example XDG
```

## Benefits

1. **Reduced Boilerplate** - Eliminate 30+ lines of repeated code
2. **Consistency** - All scripts use the same functions and patterns
3. **Maintainability** - Update once, applies to all scripts
4. **Documentation** - Comprehensive help for each function
5. **Best Practices** - Built-in error handling, logging, validation
6. **Cross-Platform** - XDG support for Windows/Linux compatibility

## Related Files

- `Common.psm1` - Main module
- `Common-Examples.ps1` - Usage examples
- `UI.psm1` - Legacy UI functions (being phased out)
- `ToolInstaller.psm1` - Uses Common module
- `ConfigDeployer.psm1` - Uses Common module
- `Verifier.psm1` - Uses Common module
- `DotfileInstaller.psm1` - Uses Common module

## Contributing

When adding new functions to Common.psm1:

1. Add comprehensive comment-based help
2. Include examples in the help
3. Add usage example to Common-Examples.ps1
4. Update this README
5. Export the function in Export-ModuleMember

## License

Part of the dotfile repository. See root LICENSE file for details.
