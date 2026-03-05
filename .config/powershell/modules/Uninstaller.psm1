# ============================================
# Uninstaller Module - Dotfile Uninstallation Functions
# ============================================

<#
.SYNOPSIS
    Provides consolidated uninstallation functionality for dotfile configurations.

.DESCRIPTION
    This module handles complete or partial removal of dotfile configurations including:
    - Bare dotfile repository and 'dot' command alias
    - PowerShell profile modifications
    - XDG environment variables
    - Neovim configurations
    - Oh-My-Posh themes
    - Windows Terminal settings
    - Installed tools (via winget)
    - Backup management

    The module supports both full uninstall (everything) and quick uninstall (configurations only, keeping tools).

    UNINSTALL MODES:
    - FullUninstall: Removes everything including tools installed via winget
    - QuickUninstall: Removes configurations only, keeps tools
    - CustomUninstall: Selective removal based on parameters

.EXPORTED FUNCTIONS
    Invoke-FullUninstall, Invoke-QuickUninstall, Invoke-CustomUninstall,
    Remove-DotfileRepo, Remove-DotAlias, Remove-PowerShellProfileConfig,
    Remove-XDGVariables, Remove-NeovimConfig, Remove-OhMyPoshTheme,
    Remove-WindowsTerminalSettings, Uninstall-Tools, Remove-BackupFiles,
    Get-TrackedDotfiles, Backup-TrackedFiles, Remove-TrackedFiles,
    Get-UninstallBackupDir, Clear-UninstallBackups
#>

# Import Common module for utilities
Import-Module (Join-Path $PSScriptRoot 'Common.psm1') -ErrorAction SilentlyContinue

# ============================================
# Configuration Variables
# ============================================

$script:UninstallConfig = @{
    DotDir        = "$env:USERPROFILE\.dotfile"
    WorkTree      = $env:USERPROFILE
    AliasName     = "dot"
    BackupRoot    = "$env:USERPROFILE\.dotfile_uninstall_backups"
    XDGConfigHome = if ($env:XDG_CONFIG_HOME) { $env:XDG_CONFIG_HOME } else { Join-Path $env:USERPROFILE ".local\config" }
    XDGDataHome   = if ($env:XDG_DATA_HOME) { $env:XDG_DATA_HOME } else { Join-Path $env:USERPROFILE ".local\data" }
}

<#
.SYNOPSIS
    Get the uninstall configuration.

.DESCRIPTION
    Returns the current uninstall configuration settings.

.EXAMPLE
    Get-UninstallConfig
#>
function Get-UninstallConfig {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param()

    return $script:UninstallConfig.Clone()
}

<#
.SYNOPSIS
    Set or update uninstall configuration.

.PARAMETER DotDir
    The dotfile repository directory.

.PARAMETER WorkTree
    The working tree directory (default: $env:USERPROFILE).

.PARAMETER AliasName
    The name of the dot alias (default: "dot").

.PARAMETER BackupRoot
    Root directory for uninstall backups.

.EXAMPLE
    Set-UninstallConfig -DotDir "$env:USERPROFILE\.mydotfiles"
#>
function Set-UninstallConfig {
    [CmdletBinding()]
    param(
        [string]$DotDir,
        [string]$WorkTree,
        [string]$AliasName,
        [string]$BackupRoot
    )

    if ($DotDir) { $script:UninstallConfig.DotDir = $DotDir }
    if ($WorkTree) { $script:UninstallConfig.WorkTree = $WorkTree }
    if ($AliasName) { $script:UninstallConfig.AliasName = $AliasName }
    if ($BackupRoot) { $script:UninstallConfig.BackupRoot = $BackupRoot }
}

# ============================================
# Main Uninstall Functions
# ============================================

<#
.SYNOPSIS
    Perform a full uninstallation of all dotfile components.

.DESCRIPTION
    Removes all dotfile configurations, the bare repository, aliases,
    and optionally uninstalls tools that were installed.

.PARAMETER RemoveTools
    Also remove tools installed via winget (default: false).

.PARAMETER KeepBackups
    Keep backup files instead of removing them (default: false).

.PARAMETER DryRun
    Show what would be done without actually doing it.

.PARAMETER Force
    Suppress confirmation prompts.

.EXAMPLE
    Invoke-FullUninstall
    Full uninstall keeping tools.

.EXAMPLE
    Invoke-FullUninstall -RemoveTools -Force
    Full uninstall including tools, no prompts.
#>
function Invoke-FullUninstall {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [switch]$RemoveTools,
        [switch]$KeepBackups,
        [switch]$DryRun,
        [switch]$Force
    )

    Write-SectionHeader "Full Dotfile Uninstall"

    $config = Get-UninstallConfig
    $errorCount = 0

    # Verify dotfile repository exists
    if (-not (Test-Path $config.DotDir)) {
        Write-WarningCustom "Dotfile repository not found at: $($config.DotDir)"
        return
    }

    # Step 1: Backup tracked files
    Write-SectionHeader "Step 1: Backing Up Tracked Files"
    if (-not $DryRun) {
        $backupDir = Backup-TrackedFiles
        if ($backupDir) {
            Write-Success "Backup created at: $backupDir"
        } else {
            Write-WarningCustom "No tracked files to backup"
        }
    } else {
        Write-Info "[DRY RUN] Would backup tracked files"
    }

    # Step 2: Remove tracked files
    Write-SectionHeader "Step 2: Removing Tracked Files"
    if (-not $DryRun) {
        $removed = Remove-TrackedFiles
        Write-Success "Removed $removed tracked file(s)"
    } else {
        Write-Info "[DRY RUN] Would remove tracked files"
    }

    # Step 3: Remove dotfile repository
    Write-SectionHeader "Step 3: Removing Dotfile Repository"
    if (-not $DryRun) {
        if (Remove-DotfileRepo -Force:$Force) {
            Write-Success "Dotfile repository removed"
        } else {
            Write-ErrorCustom "Failed to remove dotfile repository"
            $errorCount++
        }
    } else {
        Write-Info "[DRY RUN] Would remove dotfile repository: $($config.DotDir)"
    }

    # Step 4: Remove dot alias from profiles
    Write-SectionHeader "Step 4: Removing Dot Alias"
    if (-not $DryRun) {
        $profilesRemoved = Remove-DotAlias -AllProfiles
        Write-Success "Removed alias from $profilesRemoved profile(s)"
    } else {
        Write-Info "[DRY RUN] Would remove dot alias from profiles"
    }

    # Step 5: Remove XDG environment variables
    Write-SectionHeader "Step 5: Removing XDG Environment Variables"
    if (-not $DryRun) {
        Remove-XDGVariables -FromProfile
        Write-Success "Removed XDG variables from PowerShell profiles"
    } else {
        Write-Info "[DRY RUN] Would remove XDG variables from profiles"
    }

    # Step 6: Remove configurations (optional cleanup)
    Write-SectionHeader "Step 6: Removing Configuration Directories"
    if (-not $DryRun) {
        Remove-NeovimConfig -Force:$Force
        Remove-OhMyPoshTheme -Force:$Force
        Remove-WindowsTerminalSettings -Force:$Force
        Write-Success "Configuration directories cleaned up"
    } else {
        Write-Info "[DRY RUN] Would remove configuration directories"
    }

    # Step 7: Uninstall tools (optional)
    if ($RemoveTools) {
        Write-SectionHeader "Step 7: Uninstalling Tools"
        if (-not $DryRun) {
            $uninstalled = Uninstall-Tools -Force:$Force
            Write-Success "Uninstalled $uninstalled tool(s)"
        } else {
            Write-Info "[DRY RUN] Would uninstall tools"
        }
    }

    # Step 8: Clean up backups
    if (-not $KeepBackups -and -not $DryRun) {
        Write-SectionHeader "Step 8: Cleaning Up Old Backups"
        Remove-BackupFiles -OlderThan (Get-Date).AddDays(-30)
        Write-Success "Old backups removed"
    }

    Write-SectionComplete "Uninstall Complete"

    if ($errorCount -eq 0) {
        Write-Success "Dotfile uninstalled successfully"
        if (-not $KeepBackups -and -not $DryRun) {
            Write-Info "Backups are preserved in: $($config.BackupRoot)"
        }
    } else {
        Write-WarningCustom "Uninstall completed with $errorCount error(s)"
    }
}

<#
.SYNOPSIS
    Perform a quick uninstall (configurations only, keeps tools).

.DESCRIPTION
    Removes dotfile configurations and repository but preserves
    any installed tools. This is useful when you want to cleanly
    remove dotfiles without losing your development environment.

.PARAMETER KeepNeovimConfig
    Keep Neovim configuration files (default: false).

.PARAMETER KeepPoshTheme
    Keep Oh-My-Posh theme files (default: false).

.PARAMETER KeepXDGVars
    Keep XDG environment variables in profiles (default: false).

.PARAMETER DryRun
    Show what would be done without actually doing it.

.PARAMETER Force
    Suppress confirmation prompts.

.EXAMPLE
    Invoke-QuickUninstall
    Quick uninstall removing all configs.

.EXAMPLE
    Invoke-QuickUninstall -KeepNeovimConfig -KeepPoshTheme
    Quick uninstall but keep Neovim and theme configs.
#>
function Invoke-QuickUninstall {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [switch]$KeepNeovimConfig,
        [switch]$KeepPoshTheme,
        [switch]$KeepXDGVars,
        [switch]$DryRun,
        [switch]$Force
    )

    Write-SectionHeader "Quick Dotfile Uninstall"

    $config = Get-UninstallConfig
    $errorCount = 0

    # Verify dotfile repository exists
    if (-not (Test-Path $config.DotDir)) {
        Write-WarningCustom "Dotfile repository not found at: $($config.DotDir)"
        return
    }

    # Step 1: Backup tracked files
    Write-SectionHeader "Step 1: Backing Up Tracked Files"
    if (-not $DryRun) {
        $backupDir = Backup-TrackedFiles
        if ($backupDir) {
            Write-Success "Backup created at: $backupDir"
        } else {
            Write-WarningCustom "No tracked files to backup"
        }
    } else {
        Write-Info "[DRY RUN] Would backup tracked files"
    }

    # Step 2: Remove tracked files
    Write-SectionHeader "Step 2: Removing Tracked Files"
    if (-not $DryRun) {
        $removed = Remove-TrackedFiles
        Write-Success "Removed $removed tracked file(s)"
    } else {
        Write-Info "[DRY RUN] Would remove tracked files"
    }

    # Step 3: Remove dotfile repository
    Write-SectionHeader "Step 3: Removing Dotfile Repository"
    if (-not $DryRun) {
        if (Remove-DotfileRepo -Force:$Force) {
            Write-Success "Dotfile repository removed"
        } else {
            Write-ErrorCustom "Failed to remove dotfile repository"
            $errorCount++
        }
    } else {
        Write-Info "[DRY RUN] Would remove dotfile repository: $($config.DotDir)"
    }

    # Step 4: Remove dot alias from profiles
    Write-SectionHeader "Step 4: Removing Dot Alias"
    if (-not $DryRun) {
        $profilesRemoved = Remove-DotAlias -AllProfiles
        Write-Success "Removed alias from $profilesRemoved profile(s)"
    } else {
        Write-Info "[DRY RUN] Would remove dot alias from profiles"
    }

    # Step 5: Remove XDG environment variables (conditional)
    if (-not $KeepXDGVars) {
        Write-SectionHeader "Step 5: Removing XDG Environment Variables"
        if (-not $DryRun) {
            Remove-XDGVariables -FromProfile
            Write-Success "Removed XDG variables from PowerShell profiles"
        } else {
            Write-Info "[DRY RUN] Would remove XDG variables from profiles"
        }
    } else {
        Write-Info "Skipping XDG variable removal (-KeepXDGVars specified)"
    }

    # Step 6: Remove configurations (conditional)
    Write-SectionHeader "Step 6: Removing Configuration Directories"

    if (-not $KeepNeovimConfig) {
        if (-not $DryRun) {
            Remove-NeovimConfig -Force:$Force
        } else {
            Write-Info "[DRY RUN] Would remove Neovim configuration"
        }
    } else {
        Write-Info "Keeping Neovim configuration (-KeepNeovimConfig specified)"
    }

    if (-not $KeepPoshTheme) {
        if (-not $DryRun) {
            Remove-OhMyPoshTheme -Force:$Force
        } else {
            Write-Info "[DRY RUN] Would remove Oh-My-Posh theme"
        }
    } else {
        Write-Info "Keeping Oh-My-Posh theme (-KeepPoshTheme specified)"
    }

    if (-not $DryRun) {
        Remove-WindowsTerminalSettings -Force:$Force
    } else {
        Write-Info "[DRY RUN] Would remove Windows Terminal settings"
    }

    Write-SectionComplete "Quick Uninstall Complete"

    if ($errorCount -eq 0) {
        Write-Success "Dotfile configurations removed successfully"
        Write-Info "Installed tools were preserved"
    } else {
        Write-WarningCustom "Uninstall completed with $errorCount error(s)"
    }
}

<#
.SYNOPSIS
    Perform a custom uninstall with selective component removal.

.DESCRIPTION
    Allows fine-grained control over which components to remove.
    Each component is controlled by a corresponding parameter.

.PARAMETER RemoveRepo
    Remove the dotfile bare repository.

.PARAMETER RemoveAlias
    Remove the dot alias from profiles.

.PARAMETER RemoveTracked
    Remove all tracked files.

.PARAMETER RemoveNeovim
    Remove Neovim configuration.

.PARAMETER RemovePoshTheme
    Remove Oh-My-Posh theme.

.PARAMETER RemoveWindowsTerminal
    Remove Windows Terminal settings.

.PARAMETER RemoveXDG
    Remove XDG environment variables.

.PARAMETER RemoveTools
    Remove installed tools via winget.

.PARAMETER BackupBeforeRemove
    Create backup before removing files (default: true).

.PARAMETER DryRun
    Show what would be done without actually doing it.

.PARAMETER Force
    Suppress confirmation prompts.

.EXAMPLE
    Invoke-CustomUninstall -RemoveRepo -RemoveAlias -RemoveTracked
    Remove repo, alias, and tracked files only.

.EXAMPLE
    Invoke-CustomUninstall -RemoveNeovim -RemovePoshTheme -RemoveXDG
    Remove only configs and XDG variables.
#>
function Invoke-CustomUninstall {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [switch]$RemoveRepo,
        [switch]$RemoveAlias,
        [switch]$RemoveTracked,
        [switch]$RemoveNeovim,
        [switch]$RemovePoshTheme,
        [switch]$RemoveWindowsTerminal,
        [switch]$RemoveXDG,
        [switch]$RemoveTools,
        [switch]$BackupBeforeRemove = $true,
        [switch]$DryRun,
        [switch]$Force
    )

    Write-SectionHeader "Custom Dotfile Uninstall"

    $config = Get-UninstallConfig
    $errorCount = 0

    # Validate: at least one remove option must be specified
    $removeOptions = @(
        $RemoveRepo, $RemoveAlias, $RemoveTracked,
        $RemoveNeovim, $RemovePoshTheme, $RemoveWindowsTerminal,
        $RemoveXDG, $RemoveTools
    )

    if (-not $removeOptions.Contains($true)) {
        Write-ErrorCustom "At least one -Remove* parameter must be specified"
        return
    }

    # Backup first if requested and removing tracked files
    if ($BackupBeforeRemove -and $RemoveTracked -and -not $DryRun) {
        Write-SectionHeader "Creating Backup"
        $backupDir = Backup-TrackedFiles
        if ($backupDir) {
            Write-Success "Backup created at: $backupDir"
        }
    } elseif ($BackupBeforeRemove -and $RemoveTracked -and $DryRun) {
        Write-Info "[DRY RUN] Would create backup"
    }

    # Remove tracked files
    if ($RemoveTracked) {
        Write-SectionHeader "Removing Tracked Files"
        if (-not $DryRun) {
            $removed = Remove-TrackedFiles
            Write-Success "Removed $removed tracked file(s)"
        } else {
            Write-Info "[DRY RUN] Would remove tracked files"
        }
    }

    # Remove repository
    if ($RemoveRepo) {
        Write-SectionHeader "Removing Dotfile Repository"
        if (-not $DryRun) {
            if (Remove-DotfileRepo -Force:$Force) {
                Write-Success "Dotfile repository removed"
            } else {
                Write-ErrorCustom "Failed to remove dotfile repository"
                $errorCount++
            }
        } else {
            $config = Get-UninstallConfig
            Write-Info "[DRY RUN] Would remove: $($config.DotDir)"
        }
    }

    # Remove alias
    if ($RemoveAlias) {
        Write-SectionHeader "Removing Dot Alias"
        if (-not $DryRun) {
            $profilesRemoved = Remove-DotAlias -AllProfiles
            Write-Success "Removed alias from $profilesRemoved profile(s)"
        } else {
            Write-Info "[DRY RUN] Would remove dot alias"
        }
    }

    # Remove Neovim config
    if ($RemoveNeovim) {
        Write-SectionHeader "Removing Neovim Configuration"
        if (-not $DryRun) {
            Remove-NeovimConfig -Force:$Force
            Write-Success "Neovim configuration removed"
        } else {
            Write-Info "[DRY RUN] Would remove Neovim configuration"
        }
    }

    # Remove Oh-My-Posh theme
    if ($RemovePoshTheme) {
        Write-SectionHeader "Removing Oh-My-Posh Theme"
        if (-not $DryRun) {
            Remove-OhMyPoshTheme -Force:$Force
            Write-Success "Oh-My-Posh theme removed"
        } else {
            Write-Info "[DRY RUN] Would remove Oh-My-Posh theme"
        }
    }

    # Remove Windows Terminal settings
    if ($RemoveWindowsTerminal) {
        Write-SectionHeader "Removing Windows Terminal Settings"
        if (-not $DryRun) {
            Remove-WindowsTerminalSettings -Force:$Force
            Write-Success "Windows Terminal settings removed"
        } else {
            Write-Info "[DRY RUN] Would remove Windows Terminal settings"
        }
    }

    # Remove XDG variables
    if ($RemoveXDG) {
        Write-SectionHeader "Removing XDG Environment Variables"
        if (-not $DryRun) {
            Remove-XDGVariables -FromProfile
            Write-Success "XDG variables removed from profiles"
        } else {
            Write-Info "[DRY RUN] Would remove XDG variables from profiles"
        }
    }

    # Uninstall tools
    if ($RemoveTools) {
        Write-SectionHeader "Uninstalling Tools"
        if (-not $DryRun) {
            $uninstalled = Uninstall-Tools -Force:$Force
            Write-Success "Uninstalled $uninstalled tool(s)"
        } else {
            Write-Info "[DRY RUN] Would uninstall tools"
        }
    }

    Write-SectionComplete "Custom Uninstall Complete"

    if ($errorCount -eq 0) {
        Write-Success "Selected components removed successfully"
    } else {
        Write-WarningCustom "Uninstall completed with $errorCount error(s)"
    }
}

# ============================================
# Core Removal Functions
# ============================================

<#
.SYNOPSIS
    Remove the dotfile bare repository.

.DESCRIPTION
    Removes the bare git repository at the configured DotDir location.
    Verifies it's a valid bare repository before removal.

.PARAMETER Force
    Suppress confirmation prompt.

.EXAMPLE
    Remove-DotfileRepo
    Prompts for confirmation before removing.

.EXAMPLE
    Remove-DotfileRepo -Force
    Removes without prompting.
#>
function Remove-DotfileRepo {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [switch]$Force
    )

    $config = Get-UninstallConfig
    $dotDir = $config.DotDir

    if (-not (Test-Path $dotDir)) {
        Write-WarningCustom "Dotfile repository not found at: $dotDir"
        return $false
    }

    # Verify it's a bare repository
    Push-Location $dotDir
    $isBare = git rev-parse --is-bare-repository 2>$null
    Pop-Location

    if ($isBare -ne "true") {
        Write-ErrorCustom "$dotDir is not a valid bare git repository"
        return $false
    }

    # Confirm removal
    if (-not $Force) {
        $message = "Remove dotfile repository at: $dotDir"
        if (-not (Confirm-Action -Message $message)) {
            Write-Info "Cancelled"
            return $false
        }
    }

    try {
        Remove-Item $dotDir -Recurse -Force -ErrorAction Stop
        Write-Success "Removed dotfile repository: $dotDir"
        return $true
    } catch {
        Write-ErrorCustom "Failed to remove repository: $_"
        return $false
    }
}

<#
.SYNOPSIS
    Remove the 'dot' alias from PowerShell profiles.

.DESCRIPTION
    Removes the dot function alias from all PowerShell profile locations.
    Supports both current user and all users profiles.

.PARAMETER ProfilePath
    Specific profile path to clean (if not specified, checks all profiles).

.PARAMETER AllProfiles
    Remove from all PowerShell profiles (default).

.PARAMETER Force
    Suppress confirmation prompts.

.EXAMPLE
    Remove-DotAlias
    Remove from all profiles with confirmation.

.EXAMPLE
    Remove-DotAlias -AllProfiles -Force
    Remove from all profiles without confirmation.
#>
function Remove-DotAlias {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [string]$ProfilePath,
        [switch]$AllProfiles,
        [switch]$Force
    )

    $config = Get-UninstallConfig
    $aliasName = $config.AliasName

    # Define patterns to search for
    $patterns = @(
        "function $aliasName",
        "Set-Alias -Name $aliasName",
        "New-Alias -Name $aliasName",
        "$aliasName = git --git-dir"
    )

    if ($ProfilePath) {
        $profilesToCheck = @($ProfilePath)
    } elseif ($AllProfiles) {
        $profilesToCheck = @(
            $PROFILE.CurrentUserCurrentHost,
            $PROFILE.CurrentUserAllHosts,
            $PROFILE.AllUsersCurrentHost,
            $PROFILE.AllUsersAllHosts
        ) | Where-Object { -not [string]::IsNullOrEmpty($_) }
    } else {
        $profilesToCheck = @($PROFILE.CurrentUserCurrentHost)
    }

    $removedCount = 0

    foreach ($profile in $profilesToCheck) {
        if (-not (Test-Path $profile)) {
            continue
        }

        Write-Info "Checking profile: $profile"

        $content = Get-Content $profile -Raw -ErrorAction SilentlyContinue
        if ($null -eq $content) {
            continue
        }

        $modified = $false
        foreach ($pattern in $patterns) {
            if ($content -match [regex]::Escape($pattern)) {
                $modified = $true
                break
            }
        }

        if ($modified) {
            if (-not $Force) {
                $message = "Remove $aliasName alias from: $profile"
                if (-not (Confirm-Action -Message $message)) {
                    Write-Info "Skipped: $profile"
                    continue
                }
            }

            # Backup the profile
            Backup-File $profile

            # Remove the alias function/block
            # This removes multi-line function definitions
            $content = $content -replace "function\s+$aliasName\s*\{[^}]*\}", ""
            $content = $content -replace "Set-Alias\s+-Name\s+$aliasName\s+.*", ""
            $content = $content -replace "New-Alias\s+-Name\s+$aliasName\s+.*", ""
            $content = $content -replace "\$$aliasName\s*=.*", ""

            # Clean up extra blank lines
            $content = $content -replace "`r`n`r`n", "`r`n"

            Set-Content $profile -Value $content -Force
            Write-Success "Removed $aliasName alias from: $profile"
            $removedCount++
        }
    }

    return $removedCount
}

<#
.SYNOPSIS
    Remove dotfile-specific configuration from PowerShell profiles.

.DESCRIPTION
    Removes XDG environment variables and other dotfile-specific
    configuration from PowerShell profiles while preserving
    user's custom configurations.

.PARAMETER ProfilePath
    Specific profile to clean (default: current user profile).

.PARAMETER Force
    Suppress confirmation prompts.

.EXAMPLE
    Remove-PowerShellProfileConfig
    Remove config from current user profile.
#>
function Remove-PowerShellProfileConfig {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [string]$ProfilePath,
        [switch]$Force
    )

    if ($ProfilePath) {
        $profilesToCheck = @($ProfilePath)
    } else {
        $profilesToCheck = @($PROFILE.CurrentUserCurrentHost)
    }

    foreach ($profile in $profilesToCheck) {
        if (-not (Test-Path $profile)) {
            continue
        }

        Write-Info "Cleaning profile: $profile"

        $content = Get-Content $profile -Raw -ErrorAction SilentlyContinue
        if ($null -eq $content) {
            continue
        }

        $modified = $false

        # Remove XDG variable exports
        if ($content -match '\$env:XDG_') {
            if (-not $Force) {
                $message = "Remove XDG variables from: $profile"
                if (-not (Confirm-Action -Message $message)) {
                    continue
                }
            }
            $modified = $true
        }

        if ($modified) {
            Backup-File $profile

            # Remove XDG environment variable lines
            $content = $content -replace '\$env:XDG_CONFIG_HOME\s*=\s*[^`r`n]*', ""
            $content = $content -replace '\$env:XDG_DATA_HOME\s*=\s*[^`r`n]*', ""
            $content = $content -replace '\$env:XDG_STATE_HOME\s*=\s*[^`r`n]*', ""
            $content = $content -replace '\$env:XDG_CACHE_HOME\s*=\s*[^`r`n]*', ""

            # Clean up extra blank lines
            $content = $content -replace "`r`n`r`n", "`r`n"

            Set-Content $profile -Value $content -Force
            Write-Success "Cleaned profile: $profile"
        }
    }
}

<#
.SYNOPSIS
    Remove XDG environment variables from environment and profiles.

.DESCRIPTION
    Removes XDG Base Directory environment variables from:
    - Current session environment
    - PowerShell profiles
    - System/user environment (optional)

.PARAMETER FromProfile
    Remove from PowerShell profiles.

.PARAMETER FromEnvironment
    Remove from system/user environment variables (requires admin).

.PARAMETER Force
    Suppress confirmation prompts.

.EXAMPLE
    Remove-XDGVariables -FromProfile
    Remove XDG vars from profiles only.

.EXAMPLE
    Remove-XDGVariables -FromProfile -FromEnvironment
    Remove from profiles and system environment.
#>
function Remove-XDGVariables {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [switch]$FromProfile,
        [switch]$FromEnvironment,
        [switch]$Force
    )

    $xdgVars = @('XDG_CONFIG_HOME', 'XDG_DATA_HOME', 'XDG_STATE_HOME', 'XDG_CACHE_HOME')

    # Remove from current session
    foreach ($var in $xdgVars) {
        if (Test-Path "env:$var") {
            Remove-Item "env:$var" -Force
            Write-Info "Removed $var from current session"
        }
    }

    # Remove from profiles
    if ($FromProfile) {
        Remove-PowerShellProfileConfig -Force:$Force
    }

    # Remove from system/user environment
    if ($FromEnvironment) {
        if (-not (Test-Administrator)) {
            Write-WarningCustom "Removing from system environment requires administrator privileges"
            return
        }

        if (-not $Force) {
            $message = "Remove XDG variables from system environment?"
            if (-not (Confirm-Action -Message $message)) {
                return
            }
        }

        foreach ($var in $xdgVars) {
            try {
                [Environment]::SetEnvironmentVariable($var, $null, "User")
                Write-Success "Removed ${var} from user environment"
            } catch {
                Write-ErrorCustom "Failed to remove ${var}: $_"
            }
        }
    }
}

# ============================================
# Configuration Removal Functions
# ============================================

<#
.SYNOPSIS
    Remove Neovim configuration files.

.DESCRIPTION
    Removes Neovim configuration from both XDG and legacy locations.
    Supports both standard Windows paths and XDG-compliant paths.

.PARAMETER Force
    Suppress confirmation prompts.

.EXAMPLE
    Remove-NeovimConfig
    Remove Neovim config with confirmation.

.EXAMPLE
    Remove-NeovimConfig -Force
    Remove without confirmation.
#>
function Remove-NeovimConfig {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [switch]$Force
    )

    $configPaths = @(
        # XDG-compliant path
        Join-Path $script:UninstallConfig.XDGConfigHome "nvim",
        # Legacy Windows path
        Join-Path $env:LOCALAPPDATA "nvim",
        # Data path
        Join-Path $script:UninstallConfig.XDGDataHome "nvim",
        Join-Path $env:LOCALAPPDATA "nvim-data"
    )

    foreach ($path in $configPaths) {
        if (Test-Path $path) {
            Write-Info "Found Neovim config at: $path"

            if (-not $Force) {
                $message = "Remove Neovim configuration at: $path"
                if (-not (Confirm-Action -Message $message)) {
                    Write-Info "Skipped: $path"
                    continue
                }
            }

            try {
                Remove-Item $path -Recurse -Force -ErrorAction Stop
                Write-Success "Removed: ${path}"
            } catch {
                Write-ErrorCustom "Failed to remove ${path}: $_"
            }
        }
    }
}

<#
.SYNOPSIS
    Remove Oh-My-Posh theme files.

.DESCRIPTION
    Removes the .poshthemes directory and custom theme files.
    Preserves Oh-My-Posh installation itself.

.PARAMETER ThemeName
    Specific theme name to remove (if not specified, removes all custom themes).

.PARAMETER Force
    Suppress confirmation prompts.

.EXAMPLE
    Remove-OhMyPoshTheme
    Remove all custom themes with confirmation.

.EXAMPLE
    Remove-OhMyPoshTheme -ThemeName "mytheme.omp.json"
    Remove specific theme.
#>
function Remove-OhMyPoshTheme {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [string]$ThemeName,
        [switch]$Force
    )

    $poshThemesDir = "$env:USERPROFILE\.poshthemes"

    if ($ThemeName) {
        # Remove specific theme
        $themePath = Join-Path $poshThemesDir $ThemeName

        if (Test-Path $themePath) {
            if (-not $Force) {
                $message = "Remove theme: $ThemeName"
                if (-not (Confirm-Action -Message $message)) {
                    return
                }
            }

            Remove-Item $themePath -Force
            Write-Success "Removed theme: $themePath"
        } else {
            Write-WarningCustom "Theme not found: $themePath"
        }
    } else {
        # Remove all custom themes (preserve builtin)
        if (Test-Path $poshThemesDir) {
            if (-not $Force) {
                $message = "Remove custom themes from: $poshThemesDir"
                if (-not (Confirm-Action -Message $message)) {
                    return
                }
            }

            # List all custom themes (non-builtin)
            $themes = Get-ChildItem $poshThemesDir -Filter "*.omp.json" |
                      Where-Object { $_.Name -notmatch '^(atomic|avit|beta|cloud|craver|cupcake|darkblood|emblem|fish|jandedobbeleer|jtracey93|kushal|liquid|marcduiker|material|microverse-power|montys|mt|negomi|nu4a|paradox|pararus-rob|powerlevel10k|plain|poweline|pure|remk|robbyrussell|rose|shell|slim|smooth|sonn|space|spaceship|star|svelte|the-unnamed|tokie|tomukun|quick-term|lambda|agnoster|jandedobbeleer-omp|ys|zash)' }

            foreach ($theme in $themes) {
                Remove-Item $theme.FullName -Force
                Write-Success "Removed theme: $($theme.Name)"
            }
        } else {
            Write-WarningCustom "No .poshthemes directory found"
        }
    }
}

<#
.SYNOPSIS
    Remove Windows Terminal settings.

.DESCRIPTION
    Removes Windows Terminal settings JSON file.
    Be careful as this removes ALL Windows Terminal customizations.

.PARAMETER Force
    Suppress confirmation prompts.

.EXAMPLE
    Remove-WindowsTerminalSettings
    Remove with confirmation.
#>
function Remove-WindowsTerminalSettings {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [switch]$Force
    )

    $settingsPath = Join-Path $env:LOCALAPPDATA "Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"

    if (Test-Path $settingsPath) {
        Write-WarningCustom "This will remove ALL Windows Terminal settings"

        if (-not $Force) {
            $message = "Remove Windows Terminal settings at: $settingsPath"
            if (-not (Confirm-Action -Message $message)) {
                Write-Info "Skipped Windows Terminal settings removal"
                return
            }
        }

        # Backup before removing
        Backup-File $settingsPath

        # Remove the settings file (Windows Terminal will recreate defaults)
        Remove-Item $settingsPath -Force
        Write-Success "Removed Windows Terminal settings"
        Write-Info "Windows Terminal will recreate default settings on next launch"
    } else {
        Write-Info "Windows Terminal settings not found"
    }
}

# ============================================
# Tool Uninstallation Functions
# ============================================

<#
.SYNOPSIS
    Uninstall development tools installed via winget.

.DESCRIPTION
    Uninstalls tools that were commonly installed as part of the
    dotfile setup. Uses winget for package management.

.PARAMETER Tools
    Specific tools to uninstall (if not specified, uninstalls common tools).

.PARAMETER Keep
    Tools to keep even if they're in the default list.

.PARAMETER Force
    Suppress confirmation prompts and force uninstall.

.EXAMPLE
    Uninstall-Tools
    Uninstall all common tools.

.EXAMPLE
    Uninstall-Tools -Tools "Microsoft.PowerShell", "Neovim.Neovim"
    Uninstall specific tools only.

.EXAMPLE
    Uninstall-Tools -Keep "Git.Git"
    Uninstall common tools but keep Git.
#>
function Uninstall-Tools {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [string[]]$Tools,
        [string[]]$Keep,
        [switch]$Force
    )

    # Default list of tools that might be installed
    $defaultTools = @(
        "Microsoft.PowerShell",
        "Microsoft.WindowsTerminal",
        "Git.Git",
        "Neovim.Neovim",
        "JanDeDobbeleer.OhMyPosh",
        "Microsoft.VSCode",
        "GitHub.cli"
    )

    if ($Tools) {
        $toolsToUninstall = $Tools
    } else {
        $toolsToUninstall = $defaultTools
    }

    # Filter out tools to keep
    if ($Keep) {
        $toolsToUninstall = $toolsToUninstall | Where-Object { $_ -notin $Keep }
    }

    if (-not (Test-CommandAvailable "winget")) {
        Write-ErrorCustom "winget is not available. Cannot uninstall tools."
        return 0
    }

    $uninstalledCount = 0

    foreach ($tool in $toolsToUninstall) {
        Write-Info "Checking: $tool"

        # Check if tool is installed
        $installed = winget list --id $tool --exact 2>$null

        if ($LASTEXITCODE -eq 0) {
            if (-not $Force) {
                $message = "Uninstall $tool?"
                if (-not (Confirm-Action -Message $message)) {
                    Write-Info "Skipped: $tool"
                    continue
                }
            }

            Write-Info "Uninstalling: $tool"
            winget uninstall --id $tool --exact --silent 2>$null | Out-Null

            if ($LASTEXITCODE -eq 0) {
                Write-Success "Uninstalled: $tool"
                $uninstalledCount++
            } else {
                Write-WarningCustom "Failed to uninstall: $tool (exit code: $LASTEXITCODE)"
            }
        } else {
            Write-Info "Not installed: $tool"
        }
    }

    return $uninstalledCount
}

# ============================================
# Tracked Files Management
# ============================================

<#
.SYNOPSIS
    Get list of files tracked by the dotfile repository.

.DESCRIPTION
    Returns all files tracked by the bare dotfile repository.
    Useful for backup and removal operations.

.EXAMPLE
    $files = Get-TrackedDotfiles
#>
function Get-TrackedDotfiles {
    [CmdletBinding()]
    [OutputType([string[]])]
    param()

    $config = Get-UninstallConfig
    $dotDir = $config.DotDir

    if (-not (Test-Path $dotDir)) {
        Write-WarningCustom "Dotfile repository not found"
        return @()
    }

    try {
        Push-Location $dotDir
        $trackedFiles = git ls-tree -r --name-only HEAD 2>$null
        Pop-Location

        if ($trackedFiles) {
            return $trackedFiles -split "`n" | Where-Object { -not [string]::IsNullOrEmpty($_) }
        }

        return @()
    } catch {
        Write-ErrorCustom "Failed to get tracked files: $_"
        Pop-Location
        return @()
    }
}

<#
.SYNOPSIS
    Backup all tracked dotfiles.

.DESCRIPTION
    Creates a timestamped backup of all files tracked by the
    dotfile repository before removal.

.EXAMPLE
    $backupDir = Backup-TrackedFiles
#>
function Backup-TrackedFiles {
    [CmdletBinding()]
    [OutputType([string])]
    param()

    $config = Get-UninstallConfig
    $trackedFiles = Get-TrackedDotfiles

    if ($trackedFiles.Count -eq 0) {
        Write-WarningCustom "No tracked files found"
        return $null
    }

    # Create backup directory
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $backupDir = Join-Path $config.BackupRoot "backup_$timestamp"

    if (-not (Test-Path $config.BackupRoot)) {
        New-Item -ItemType Directory -Path $config.BackupRoot -Force | Out-Null
    }

    New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
    Write-Info "Created backup directory: $backupDir"

    $backedUpCount = 0

    foreach ($file in $trackedFiles) {
        $sourcePath = Join-Path $config.WorkTree $file
        $destPath = Join-Path $backupDir $file

        if (Test-Path $sourcePath) {
            $destDir = Split-Path $destPath -Parent

            if (-not (Test-Path $destDir)) {
                New-Item -ItemType Directory -Path $destDir -Force | Out-Null
            }

            Copy-Item $sourcePath $destPath -Force -Recurse
            $backedUpCount++
            Write-Info "Backed up: $file"
        }
    }

    Write-Success "Backed up $backedUpCount file(s) to: $backupDir"
    return $backupDir
}

<#
.SYNOPSIS
    Remove all tracked dotfiles.

.DESCRIPTION
    Removes all files that are tracked by the dotfile repository.
    Does NOT remove the repository itself (use Remove-DotfileRepo for that).

.EXAMPLE
    $removed = Remove-TrackedFiles
#>
function Remove-TrackedFiles {
    [CmdletBinding()]
    [OutputType([int])]
    param()

    $config = Get-UninstallConfig
    $trackedFiles = Get-TrackedDotfiles

    if ($trackedFiles.Count -eq 0) {
        Write-WarningCustom "No tracked files found"
        return 0
    }

    $removedCount = 0

    foreach ($file in $trackedFiles) {
        $targetPath = Join-Path $config.WorkTree $file

        if (Test-Path $targetPath) {
            try {
                Remove-Item $targetPath -Force -Recurse -ErrorAction Stop
                Write-Info "Removed: ${file}"
                $removedCount++
            } catch {
                Write-WarningCustom "Failed to remove ${file}: $_"
            }
        }
    }

    return $removedCount
}

# ============================================
# Backup Management Functions
# ============================================

<#
.SYNOPSIS
    Get the uninstall backup directory.

.DESCRIPTION
    Returns the path to the directory where uninstall backups are stored.

.EXAMPLE
    $backupDir = Get-UninstallBackupDir
#>
function Get-UninstallBackupDir {
    [CmdletBinding()]
    [OutputType([string])]
    param()

    $config = Get-UninstallConfig
    return $config.BackupRoot
}

<#
.SYNOPSIS
    Remove old backup files.

.DESCRIPTION
    Removes backup directories older than the specified date.
    Useful for cleaning up old uninstall backups.

.PARAMETER OlderThan
    Remove backups older than this date (default: 30 days ago).

.PARAMETER KeepCount
    Keep the most recent N backups (alternative to OlderThan).

.PARAMETER Force
    Remove without confirmation.

.EXAMPLE
    Remove-BackupFiles -OlderThan (Get-Date).AddDays(-30)
    Remove backups older than 30 days.

.EXAMPLE
    Remove-BackupFiles -KeepCount 5
    Keep only the 5 most recent backups.
#>
function Remove-BackupFiles {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [DateTime]$OlderThan = (Get-Date).AddDays(-30),
        [int]$KeepCount,
        [switch]$Force
    )

    $backupRoot = Get-UninstallBackupDir

    if (-not (Test-Path $backupRoot)) {
        Write-Info "No backup directory found"
        return
    }

    $backups = Get-ChildItem $backupRoot -Directory |
               Sort-Object LastWriteTime -Descending

    if ($KeepCount) {
        $toRemove = $backups | Select-Object -Skip $KeepCount
    } else {
        $toRemove = $backups | Where-Object { $_.LastWriteTime -lt $OlderThan }
    }

    if ($toRemove.Count -eq 0) {
        Write-Info "No old backups to remove"
        return
    }

    if (-not $Force) {
        $message = "Remove $($toRemove.Count) old backup(s)?"
        if (-not (Confirm-Action -Message $message)) {
            Write-Info "Cancelled"
            return
        }
    }

    foreach ($backup in $toRemove) {
        try {
            Remove-Item $backup.FullName -Recurse -Force -ErrorAction Stop
            Write-Success "Removed: $($backup.Name)"
        } catch {
            Write-WarningCustom "Failed to remove $($backup.Name): $_"
        }
    }
}

<#
.SYNOPSIS
    Remove all uninstall backups.

.DESCRIPTION
    Removes the entire backup directory and all backups within.
    Use with caution!

.PARAMETER Force
    Remove without confirmation.

.EXAMPLE
    Clear-UninstallBackups
    Prompts before removing all backups.
#>
function Clear-UninstallBackups {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [switch]$Force
    )

    $backupRoot = Get-UninstallBackupDir

    if (-not (Test-Path $backupRoot)) {
        Write-Info "No backup directory found"
        return
    }

    Write-WarningCustom "This will remove ALL uninstall backups!"

    if (-not $Force) {
        $message = "Remove all backups in: $backupRoot"
        if (-not (Confirm-Action -Message $message)) {
            Write-Info "Cancelled"
            return
        }
    }

    try {
        Remove-Item $backupRoot -Recurse -Force -ErrorAction Stop
        Write-Success "Removed all uninstall backups"
    } catch {
        Write-ErrorCustom "Failed to remove backups: $_"
    }
}

# ============================================
# Module Exports
# ============================================

Export-ModuleMember -Function @(
    # Configuration
    'Get-UninstallConfig',
    'Set-UninstallConfig',

    # Main Uninstall Functions
    'Invoke-FullUninstall',
    'Invoke-QuickUninstall',
    'Invoke-CustomUninstall',

    # Core Removal Functions
    'Remove-DotfileRepo',
    'Remove-DotAlias',
    'Remove-PowerShellProfileConfig',
    'Remove-XDGVariables',

    # Configuration Removal Functions
    'Remove-NeovimConfig',
    'Remove-OhMyPoshTheme',
    'Remove-WindowsTerminalSettings',

    # Tool Uninstallation Functions
    'Uninstall-Tools',

    # Tracked Files Management
    'Get-TrackedDotfiles',
    'Backup-TrackedFiles',
    'Remove-TrackedFiles',

    # Backup Management Functions
    'Get-UninstallBackupDir',
    'Remove-BackupFiles',
    'Clear-UninstallBackups'
)
