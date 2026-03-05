#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Uninstall dotfile configuration and optionally restore system defaults

.DESCRIPTION
    This script completely removes the dotfile installation from your system.
    It removes all deployed configurations, the bare git repository, and restores
    system defaults or performs cleanup.

.PARAMETER RemoveBackups
    Remove backup files created during initial installation

.PARAMETER KeepProfile
    Keep PowerShell profile instead of restoring default

.PARAMETER KeepTerminalSettings
    Keep Windows Terminal settings instead of removing them

.PARAMETER KeepVimConfig
    Keep Vim/Neovim configurations instead of removing them

.PARAMETER Quiet
    Run without confirmation prompts

.EXAMPLE
    .\Uninstall-Dotfile.ps1
    Interactive uninstall with prompts

.EXAMPLE
    .\Uninstall-Dotfile.ps1 -RemoveBackups -Quiet
    Full uninstall without prompts and remove all backups

.EXAMPLE
    .\Uninstall-Dotfile.ps1 -KeepProfile
    Remove all dotfiles but keep PowerShell profile
#>

param(
    [switch]$RemoveBackups,
    [switch]$KeepProfile,
    [switch]$KeepTerminalSettings,
    [switch]$KeepVimConfig,
    [switch]$Quiet
)

# Import UI module for colored output
$ModulePath = Join-Path $PSScriptRoot "..\.config\powershell\modules"
Import-Module (Join-Path $ModulePath "UI.psm1") -Force

# Import dotfile management module
Import-Module (Join-Path $ModulePath "DotfileInstaller.psm1") -Force

# Import verification module for cleanup check
Import-Module (Join-Path $ModulePath "Verifier.psm1") -Force

# Global variables
$DotfileRepoPath = "$env:USERPROFILE\.dotfile"
$BackupPath = "$env:USERPROFILE\.dotfiles_backup_$(Get-Date -Format 'yyyyMMdd')"
$LogPath = "$env:TEMP\dotfile_uninstall_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"

# Function to log messages
function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp - $Message" | Out-File -FilePath $LogPath -Append
    Write-Info $Message
}

# Function to show uninstall summary
function Show-UninstallSummary {
    param([bool]$Quiet = $false)

    $summary = @"
    ==========================================
    Dotfile Uninstall Summary
    ==========================================

    This will perform the following actions:

    [✓] Remove bare git repository: $DotfileRepoPath
    [✓] Remove 'dot' function from PowerShell profile
    [✓] Clean up Neovim configuration: $env:USERPROFILE\.config\nvim
    [✓] Clean up Vim configuration: $env:USERPROFILE\.vim
    [✓] Clean up Windows Terminal settings
    [✓] Remove XDG environment variables from profile

    @If backups exist: $BackupPath
    @If RemoveBackups specified: Delete backup files

    @If KeepProfile specified: Keep PowerShell profile
    @If KeepTerminalSettings specified: Keep Windows Terminal settings
    @If KeepVimConfig specified: Keep Vim configurations

    Log file: $LogPath

    ==========================================
"@

    if (-not $Quiet) {
        Write-Host $summary
        $confirm = Read-Host "`nProceed with uninstallation? (Y/N)"
        if ($confirm -ne "Y" -and $confirm -ne "y") {
            Write-Warning "Uninstall cancelled by user"
            exit 0
        }
    } else {
        Write-Info "Running uninstall in quiet mode..."
        Write-Host $summary
    }
}

# Function to clean up XDG environment variables
function Remove-XDGEnvironment {
    Write-Log "Removing XDG environment variables"

    $profilePaths = @(
        "$env:USERPROFILE\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1",
        "$env:USERPROFILE\Documents\WindowsPowerShell\Profile.ps1"
    )

    foreach ($profilePath in $profilePaths) {
        if (Test-Path $profilePath) {
            $content = Get-Content $profilePath -Raw

            # Remove XDG-related lines
            $updatedContent = $content -replace '# XDG Base Directory Specification - Enable Linux-style paths on Windows.*?\n.*?Set permanently in user environment.*?\n.*?\}', ''

            if ($updatedContent -ne $content) {
                $updatedContent | Out-File $profilePath -Encoding utf8
                Write-Log "Removed XDG variables from: $profilePath"
            }
        }
    }

    # Remove environment variables from registry
    try {
        [System.Environment]::SetEnvironmentVariable('XDG_CONFIG_HOME', $null, 'User')
        [System.Environment]::SetEnvironmentVariable('XDG_DATA_HOME', $null, 'User')
        [System.Environment]::SetEnvironmentVariable('XDG_STATE_HOME', $null, 'User')
        Write-Log "Removed XDG environment variables from registry"
    } catch {
        Write-Warning "Failed to remove XDG variables from registry: $_"
    }
}

# Function to clean up PowerShell profile
function Remove-ProfileDotFunction {
    param([bool]$KeepProfile = $false)

    if ($KeepProfile) {
        Write-Log "Keeping PowerShell profile intact"
        return
    }

    Write-Log "Removing dot function from PowerShell profile"

    $profilePaths = @(
        "$env:USERPROFILE\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1",
        "$env:USERPROFILE\Documents\WindowsPowerShell\Profile.ps1",
        "$env:PROFILE.CurrentUserCurrentHost"
    )

    foreach ($profilePath in $profilePaths) {
        if (Test-Path $profilePath) {
            $content = Get-Content $profilePath -Raw

            # Remove dot function definition
            $updatedContent = $content -replace '# dotfile管理\s*\n.*?function dot\s*\{.*?git --git-dir=.*?\s*\}.*?\n', ''

            if ($updatedContent -ne $content) {
                $updatedContent | Out-File $profilePath -Encoding utf8
                Write-Log "Removed dot function from: $profilePath"
            }
        }
    }
}

# Function to clean up Neovim configuration
function Remove-NeovimConfig {
    param([bool]$KeepVimConfig = $false)

    if ($KeepVimConfig) {
        Write-Log "Keeping Neovim configuration intact"
        return
    }

    $nvimPaths = @(
        "$env:USERPROFILE\.config\nvim",
        "$env:LOCALAPPDATA\nvim",
        "$env:APPDATA\nvim"
    )

    foreach ($path in $nvimPaths) {
        if (Test-Path $path) {
            Write-Log "Removing Neovim config: $path"
            Remove-Item -Path $path -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    # Clean up Neovim data directories
    $nvimDataPaths = @(
        "$env:LOCALAPPDATA\nvim-data",
        "$env:APPDATA\nvim",
        "$env:XDG_DATA_HOME\nvim-data"
    )

    foreach ($path in $nvimDataPaths) {
        if (Test-Path $path) {
            Write-Log "Removing Neovim data: $path"
            Remove-Item -Path $path -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}

# Function to clean up Vim configuration
function Remove-VimConfig {
    param([bool]$KeepVimConfig = $false)

    if ($KeepVimConfig) {
        Write-Log "Keeping Vim configuration intact"
        return
    }

    $vimPaths = @(
        "$env:USERPROFILE\.vim",
        "$env:VIM",
        "$env:VIMRC"
    )

    foreach ($path in $vimPaths) {
        if (Test-Path $path) {
            Write-Log "Removing Vim config: $path"
            Remove-Item -Path $path -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}

# Function to clean up Windows Terminal settings
function Remove-TerminalSettings {
    param([bool]$KeepTerminalSettings = $false)

    if ($KeepTerminalSettings) {
        Write-Log "Keeping Windows Terminal settings intact"
        return
    }

    $terminalPath = "$env:LOCALAPPDB\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"

    if (Test-Path $terminalPath) {
        Write-Log "Removing Windows Terminal custom settings"
        # Create a minimal settings file instead of removing
        $minimalSettings = @{
            "profiles" = @{
                "defaults" = @{
                    "cursorColor" = "#FFFFFF"
                    "fontFace" = "Consolas"
                    "fontSize" = 12
                }
            }
            "profiles" = @{
                "list" = @()
            }
        } | ConvertTo-Json -Depth 10

        $minimalSettings | Out-File $terminalPath -Encoding utf8
        Write-Log "Reset Windows Terminal to minimal settings"
    }
}

# Function to clean up Oh-My-Posh and themes
function Remove-OhMyPosh {
    Write-Log "Cleaning up Oh-My-Posh installation"

    # Uninstall via winget if installed
    if (Get-Command winget -ErrorAction SilentlyContinue) {
        winget uninstall JanDeDobbeleer.OhMyPosh -e --silent 2>$null
    }

    # Remove theme directory
    $themePath = "$env:USERPROFILE\.poshthemes"
    if (Test-Path $themePath) {
        Remove-Item -Path $themePath -Recurse -Force -ErrorAction SilentlyContinue
        Write-Log "Removed theme directory: $themePath"
    }

    # Remove Oh-My-Posh from PowerShell profile
    $profilePaths = @(
        "$env:USERPROFILE\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1",
        "$env:USERPROFILE\Documents\WindowsPowerShell\Profile.ps1"
    )

    foreach ($profilePath in $profilePaths) {
        if (Test-Path $profilePath) {
            $content = Get-Content $profilePath -Raw
            $updatedContent = $content -replace '# Oh-My-Posh 主题引擎.*?\n.*?oh-my-posh.*?\n.*?Invoke-Expression.*?\n', ''
            if ($updatedContent -ne $content) {
                $updatedContent | Out-File $profilePath -Encoding utf8
                Write-Log "Removed Oh-My-Posh from profile"
            }
        }
    }
}

# Function to clean up PowerShell modules
function Remove-PowerShellModules {
    Write-Log "Cleaning up PowerShell modules"

    $modules = @(
        "Terminal-Icons",
        "PSReadLine",  # Don't remove as it's built-in
        "PSFzf",
        "OhMyPosh",    # Already handled
        "zoxide"
    )

    foreach ($module in $modules) {
        $modulePath = Join-Path $env:USERPROFILE "Documents\WindowsPowerShell\Modules\$module"
        if (Test-Path $modulePath) {
            Write-Log "Removing module: $module"
            Remove-Item -Path $modulePath -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}

# Function to clean up tools installations
function Remove-Tools {
    Write-Log "Checking for installed tools to uninstall"

    if (Get-Command winget -ErrorAction SilentlyContinue) {
        $tools = @(
            @{Name = "Neovim"; Id = "Neovim.Neovim"},
            @{Name = "Git"; Id = "Git.Git"},
            @{Name = "Node.js"; Id = "OpenJS.NodeJS"},
            @{Name = "Windows Terminal"; Id = "Microsoft.WindowsTerminal"}
        )

        foreach ($tool in $tools) {
            if (Get-Command $tool.Name -ErrorAction SilentlyContinue) {
                Write-Log "Attempting to uninstall: $($tool.Name)"
                winget uninstall $($tool.Id) -e --silent 2>$null
            }
        }
    }
}

# Function to remove backup files
function Remove-Backups {
    Write-Log "Removing backup files"

    if (Test-Path $BackupPath) {
        Remove-Item -Path $BackupPath -Recurse -Force -ErrorAction SilentlyContinue
        Write-Log "Removed backup directory: $BackupPath"
    }

    # Clean up any other backup directories
    $backupPattern = "$env:USERPROFILE\.dotfiles_backup_*"
    $backupDirs = Get-ChildItem -Path $backupPattern -Directory -ErrorAction SilentlyContinue

    foreach ($dir in $backupDirs) {
        Write-Log "Removing backup directory: $($dir.FullName)"
        Remove-Item -Path $dir.FullName -Recurse -Force -ErrorAction SilentlyContinue
    }
}

# Main uninstall process
function main {
    Write-Info "Starting dotfile uninstallation..."
    Write-Log "Starting uninstall process"

    # Show summary and get confirmation
    Show-UninstallSummary -Quiet:$Quiet

    # Step 1: Remove the bare git repository
    if (Test-Path $DotfileRepoPath) {
        Write-Log "Removing bare git repository: $DotfileRepoPath"
        Remove-Item -Path $DotfileRepoPath -Recurse -Force -ErrorAction SilentlyContinue
    } else {
        Write-Log "Dotfile repository not found at: $DotfileRepoPath"
    }

    # Step 2: Remove dot function from profile
    Remove-ProfileDotFunction -KeepProfile:$KeepProfile

    # Step 3: Remove XDG environment variables
    Remove-XDGEnvironment

    # Step 4: Remove Neovim configuration
    Remove-NeovimConfig -KeepVimConfig:$KeepVimConfig

    # Step 5: Remove Vim configuration
    Remove-VimConfig -KeepVimConfig:$KeepVimConfig

    # Step 6: Remove Windows Terminal settings
    Remove-TerminalSettings -KeepTerminalSettings:$KeepTerminalSettings

    # Step 7: Remove Oh-My-Posh
    Remove-OhMyPosh

    # Step 8: Remove PowerShell modules
    Remove-PowerShellModules

    # Step 9: Uninstall tools (optional)
    if ($Quiet) {
        Remove-Tools
    } else {
        $uninstallTools = Read-Host "Do you want to also uninstall development tools (Git, Node.js, Neovim, etc.)? (Y/N)"
        if ($uninstallTools -eq "Y" -or $uninstallTools -eq "y") {
            Remove-Tools
        }
    }

    # Step 10: Remove backup files
    if ($RemoveBackups) {
        Remove-Backups
    } elseif (-not $Quiet -and (Test-Path $BackupPath)) {
        $removeBackups = Read-Host "Do you want to remove backup files? (Y/N)"
        if ($removeBackups -eq "Y" -or $removeBackups -eq "y") {
            Remove-Backups
        }
    }

    # Final verification
    Write-Info "Final verification..."
    $verified = Verify-Installation

    if (-not $verified) {
        Write-Success "Dotfile uninstallation completed successfully!"
        Write-Log "Uninstall completed successfully"
    } else {
        Write-Warning "Some components may still remain. Manual cleanup may be required."
        Write-Log "Uninstall completed with warnings"
    }

    # Display post-uninstall instructions
    Write-Info "`n=== Post-Uninstall Instructions ==="
    Write-Info "1. Restart PowerShell to ensure all changes take effect"
    Write-Info "2. The uninstall log is saved to: $LogPath"
    Write-Info "3. If you removed development tools, you'll need to reinstall them manually"

    if (-not $Quiet) {
        Write-Host "`nPress any key to exit..."
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    }
}

# Run the main function
main