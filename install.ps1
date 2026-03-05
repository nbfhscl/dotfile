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

# Get the script directory
$ScriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { Get-Location }

# Import modules
$ModulePath = Join-Path $ScriptDir ".config\powershell\modules"

try {
    # Import new modules first (Common, Config, Uninstaller)
    Import-Module (Join-Path $ModulePath "Common.psm1") -ErrorAction Stop
    Import-Module (Join-Path $ModulePath "Config.psm1") -ErrorAction Stop
    Import-Module (Join-Path $ModulePath "Uninstaller.psm1") -ErrorAction Stop

    # Import existing modules
    Import-Module (Join-Path $ModulePath "UI.psm1") -ErrorAction Stop
    Import-Module (Join-Path $ModulePath "ToolInstaller.psm1") -ErrorAction Stop
    Import-Module (Join-Path $ModulePath "ConfigDeployer.psm1") -ErrorAction Stop
    Import-Module (Join-Path $ModulePath "Verifier.psm1") -ErrorAction Stop
    Import-Module (Join-Path $ModulePath "DotfileInstaller.psm1") -ErrorAction Stop
} catch {
    Write-ErrorCustom "Failed to import required modules: $_"
    exit 1
}

# Handle uninstall mode
if ($Uninstall) {
    Write-Info "Starting uninstallation..."

    # Use Uninstaller module instead of external script
    Invoke-QuickUninstall -Force
    exit 0
}

# If OnlyDotfile is specified, automatically set SkipTools
if ($OnlyDotfile) {
    $SkipTools = $true
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

    # Initialize logging
    $logConfig = Get-LoggingConfiguration
    $logFile = Initialize-Logging -LogDirectory $logConfig.LogDirectory -LogName "install" -IncludeDateInName

    Write-Log "Installation started" -LogFile $logFile -Level Info -PassThru

    # Environment detection
    Test-Environment

    # Get configuration
    $config = Get-AllConfiguration
    $xdgConfig = Get-XDGConfiguration

    # Initialize XDG paths
    Write-Info "Initializing XDG Base Directory paths..."
    Initialize-XDGPaths -SetEnvironment
    Write-Log "XDG paths initialized: Config=$($xdgConfig.ConfigHome), Data=$($xdgConfig.DataHome)" -LogFile $logFile -Level Info

    # Install tools
    if (-not $SkipTools) {
        Write-Log "Starting tool installation" -LogFile $logFile -Level Info
        Install-AllDevelopmentTools -DryRun:$DryRun

        # Configure Oh-My-Posh themes
        Configure-OhMyPoshThemes
        Write-Log "Tool installation completed" -LogFile $logFile -Level Info
    } else {
        Write-Info "Skipping tool installation (-SkipTools or -OnlyDotfile specified)"
        Write-Log "Tool installation skipped" -LogFile $logFile -Level Warning
    }

    # Deploy dotfile
    Write-SectionHeader "Starting dotfile deployment"

    try {
        Initialize-DotfileRepo
        Write-Log "Dotfile repository initialized" -LogFile $logFile -Level Info

        Deploy-Dotfiles
        Write-Log "Dotfiles deployed" -LogFile $logFile -Level Info

        Deploy-PowerShellProfile
        Write-Log "PowerShell profile deployed" -LogFile $logFile -Level Info

        Deploy-AllNeovimConfig
        Write-Log "Neovim configuration deployed" -LogFile $logFile -Level Info
    } catch {
        $errorMsg = "Dotfile deployment failed: $_"
        Write-ErrorCustom $errorMsg
        Write-Log $errorMsg -LogFile $logFile -Level Error
        throw
    }

    Write-SectionComplete "All completed!"

    Write-Info "Please restart PowerShell or run '. \$PROFILE' to apply all configurations"
    Write-Log "Installation completed successfully" -LogFile $logFile -Level Info
}

# Execute main process
try {
    Install-DevEnvironment
} catch {
    Write-ErrorCustom "Installation failed: $_"
    exit 1
} finally {
    Pop-Location
}
