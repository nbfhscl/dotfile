#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Quick uninstall dotfile configuration

.DESCRIPTION
    A simplified uninstall script that removes only dotfile configurations,
    keeping system tools and applications intact.
#>

param(
    [switch]$Quiet,
    [switch]$RemoveBackups
)

# Import UI module
$ModulePath = Join-Path $PSScriptRoot "..\.config\powershell\modules"
Import-Module (Join-Path $ModulePath "UI.psm1") -Force

$DotfileRepoPath = "$env:USERPROFILE\.dotfile"
$BackupPath = "$env:USERPROFILE\.dotfiles_backup_$(Get-Date -Format 'yyyyMMdd')"

function Show-QuickUninstallSummary {
    if (-not $Quiet) {
        Write-Info @"
Quick Uninstall will:
- Remove the dotfile repository: $DotfileRepoPath
- Remove 'dot' function from PowerShell profile
- Remove XDG environment variables
- Remove Oh-My-Posh theme directory

But WILL NOT remove:
- Neovim/Vim installations
- Git, Node.js, or other tools
- Personal configurations
- Windows Terminal application (just custom settings)

Proceed? (Y/N)
"@

        $confirm = Read-Host
        return ($confirm -eq "Y" -or $confirm -eq "y")
    }
    return $true
}

function Remove-DotRepository {
    if (Test-Path $DotfileRepoPath) {
        Write-Info "Removing dotfile repository..."
        Remove-Item -Path $DotfileRepoPath -Recurse -Force -ErrorAction SilentlyContinue
        Write-Success "Dotfile repository removed"
    }
}

function Remove-DotFunction {
    $profilePaths = @(
        "$env:USERPROFILE\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1",
        "$env:PROFILE.CurrentUserCurrentHost"
    )

    foreach ($profilePath in $profilePaths) {
        if (Test-Path $profilePath) {
            $content = Get-Content $profilePath -Raw
            $updatedContent = $content -replace '# dotfile管理\s*\n.*?function dot\s*\{.*?git --git-dir=.*?\s*\}.*?\n', ''

            if ($updatedContent -ne $content) {
                $updatedContent | Out-File $profilePath -Encoding utf8
                Write-Info "Removed 'dot' function from profile"
            }
        }
    }
}

function Remove-XDGVariables {
    $profilePaths = @(
        "$env:USERPROFILE\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1"
    )

    foreach ($profilePath in $profilePaths) {
        if (Test-Path $profilePath) {
            $content = Get-Content $profilePath -Raw
            $updatedContent = $content -replace '# XDG Base Directory Specification - Enable Linux-style paths on Windows.*?\n.*?\}', ''

            if ($updatedContent -ne $content) {
                $updatedContent | Out-File $profilePath -Encoding utf8
                Write-Info "Removed XDG variables from profile"
            }
        }
    }
}

function Remove-OhMyPosh {
    $themePath = "$env:USERPROFILE\.poshthemes"
    if (Test-Path $themePath) {
        Remove-Item -Path $themePath -Recurse -Force -ErrorAction SilentlyContinue
        Write-Info "Removed Oh-My-Posh themes"
    }

    # Remove from profile
    $profilePaths = @(
        "$env:USERPROFILE\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1"
    )

    foreach ($profilePath in $profilePaths) {
        if (Test-Path $profilePath) {
            $content = Get-Content $profilePath -Raw
            $updatedContent = $content -replace '# Oh-My-Posh 主题引擎.*?\n.*?oh-my-posh.*?\n.*?Invoke-Expression.*?\n', ''

            if ($updatedContent -ne $content) {
                $updatedContent | Out-File $profilePath -Encoding utf8
                Write-Info "Removed Oh-My-Posh from profile"
            }
        }
    }
}

function Remove-Backups {
    if ($RemoveBackups -and (Test-Path $BackupPath)) {
        Remove-Item -Path $BackupPath -Recurse -Force -ErrorAction SilentlyContinue
        Write-Info "Removed backup files"
    }
}

# Main execution
if (-not (Show-QuickUninstallSummary)) {
    Write-Info "Uninstall cancelled"
    exit 0
}

Write-Info "Starting quick uninstall..."

Remove-DotRepository
Remove-DotFunction
Remove-XDGVariables
Remove-OhMyPosh
Remove-Backups

Write-Success "Quick uninstall completed!"
Write-Info "Restart PowerShell to see all changes"

if (-not $Quiet) {
    Write-Host "`nPress any key to exit..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}