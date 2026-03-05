# Config.psm1 - Configuration Module

## Overview

The **Config.psm1** module serves as the single source of truth for all configuration data in the dotfile management system. It centralizes:

- Tool definitions (Git, Node.js, Neovim, PowerShell, etc.)
- Download URLs and installation parameters
- PowerShell modules with versions
- Configuration file paths and templates
- XDG Base Directory configuration
- Offline deployment settings
- Color scheme and UI configuration
- Validation rules and requirements

## Why Centralized Configuration?

**Before:** Configuration data was scattered across multiple modules:
- `ToolInstaller.psm1`: Winget IDs hardcoded
- `UI.psm1`: Manual download URLs hardcoded
- `DotfileInstaller.psm1`: Repository URL hardcoded
- `Package-Offline-Installer.ps1`: All tool definitions duplicated

**After:** All configuration data in one place:
- Update a tool version? Edit one location
- Add a new tool? Add to `Get-ToolDefinitions`
- Change paths? Update `Get-ConfigurationPaths`

## Quick Start

```powershell
# Import the module
Import-Module Config.psm1

# Get all tool definitions
$tools = Get-ToolDefinitions
$gitConfig = $tools.Git

# Get configuration paths
$paths = Get-ConfigurationPaths
$nvimConfig = $paths.NeovimConfig

# Get XDG paths
$xdg = Get-XDGConfiguration
$nvimData = $xdg.NeovimDataPath
```

## Available Functions

### Tool Configuration

#### `Get-ToolDefinitions`
Returns all tool definitions with properties like Name, WingetId, MinVersion, DownloadUrl, etc.

```powershell
$tools = Get-ToolDefinitions
foreach ($tool in $tools.Values) {
    Write-Host "$($tool.Name) - $($tool.DisplayName)"
}
```

**Tool Properties:**
- `Name` - Internal identifier (e.g., "Git", "NodeJS")
- `DisplayName` - Human-readable name
- `WingetId` - Package ID for winget
- `MinVersion` - Minimum required version
- `Command` - CLI command to verify installation
- `DownloadUrl` - Manual installation URL
- `Required` - Whether tool is required or optional
- `Category` - Tool category (Development, System, Productivity)
- `Dependencies` - List of required runtimes
- `InstallScript` - Installation command

#### `Get-ModuleDefinitions`
Returns PowerShell module definitions.

```powershell
$modules = Get-ModuleDefinitions
foreach ($module in $modules.Values) {
    Write-Host "$($module.Name) v$($module.MinVersion)"
}
```

#### `Get-RuntimeDefinitions`
Returns runtime dependencies (VC++ Redistributables).

### Path Configuration

#### `Get-DotfileConfiguration`
Returns dotfile repository settings.

```powershell
$dotfile = Get-DotfileConfiguration
Write-Host "Repository: $($dotfile.RepoUrl)"
Write-Host "Local path: $($dotfile.DotDir)"
```

#### `Get-XDGConfiguration`
Returns XDG Base Directory paths for Windows.

```powershell
$xdg = Get-XDGConfiguration
Write-Host "Config: $($xdg.ConfigHome)"
Write-Host "Data: $($xdg.DataHome)"
Write-Host "Neovim: $($xdg.NeovimConfigPath)"
```

**XDG Paths:**
- `ConfigHome` - User config files (default: `$USERPROFILE\.local\config`)
- `DataHome` - User data files (default: `$USERPROFILE\.local\data`)
- `StateHome` - User state files (default: `$USERPROFILE\.local\state`)
- `CacheHome` - User cache files (default: `$USERPROFILE\.cache`)
- `NeovimConfigPath` - Neovim configuration directory
- `NeovimDataPath` - Neovim data directory
- `VimRuntimePath` - Vim runtime files

#### `Get-ConfigurationPaths`
Returns all configuration file paths.

```powershell
$paths = Get-ConfigurationPaths
Write-Host "PowerShell: $($paths.PowerShellProfile)"
Write-Host "Neovim: $($paths.NeovimConfig)"
Write-Host "Windows Terminal: $($paths.WindowsTerminalSettings)"
```

### Deployment Configuration

#### `Get-OfflineDeploymentConfiguration`
Returns settings for offline deployment packages.

```powershell
$offline = Get-OfflineDeploymentConfiguration
Write-Host "Output dir: $($offline.OutputDir)"
Write-Host "Package name: $($offline.PackageName)"
```

#### `Get-OneClickInstallConfiguration`
Returns one-click installation settings.

```powershell
$oneclick = Get-OneClickInstallConfiguration
Write-Host "Install script: $($oneclick.InstallScriptUrl)"
```

### UI Configuration

#### `Get-UIConfiguration`
Returns color schemes and UI settings.

```powershell
$ui = Get-UIConfiguration
$color = $ui.Colors.Success # "Green"
Write-Host "Success message" -ForegroundColor $color
```

#### `Get-ManualInstallationUrls`
Returns manual download URLs.

```powershell
$urls = Get-ManualInstallationUrls
Write-Host "Git: $($urls.Git)"
Write-Host "Node.js: $($urls.Node)"
```

### System Configuration

#### `Get-ValidationRules`
Returns system requirements and validation rules.

```powershell
$rules = Get-ValidationRules
Write-Host "Min PowerShell: $($rules.MinPowerShellVersion)"
Write-Host "Require winget: $($rules.RequireWinget)"
```

#### `Get-LoggingConfiguration`
Returns logging and debugging settings.

```powershell
$logging = Get-LoggingConfiguration
Write-Host "Log dir: $($logging.LogDirectory)"
Write-Host "Max age: $($logging.MaxLogAgeDays) days"
```

### Utility Functions

#### `Get-AllConfiguration`
Returns complete configuration as one object.

```powershell
$config = Get-AllConfiguration
$config.Tools.Git.DisplayName
$config.Paths.PowerShellProfile
$config.ValidationRules.MinPowerShellVersion
```

#### `Export-ConfigurationToJson`
Exports configuration to JSON file.

```powershell
Export-ConfigurationToJson -OutputPath "config-backup.json"
Export-ConfigurationToJson -OutputPath "config-min.json" -PrettyPrint:$false
```

#### `Test-ConfigurationIntegrity`
Validates configuration data.

```powershell
$valid = Test-ConfigurationIntegrity
if ($valid) {
    Write-Host "Configuration is valid"
}
```

#### `Show-ConfigurationHelp`
Displays help information.

```powershell
Show-ConfigurationHelp
```

## Configuration Data Structure

### Tool Definition Example

```powershell
Git = @{
    Name                = "Git"
    DisplayName         = "Git for Windows"
    WingetId            = "Git.Git"
    MinVersion          = "2.40.0"
    Command             = "git"
    DownloadUrl         = "https://git-scm.com/download/win"
    InstallerArgs       = @("/SILENT")
    Required            = $true
    Category            = "Development"
    Dependencies        = @()
    InstallScript       = "winget install --id Git.Git ..."
    VerificationCommand = "git --version"
    Description         = "Distributed version control system"
}
```

### Module Definition Example

```powershell
PSReadLine = @{
    Name        = "PSReadLine"
    MinVersion  = "2.2.0"
    Required    = $true
    Description = "Improved command-line editing experience"
    ImportName  = "PSReadLine"
}
```

## Usage Examples

### Example 1: Get All Required Tools

```powershell
$tools = Get-ToolDefinitions
$requiredTools = $tools.GetEnumerator() | Where-Object { $_.Value.Required -eq $true }

foreach ($tool in $requiredTools) {
    Write-Host "$($tool.Value.DisplayName) - $($tool.Value.WingetId)"
}
```

### Example 2: Verify Tool Installation

```powershell
$tools = Get-ToolDefinitions

foreach ($tool in $tools.Values) {
    if ($tool.Command) {
        $installed = Get-Command $tool.Command -ErrorAction SilentlyContinue
        $status = if ($installed) { "Installed" } else { "Not installed" }
        Write-Host "$($tool.Name): $status"
    }
}
```

### Example 3: Create Custom Tool Installer

```powershell
Import-Module Config.psm1

function Install-ToolByName {
    param([string]$ToolName)

    $tools = Get-ToolDefinitions
    $tool = $tools[$ToolName]

    if (-not $tool) {
        Write-Error "Tool '$ToolName' not found in configuration"
        return
    }

    Write-Host "Installing $($tool.DisplayName)..."
    Invoke-Expression $tool.InstallScript
}

# Usage
Install-ToolByName "Git"
Install-ToolByName "Neovim"
```

### Example 4: Generate Installation Report

```powershell
Import-Module Config.psm1

$tools = Get-ToolDefinitions
$report = @()

foreach ($tool in $tools.Values) {
    $installed = if ($tool.Command) {
        $null -ne (Get-Command $tool.Command -ErrorAction SilentlyContinue)
    } else { $false }

    $report += [PSCustomObject]@{
        Tool      = $tool.DisplayName
        Required  = $tool.Required
        Installed = $installed
        Version   = if ($installed) { & $tool.Command --version } else { "N/A" }
    }
}

$report | Format-Table -AutoSize
```

### Example 5: Export and Import Configuration

```powershell
# Export configuration
Export-ConfigurationToJson -OutputPath "my-config.json"

# Import and use
$config = Get-Content "my-config.json" | ConvertFrom-Json
$tools = $config.Tools.PSObject.Properties | ForEach-Object {
    [PSCustomObject]$_.Value
}
```

## Migrating from Hardcoded Values

### Before (in ToolInstaller.psm1)

```powershell
function Install-Git {
    Install-Package -PackageName "Git" -WingetId "Git.Git" -Required
}
```

### After (using Config.psm1)

```powershell
Import-Module Config.psm1

function Install-Git {
    $tools = Get-ToolDefinitions
    $git = $tools.Git

    Install-Package -PackageName $git.Name -WingetId $git.WingetId -Required:$git.Required
}
```

## Best Practices

1. **Always Import Config First**
   ```powershell
   Import-Module (Join-Path $PSScriptRoot 'Config.psm1')
   Import-Module (Join-Path $PSScriptRoot 'UI.psm1')
   ```

2. **Don't Hardcode Values**
   ```powershell
   # Bad
   $gitUrl = "https://git-scm.com/download/win"

   # Good
   $urls = Get-ManualInstallationUrls
   $gitUrl = $urls.Git
   ```

3. **Use Validation Rules**
   ```powershell
   $rules = Get-ValidationRules
   if ($PSVersionTable.PSVersion -lt $rules.MinPowerShellVersion) {
       Write-Error "PowerShell version too old"
   }
   ```

4. **Export Before Changes**
   ```powershell
   # Backup current configuration
   Export-ConfigurationToJson -OutputPath "config-before-change.json"

   # Make changes...

   # Validate
   Test-ConfigurationIntegrity
   ```

## Updating Configuration

### Adding a New Tool

```powershell
# Edit Config.psm1
function Get-ToolDefinitions {
    return @{
        # ... existing tools ...

        MyNewTool = @{
            Name                = "MyNewTool"
            DisplayName         = "My New Tool"
            WingetId            = "Publisher.MyNewTool"
            MinVersion          = "1.0.0"
            Command             = "mynewtool"
            DownloadUrl         = "https://example.com/download"
            Required            = $false
            Category            = "Development"
            Dependencies        = @()
            InstallScript       = "winget install --id Publisher.MyNewTool ..."
            Description         = "My new development tool"
        }
    }
}
```

### Updating Tool Versions

```powershell
# Edit Config.psm1
Git = @{
    MinVersion = "2.42.0"  # Update from 2.40.0
    # ... rest of properties ...
}
```

## Testing

```powershell
# Import and validate
Import-Module Config.psm1 -Force

# Test integrity
Test-ConfigurationIntegrity

# View all tools
$tools = Get-ToolDefinitions
$tools.Keys | ForEach-Object { Write-Host $_ }

# Export and inspect
Export-ConfigurationToJson -OutputPath "test-export.json"
Get-Content "test-export.json" | ConvertFrom-Json
```

## Related Modules

The Config module is used by:
- `ToolInstaller.psm1` - Tool installation functions
- `DotfileInstaller.psm1` - Dotfile deployment
- `ConfigDeployer.psm1` - Configuration deployment
- `Verifier.psm1` - Verification functions
- `UI.psm1` - User interface functions

## Troubleshooting

### Module Not Found
```powershell
# Use full path
Import-Module "D:\develop\dotfile\.config\powershell\modules\Config.psm1"

# Or add to module path
$env:PSModulePath += ";D:\develop\dotfile\.config\powershell\modules"
```

### Configuration Validation Failed
```powershell
# Check for missing required fields
Test-ConfigurationIntegrity -Verbose

# Export and inspect
Export-ConfigurationToJson -OutputPath "debug-config.json"
```

## Version History

- **1.0.0** (2025-01-06) - Initial release with centralized configuration

## Contributing

When adding new configuration:
1. Add to appropriate getter function
2. Include all required properties
3. Update this documentation
4. Run `Test-ConfigurationIntegrity`
5. Export JSON to verify structure
