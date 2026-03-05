#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Windows development environment installer and uninstaller

.DESCRIPTION
    This script manages both installation and uninstallation of dotfile configurations.

    INSTALLATION: Automatically install and configure Windows development tools including:
    - Windows Terminal, PowerShell 7
    - Git, Node.js, Neovim
    - Oh-My-Posh, PSReadLine and other enhancement tools
    - dotfile auto-deployment

    Usage (one-click install): irm https://raw.githubusercontent.com/nbfhscl/dotfile/refs/heads/master/install.ps1 | iex

    UNINSTALLATION: Clean removal of dotfile configurations while keeping tools intact.

.EXAMPLE
    .\install.ps1                               # Full installation

.EXAMPLE
    .\install.ps1 -SkipTools                    # Skip tools, only deploy dotfile

.EXAMPLE
    .\install.ps1 -OnlyDotfile                  # Only deploy dotfile, no tools

.EXAMPLE
    .\install.ps1 -Uninstall                    # Remove dotfile configurations

.EXAMPLE
    .\install.ps1 -DryRun                       # Show what would be done

.PARAMETER SkipTools
    Skip tool installation, only deploy dotfile

.PARAMETER OnlyDotfile
    Only deploy dotfile, no tool installation

.PARAMETER DryRun
    Dry run mode, only show what will be executed

.PARAMETER Uninstall
    Remove dotfile configuration
#>

[CmdletBinding()]
param(
    [switch]$SkipTools = $false,
    [switch]$OnlyDotfile = $false,
    [switch]$DryRun = $false,
    [switch]$Uninstall = $false
)

# Handle uninstall mode
if ($Uninstall) {
    Write-Info "Starting uninstallation..."
    $uninstallScript = Join-Path $ScriptDir "scripts\Quick-Uninstall.ps1"

    if (Test-Path $uninstallScript) {
        & $uninstallScript
    } else {
        Write-Error "Uninstall script not found: $uninstallScript"
        exit 1
    }
    exit 0
}

# If OnlyDotfile is specified, automatically set SkipTools
if ($OnlyDotfile) {
    $SkipTools = $true
}

# Get the script directory
$ScriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { Get-Location }

# Import modules
$ModulePath = Join-Path $ScriptDir ".config\powershell\modules"

try {
    Import-Module (Join-Path $ModulePath "UI.psm1") -ErrorAction Stop
    Import-Module (Join-Path $ModulePath "ToolInstaller.psm1") -ErrorAction Stop
    Import-Module (Join-Path $ModulePath "ConfigDeployer.psm1") -ErrorAction Stop
    Import-Module (Join-Path $ModulePath "Verifier.psm1") -ErrorAction Stop
    Import-Module (Join-Path $ModulePath "DotfileInstaller.psm1") -ErrorAction Stop
} catch {
    Write-Host "[ERROR] Failed to import required modules: $_" -ForegroundColor Red
    exit 1
}

# Change to the script directory (assuming we're in the dotfile repo)
$DotfileRoot = if (Test-Path (Join-Path $ScriptDir ".config")) {
    $ScriptDir
} else {
    Split-Path -Parent $ScriptDir
}

Push-Location $DotfileRoot

<#
.SYNOPSIS
    Main installation function
#>
function Install-DevEnvironment {
    [CmdletBinding()]
    param()

    Write-SectionHeader "Windows development environment installation script"

    if ($DryRun) {
        Write-WarningCustom "Dry run mode enabled, only showing what will be executed"
    }

    # Environment detection
    Test-Environment

    # Install tools
    if (-not $SkipTools) {
        Install-AllDevelopmentTools -DryRun:$DryRun

        # Configure Oh-My-Posh themes
        Configure-OhMyPoshThemes
    } else {
        Write-Info "Skipping tool installation (-SkipTools or -OnlyDotfile specified)"
    }

    # Deploy dotfile
    Write-SectionHeader "Starting dotfile deployment"

    Initialize-DotfileRepo
    Deploy-Dotfiles
    Deploy-PowerShellProfile
    Deploy-AllNeovimConfig

    Write-SectionComplete "All completed!"

    Write-Info "Please restart PowerShell or run '. \$PROFILE' to apply all configurations"
}

# Execute main process
try {
    Install-DevEnvironment
} finally {
    Pop-Location
}
