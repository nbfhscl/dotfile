# Uninstaller.psm1 Quick Reference Card

## Import
```powershell
Import-Module (Join-Path $PSScriptRoot 'modules\Uninstaller.psm1')
```

## Main Uninstall Functions
```powershell
# Full uninstall (everything)
Invoke-FullUninstall                              # Keep tools
Invoke-FullUninstall -RemoveTools                 # Remove tools too
Invoke-FullUninstall -RemoveTools -Force          # No prompts
Invoke-FullUninstall -DryRun                      # Preview only

# Quick uninstall (configs only, keep tools)
Invoke-QuickUninstall                             # Remove all configs
Invoke-QuickUninstall -KeepNeovimConfig           # Keep Neovim
Invoke-QuickUninstall -KeepNeovimConfig -KeepPoshTheme -KeepXDGVars

# Custom uninstall (selective removal)
Invoke-CustomUninstall -RemoveRepo -RemoveAlias -RemoveTracked
Invoke-CustomUninstall -RemoveNeovim -RemovePoshTheme -RemoveXDG
```

## Core Removal Functions
```powershell
Remove-DotfileRepo                                # Remove repository
Remove-DotfileRepo -Force

Remove-DotAlias                                   # Remove from profiles
Remove-DotAlias -AllProfiles -Force
Remove-DotAlias -ProfilePath $PROFILE

Remove-PowerShellProfileConfig                    # Clean profiles
Remove-PowerShellProfileConfig -Force

Remove-XDGVariables -FromProfile                  # Remove XDG vars
Remove-XDGVariables -FromProfile -FromEnvironment  # + system env
Remove-XDGVariables -FromProfile -FromEnvironment -Force
```

## Configuration Removal
```powershell
Remove-NeovimConfig                               # Remove Neovim
Remove-NeovimConfig -Force

Remove-OhMyPoshTheme                              # Remove all custom themes
Remove-OhMyPoshTheme -ThemeName "mytheme.omp.json"
Remove-OhMyPoshTheme -Force

Remove-WindowsTerminalSettings                    # Remove settings
Remove-WindowsTerminalSettings -Force
```

## Tool Uninstallation
```powershell
Uninstall-Tools                                   # All default tools
Uninstall-Tools -Tools "Neovim.Neovim"            # Specific tool
Uninstall-Tools -Keep "Git.Git"                   # Keep Git
Uninstall-Tools -Force                            # No prompts

# Default tools removed:
# Microsoft.PowerShell, Microsoft.WindowsTerminal, Git.Git,
# Neovim.Neovim, JanDeDobbeleer.OhMyPosh,
# Microsoft.VSCode, GitHub.cli
```

## Tracked Files Management
```powershell
$files = Get-TrackedDotfiles                      # List tracked files
$backupDir = Backup-TrackedFiles                  # Backup all tracked
$removed = Remove-TrackedFiles                    # Remove all tracked
```

## Backup Management
```powershell
$backupDir = Get-UninstallBackupDir               # Get backup path

Remove-BackupFiles -OlderThan (Get-Date).AddDays(-30)  # Older than 30 days
Remove-BackupFiles -KeepCount 5                        # Keep 5 most recent
Remove-BackupFiles -KeepCount 3 -Force                 # Keep 3, no prompt

Clear-UninstallBackups                            # Remove ALL backups
Clear-UninstallBackups -Force                     # No prompt
```

## Configuration
```powershell
$config = Get-UninstallConfig                     # View config
Set-UninstallConfig -DotDir "$env:USERPROFILE\.mydotfiles"
Set-UninstallConfig -AliasName "dots"

# Config keys:
# DotDir, WorkTree, AliasName, BackupRoot,
# XDGConfigHome, XDGDataHome
```

## Common Usage Patterns

### Interactive Uninstall
```powershell
Import-Module (Join-Path $PSScriptRoot 'modules\Uninstaller.psm1')
Invoke-FullUninstall  # Prompts at each step
```

### Automated Uninstall
```powershell
Import-Module (Join-Path $PSScriptRoot 'modules\Uninstaller.psm1')
Invoke-FullUninstall -RemoveTools -Force  # No prompts
```

### Dry Run Preview
```powershell
Import-Module (Join-Path $PSScriptRoot 'modules\Uninstaller.psm1')
Invoke-FullUninstall -DryRun  # Preview only
```

### Selective Removal
```powershell
Import-Module (Join-Path $PSScriptRoot 'modules\Uninstaller.psm1')
Invoke-CustomUninstall -RemoveTracked -RemoveRepo -Force
```

### Configuration Reset
```powershell
Import-Module (Join-Path $PSScriptRoot 'modules\Uninstaller.psm1')
Invoke-QuickUninstall -KeepNeovimConfig -KeepXDGVars -Force
```

### Backup Management
```powershell
Import-Module (Join-Path $PSScriptRoot 'modules\Uninstaller.psm1')
Remove-BackupFiles -KeepCount 5 -Force
$backupDir = Get-UninstallBackupDir
Get-ChildItem $backupDir | Sort-Object LastWriteTime -Descending
```

## Uninstall Modes Comparison

| Mode | Removes Config | Removes Repo | Removes Tools | Backups First |
|------|----------------|--------------|---------------|---------------|
| Full | ✓ | ✓ | Optional | ✓ |
| Quick | ✓ | ✓ | ✗ | ✓ |
| Custom | Selective | Selective | Selective | Optional |

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

## Common Parameters

### `-Force`
Suppress confirmation prompts (use in scripts/automation)
```powershell
Invoke-FullUninstall -Force
```

### `-DryRun`
Show what would be done without executing
```powershell
Invoke-FullUninstall -DryRun
```

### `-RemoveTools`
Also remove tools installed via winget
```powershell
Invoke-FullUninstall -RemoveTools
```

## Safety Features

1. **Automatic Backups**: Tracked files backed up before removal
2. **Confirmation Prompts**: All operations prompt by default
3. **Dry Run Mode**: Preview operations before executing
4. **Validation**: Checks for valid repos and paths
5. **Rollback Safety**: Backups preserved unless explicitly removed

## Help
```powershell
Import-Module '.\modules\Uninstaller.psm1'
Get-Help Invoke-FullUninstall -Full
Get-Help Remove-DotfileRepo -Examples
Get-Help Uninstall-Tools -Parameter Tools
Get-Command -Module Uninstaller
```

## Files
- `Uninstaller.psm1` - Main module
- `Uninstaller-README.md` - Full documentation
- `Uninstaller-QUICK-REF.md` - This file

## Stats
- 19 exported functions
- 1,440 lines of code
- 3 uninstall modes (Full, Quick, Custom)
- Comprehensive backup management
- Dry run and force support
- Full parameter validation
