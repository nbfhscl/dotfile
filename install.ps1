#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Windows development environment auto-install script

.DESCRIPTION
    Automatically install and configure Windows development tools including:
    - Windows Terminal, PowerShell 7
    - Git, Node.js, Neovim
    - Oh-My-Posh, PSReadLine and other enhancement tools
    - dotfile auto-deployment

    Usage (one-click install): irm https://raw.githubusercontent.com/nbfhscl/dotfile/refs/heads/master/install.ps1 | iex

.EXAMPLE
    .\install.ps1

.EXAMPLE
    .\install.ps1 -SkipTools -OnlyDotfile

.EXAMPLE
    irm https://raw.githubusercontent.com/nbfhscl/dotfile/refs/heads/master/install.ps1 | iex

.EXAMPLE
    irm https://raw.githubusercontent.com/nbfhscl/dotfile/refs/heads/master/install.ps1 | iex; .\install.ps1 -OnlyDotfile

.PARAMETER SkipTools
    Skip tool installation, only deploy dotfile

.PARAMETER OnlyDotfile
    Only deploy dotfile, no tool installation

.PARAMETER DryRun
    Dry run mode, only show what will be executed
#>

param(
    [switch]$SkipTools = $false,
    [switch]$OnlyDotfile = $false,
    [switch]$DryRun = $false
)

# If OnlyDotfile is specified, automatically set SkipTools
if ($OnlyDotfile) {
    $SkipTools = $true
}

# Configuration
$REPO_URL = "https://github.com/nbfhscl/dotfile.git"
$DOT_DIR = "$env:USERPROFILE\.dotfile"
$BACKUP_DIR = "$env:USERPROFILE\.dotfile_backup_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
$ALIAS_NAME = "dot"

# Color output helper functions
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

# Environment detection functions
function Test-PowerShellVersion {
    $currentVersion = $PSVersionTable.PSVersion
    Write-Info "Current PowerShell version: $currentVersion"

    if ($currentVersion.Major -lt 7) {
        Write-Warning "PowerShell 7.0 or higher is recommended, but continuing with PowerShell 5.1"
        # Write-Error "PowerShell 7.0 or higher is required"
        # Write-Info "Please run: winget install Microsoft.PowerShell"
        # exit 1
    }

    Write-Success "PowerShell version check passed"
    return $true
}

function Test-WingetAvailable {
    if (Get-Command winget -ErrorAction SilentlyContinue) {
        Write-Success "winget is installed"
        return $true
    } else {
        Write-Warning "winget is not installed"
        Write-Info "Please install Windows Package Manager from Microsoft Store"
        return $false
    }
}

function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    $isAdmin = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

    if ($isAdmin) {
        Write-Success "Administrator privileges check passed"
        return $true
    } else {
        Write-Warning "Administrator privileges not detected"
        Write-Info "Some operations may require administrator privileges"
        return $false
    }
}

# Manual installation download links
$ManualInstallLinks = @{
    "Git" = "https://git-scm.com/download/win"
    "Node.js" = "https://nodejs.org/"
    "Neovim" = "https://github.com/neovim/neovim/releases"
    "Windows Terminal" = "https://aka.ms/terminal"
    "PowerShell" = "https://github.com/PowerShell/PowerShell/releases"
}

function Show-ManualInstallHelp {
    param([string]$ToolName)

    if ($ManualInstallLinks.ContainsKey($ToolName)) {
        Write-Warning "Please install $ToolName manually:"
        Write-Info "Download URL: $($ManualInstallLinks[$ToolName])"
    }
}

function Install-Package {
    param(
        [string]$PackageName,
        [string]$WingetId,
        [switch]$Required = $true
    )

    if ($DryRun) {
        Write-Info "[DRY-RUN] Will install $PackageName (using winget)"
        return $true
    }

    # Check if already installed
    $packageCommand = $PackageName -replace ' ', ''
    if (Get-Command $packageCommand -ErrorAction SilentlyContinue) {
        Write-Success "$PackageName is already installed"
        return $true
    }

    Write-Info "Installing $PackageName..."

    if (-not (Test-WingetAvailable)) {
        if ($Required) {
            Write-Error "winget is not available, cannot install $PackageName"
            Show-ManualInstallHelp -ToolName $PackageName
            return $false
        } else {
            Write-Warning "Skipping optional tool $PackageName"
            return $true
        }
    }

    # Use winget to install
    $result = & winget install --id $WingetId --accept-source-agreements --accept-package-agreements -e 2>&1

    if ($LASTEXITCODE -eq 0) {
        Write-Success "$PackageName installation completed"

        # Refresh environment variables
        $machinePath = [System.Environment]::GetEnvironmentVariable("Path", "Machine")
        $userPath = [System.Environment]::GetEnvironmentVariable("Path", "User")
        $env:Path = $machinePath + ";" + $userPath
        return $true
    } else {
        Write-Error "$PackageName installation failed"
        if ($Required) {
            Show-ManualInstallHelp -ToolName $PackageName
        }
        return $false
    }
}

# Core tool installation functions
function Install-WindowsTerminal {
    if (Get-Command wt -ErrorAction SilentlyContinue) {
        Write-Success "Windows Terminal is installed"
        return $true
    }
    Write-Info "Installing Windows Terminal..."
    Install-Package -PackageName "Windows Terminal" -WingetId "Microsoft.WindowsTerminal"
}

function Install-PowerShell7 {
    if ($PSVersionTable.PSVersion.Major -ge 7) {
        Write-Success "PowerShell 7 is installed"
        return $true
    }
    Write-Info "Installing PowerShell 7..."
    Install-Package -PackageName "PowerShell" -WingetId "Microsoft.PowerShell"
}

function Install-Git {
    Write-Info "Installing Git..."
    Install-Package -PackageName "Git" -WingetId "Git.Git" -Required
}

function Install-Nodejs {
    Write-Info "Installing Node.js and npm..."
    Install-Package -PackageName "Node.js" -WingetId "OpenJS.NodeJS.LTS" -Required
}

function Install-Neovim {
    Write-Info "Installing Neovim..."
    $result = Install-Package -PackageName "Neovim" -WingetId "Neovim.Neovim" -Required

    if ($result) {
        Write-Info "Verifying Neovim installation..."
        if (Get-Command nvim -ErrorAction SilentlyContinue) {
            $nvimVersion = & nvim --version | Select-Object -First 1
            Write-Success "Neovim is installed: $nvimVersion"
        } else {
            Write-Warning "Neovim installation completed, but 'nvim' command not found in PATH"
            Write-Info "You may need to restart your shell or refresh your PATH"
        }
    }

    return $result
}

# ============================================
# Task 5: PowerShell module installation
# ============================================

function Install-OhMyPosh {
    if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) {
        Write-Success "Oh-My-Posh is installed"
        return $true
    }
    Write-Info "Installing Oh-My-Posh..."
    if ($DryRun) { return $true }
    try {
        & winget install --id JanDeDobbeleer.OhMyPosh -e --accept-source-agreements --accept-package-agreements 2>&1 | Out-Null
        if ($LASTEXITCODE -eq 0) {
            Write-Success "Oh-My-Posh installation completed"
            return $true
        } else {
            # Fallback: use PowerShell module
            Install-Module -Name oh-my-posh -Force -Scope CurrentUser -AllowClobber
            return $true
        }
    } catch {
        Write-Error "Oh-My-Posh installation failed: $_"
        return $false
    }
}

function Install-PSModules {
    $modules = @(
        @{ Name = "PSReadLine"; Required = $true },
        @{ Name = "Terminal-Icons"; Required = $false },
        @{ Name = "PSFzf"; Required = $false }
    )
    foreach ($module in $modules) {
        $moduleName = $module.Name
        $required = $module.Required
        if (Get-Module -ListAvailable -Name $moduleName) {
            Write-Success "$moduleName is already installed"
            continue
        }
        Write-Info "Installing $moduleName..."
        if ($DryRun) { continue }
        try {
            Install-Module -Name $moduleName -Force -Scope CurrentUser -AllowClobber -ErrorAction Stop
            Write-Success "$moduleName installation completed"
        } catch {
            if ($required) {
                Write-Error "$moduleName installation failed: $_"
            } else {
                Write-Warning "$moduleName installation failed (optional tool)"
            }
        }
    }
}

function Install-Zoxide {
    if (Get-Command zoxide -ErrorAction SilentlyContinue) {
        Write-Success "zoxide is installed"
        return $true
    }
    Write-Info "Installing zoxide..."
    Install-Package -PackageName "zoxide" -WingetId "ajeetdsouza.zoxide" -Required:$false
}

# ============================================
# Neovim Configuration Deployment
# ============================================

function Deploy-VimRuntime {
    <#
    .SYNOPSIS
        Deploy .vim directory to Windows Neovim runtime path

    .DESCRIPTION
        On Windows, Neovim uses $env:LOCALAPPDATA\nvim-data\vimfiles\ as the runtime path
        (equivalent to ~/.vim on Unix). This function copies .vim contents there.
    #>
    Write-Info "Deploying Vim runtime files (.vim)..."
    $vimSource = ".vim"
    $vimTarget = "$env:LOCALAPPDATA\nvim-data\vimfiles"

    if (-not (Test-Path $vimSource)) {
        Write-Warning ".vim directory not found in dotfile, skipping"
        return $false
    }

    # Create target directory if it doesn't exist
    if (-not (Test-Path $vimTarget)) {
        New-Item -ItemType Directory -Path $vimTarget -Force | Out-Null
        Write-Info "Created directory: $vimTarget"
    }

    # Backup existing vimfiles if they exist
    if (Test-Path "$vimTarget\*") {
        $backupPath = "$env:USERPROFILE\.vimfiles_backup_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
        Write-Info "Backing up existing vimfiles to: $backupPath"
        Copy-Item -Path $vimTarget -Destination $backupPath -Recurse -Force
    }

    # Copy contents
    try {
        Copy-Item -Path "$vimSource\*" -Destination $vimTarget -Recurse -Force -ErrorAction Stop
        Write-Success "Vim runtime files deployed to: $vimTarget"
        return $true
    } catch {
        Write-Error "Failed to deploy Vim runtime files: $_"
        return $false
    }
}

function Deploy-NeovimConfig {
    <#
    .SYNOPSIS
        Deploy .config/nvim to Windows Neovim config path

    .DESCRIPTION
        On Windows, Neovim uses $env:LOCALAPPDATA\nvim\ as the config path
        (equivalent to ~/.config/nvim on Unix). This function copies nvim config there.
    #>
    Write-Info "Deploying Neovim configuration (.config/nvim)..."
    $nvimSource = ".config\nvim"
    $nvimTarget = "$env:LOCALAPPDATA\nvim"

    if (-not (Test-Path $nvimSource)) {
        Write-Warning ".config/nvim directory not found in dotfile, skipping"
        return $false
    }

    # Create target directory if it doesn't exist
    if (-not (Test-Path $nvimTarget)) {
        New-Item -ItemType Directory -Path $nvimTarget -Force | Out-Null
        Write-Info "Created directory: $nvimTarget"
    }

    # Backup existing nvim config if it exists
    if (Test-Path "$nvimTarget\*") {
        $backupPath = "$env:USERPROFILE\.nvim_config_backup_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
        Write-Info "Backing up existing Neovim config to: $backupPath"
        Copy-Item -Path $nvimTarget -Destination $backupPath -Recurse -Force
    }

    # Copy contents
    try {
        Copy-Item -Path "$nvimSource\*" -Destination $nvimTarget -Recurse -Force -ErrorAction Stop
        Write-Success "Neovim configuration deployed to: $nvimTarget"
        return $true
    } catch {
        Write-Error "Failed to deploy Neovim configuration: $_"
        return $false
    }
}

function Deploy-AllNeovimConfig {
    <#
    .SYNOPSIS
        Deploy all Neovim-related configuration for Windows

    .DESCRIPTION
        Orchestrates deployment of both Vim runtime files and Neovim config
    #>
    Write-Info "=========================================="
    Write-Info "Deploying Neovim configuration for Windows"
    Write-Info "=========================================="

    $vimRuntimeResult = Deploy-VimRuntime
    $nvimConfigResult = Deploy-NeovimConfig

    if ($vimRuntimeResult -or $nvimConfigResult) {
        Write-Success "Neovim configuration deployment completed"
        Write-Info "Neovim paths:"
        Write-Info "  - Config:  $env:LOCALAPPDATA\nvim"
        Write-Info "  - Runtime: $env:LOCALAPPDATA\nvim-data\vimfiles"
        return $true
    } else {
        Write-Warning "No Neovim configuration files found to deploy"
        return $false
    }
}

# ============================================
# Task 6: PowerShell Profile configuration
# ============================================

function Deploy-PowerShellProfile {
    Write-Info "Configuring PowerShell Profile..."
    $profileDir = Split-Path -Parent $PROFILE.CurrentUserCurrentHost
    $profilePath = $PROFILE.CurrentUserCurrentHost

    if (-not (Test-Path $profileDir)) {
        New-Item -ItemType Directory -Path $profileDir -Force | Out-Null
    }

    if (Test-Path $profilePath) {
        $backupPath = "$profilePath.backup"
        Write-Warning "Existing profile found, backing up to: $backupPath"
        Copy-Item $profilePath $backupPath -Force
    }

    $sourceProfile = ".config/powershell/profile.ps1"
    if (Test-Path $sourceProfile) {
        Write-Info "Deploying profile from dotfile..."
        Copy-Item $sourceProfile $profilePath -Force
    } else {
        Write-Warning "Profile not found in dotfile, skipping"
    }

    Write-Success "PowerShell Profile configuration completed"
    Write-Info "Please run '. \$PROFILE' or restart PowerShell to apply configuration"
}

# ============================================
# Task 7: dotfile deployment
# ============================================

function Initialize-DotfileRepo {
    if (Test-Path $DOT_DIR) {
        Write-Warning ".dotfile directory already exists, will update instead of cloning"
        Push-Location $DOT_DIR
        & git fetch origin 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Success "dotfile repository update completed"
        } else {
            Write-Warning "Update failed, will continue with existing version"
        }
        Pop-Location
    } else {
        Write-Info "Cloning dotfile repository..."
        & git clone --bare $REPO_URL $DOT_DIR 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Success "dotfile repository clone completed"
        } else {
            Write-Error "Failed to clone dotfile repository"
            exit 1
        }
    }
}

function Deploy-Dotfiles {
    Write-Info "Deploying dotfile..."

    function dot {
        & git --git-dir="$DOT_DIR" --work-tree="$env:USERPROFILE" $args
    }

    Write-Info "Checking for file conflicts..."
    $trackedFiles = dot ls-tree -r --name-only HEAD 2>$null
    $conflicts = @()

    foreach ($file in $trackedFiles) {
        $targetPath = Join-Path $env:USERPROFILE $file
        if (Test-Path $targetPath) {
            $conflicts += $file
        }
    }

    if ($conflicts.Count -gt 0) {
        Write-Warning "Found $($conflicts.Count) conflicting files, will backup..."
        New-Item -ItemType Directory -Path $BACKUP_DIR -Force | Out-Null

        foreach ($file in $conflicts) {
            $sourcePath = Join-Path $env:USERPROFILE $file
            $backupPath = Join-Path $BACKUP_DIR $file
            $backupDir = Split-Path -Parent $backupPath

            if (-not (Test-Path $backupDir)) {
                New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
            }

            Copy-Item $sourcePath $backupPath -Force
            Write-Info "  → Backup: $file"
        }

        Write-Success "Backup saved to: $BACKUP_DIR"
    } else {
        Write-Success "No conflicts found"
    }

    Write-Info "Deploying dotfile..."
    dot checkout -f 2>$null

    if ($LASTEXITCODE -eq 0) {
        Write-Success "dotfile deployment completed"
        dot config --local status.showUntrackedFiles no
        Deploy-WindowsTerminalSettings
        Add-DotAliasToProfile
        return $true
    } else {
        Write-Error "dotfile deployment failed"
        return $false
    }
}

function Deploy-WindowsTerminalSettings {
    Write-Info "Configuring Windows Terminal..."
    $terminalSettingsPath = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
    if (-not (Test-Path $terminalSettingsPath)) {
        Write-Warning "Windows Terminal configuration file not found, skipping"
        return
    }
    $backupPath = "$terminalSettingsPath.backup"
    Write-Info "Backing up existing configuration to: $backupPath"
    Copy-Item $terminalSettingsPath $backupPath -Force
    $sourceSettings = ".config/windows-terminal/settings.json"
    if (Test-Path $sourceSettings) {
        Write-Info "Deploying Windows Terminal configuration from dotfile..."
        Copy-Item $sourceSettings $terminalSettingsPath -Force
        Write-Success "Windows Terminal configuration completed"
        Write-Info "Please restart Windows Terminal to apply configuration"
    } else {
        Write-Warning "Windows Terminal configuration not found in dotfile"
    }
}

function Add-DotAliasToProfile {
    $profilePath = $PROFILE.CurrentUserCurrentHost
    $aliasLine = "function dot { git --git-dir=`$env:USERPROFILE\.dotfile --work-tree=`$env:USERPROFILE `$args }"

    if (-not (Test-Path $profilePath)) { return }

    $profileContent = Get-Content $profilePath -Raw
    if ($profileContent -notmatch 'function dot') {
        Write-Info "Adding 'dot' alias to PowerShell Profile..."
        Add-Content -Path $profilePath -Value "`n# dotfile alias (auto-added)`n$aliasLine"
        Write-Success "'dot' alias added"
    }
}

# ============================================
# Main process
# ============================================

function Install-AllTools {
    Write-Info "=========================================="
    Write-Info "Starting development tools installation"
    Write-Info "=========================================="

    Install-WindowsTerminal
    Install-PowerShell7
    Install-Git
    Install-Nodejs
    Install-Neovim
    Install-OhMyPosh
    Install-PSModules
    Install-Zoxide

    Write-Success "=========================================="
    Write-Success "Development tools installation completed"
    Write-Success "=========================================="
}

function main {
    Write-Info "=========================================="
    Write-Info "Windows development environment installation script"
    Write-Info "=========================================="

    if ($DryRun) {
        Write-Warning "Dry run mode enabled, only showing what will be executed"
    }

    # Environment detection
    Test-PowerShellVersion
    Test-WingetAvailable
    Test-Administrator

    # Install tools
    if (-not $SkipTools) {
        Install-AllTools
    } else {
        Write-Info "Skipping tool installation (-SkipTools or -OnlyDotfile specified)"
    }

    # Deploy dotfile
    Write-Info "=========================================="
    Write-Info "Starting dotfile deployment"
    Write-Info "=========================================="

    Initialize-DotfileRepo
    Deploy-Dotfiles
    Deploy-PowerShellProfile
    Deploy-AllNeovimConfig

    Write-Success "=========================================="
    Write-Success "All completed!"
    Write-Success "=========================================="
    Write-Info "Please restart PowerShell or run '. \$PROFILE' to apply all configurations"
}

# Execute main process
main