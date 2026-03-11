# ============================================
# ConfigDeployer Module - Configuration Deployment Functions
# ============================================

<#
.SYNOPSIS
    Provides functions for deploying configuration files to their appropriate locations.

.DESCRIPTION
    This module handles the deployment of various configuration files including
    Oh-My-Posh themes, Neovim configurations, PowerShell profiles, and Windows Terminal settings.

.EXPORTED FUNCTIONS
    Initialize-PoshThemesDirectory, Deploy-DefaultTheme, Get-DefaultThemeContent,
    Get-BuiltinThemes, Deploy-VimRuntime, Deploy-NeovimConfig, Deploy-AllNeovimConfig,
    Deploy-PowerShellProfile, Deploy-WindowsTerminalSettings
#>

# Import UI module for output functions
Import-Module (Join-Path $PSScriptRoot 'UI.psm1') -ErrorAction SilentlyContinue

<#
.SYNOPSIS
    Create and initialize the .poshthemes directory.

.DESCRIPTION
    Creates the .poshthemes directory in the user's profile if it doesn't exist
    and ensures it's properly configured.

.EXAMPLE
    Initialize-PoshThemesDirectory
#>
function Initialize-PoshThemesDirectory {
    [CmdletBinding()]
    param()

    Write-Info "Initializing Oh-My-Posh themes directory..."
    $poshThemesDir = "$env:USERPROFILE\.poshthemes"

    if (-not (Test-Path $poshThemesDir)) {
        try {
            New-Item -ItemType Directory -Path $poshThemesDir -Force | Out-Null
            Write-Success "Created .poshthemes directory at: $poshThemesDir"
            return $true
        } catch {
            Write-ErrorCustom "Failed to create .poshthemes directory: $_"
            return $false
        }
    } else {
        Write-Success ".poshthemes directory already exists"
        return $true
    }
}

<#
.SYNOPSIS
    Returns the JSON content for a simple default Oh-My-Posh theme.

.DESCRIPTION
    Generates a clean, simple theme JSON that works well on Windows.

.EXAMPLE
    Get-DefaultThemeContent
#>
function Get-DefaultThemeContent {
    [CmdletBinding()]
    param()

    return @"
{
  "`$schema": "https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/schema.json",
  "final_space": true,
  "version": 2,
  "blocks": [
    {
      "type": "prompt",
      "alignment": "left",
      "segments": [
        {
          "type": "root",
          "style": "plain",
          "foreground": "#ff5555",
          "template": " "
        },
        {
          "type": "session",
          "style": "plain",
          "foreground": "#ffffff",
          "template": "{{ .UserName }}@{{ .HostName }} "
        },
        {
          "type": "path",
          "style": "plain",
          "foreground": "#61afef",
          "template": "{{ .Path }} ",
          "properties": {
            "style": "full"
          }
        },
        {
          "type": "git",
          "style": "plain",
          "foreground": "#98c379",
          "template": "{{ .HEAD }}{{ .BranchStatus }} ",
          "properties": {
            "branch_icon": "",
            "commit_icon": "@",
            "tag_icon": "#"
          }
        }
      ]
    },
    {
      "type": "prompt",
      "alignment": "right",
      "segments": [
        {
          "type": "node",
          "style": "plain",
          "foreground": "#689f63",
          "template": "  {{ if .Error }}{{ .Error }}{{ else }}{{ if .Version }}v{{ .Version }}{{ end }}{{ end }} ",
          "properties": {
            "display_mode": "files",
            "fetch_version": true
          }
        },
        {
          "type": "python",
          "style": "plain",
          "foreground": "#e06c75",
          "template": "  {{ if .Error }}{{ .Error }}{{ else }}{{ if .Venv }}{{ .Venv }} {{ end }}{{ if .Version }}v{{ .Version }}{{ end }}{{ end }} ",
          "properties": {
            "display_mode": "files",
            "fetch_version": true
          }
        }
      ]
    }
  ],
  "newline": true
}
"@
}

<#
.SYNOPSIS
    Deploy a default Oh-My-Posh theme to the .poshthemes directory.

.DESCRIPTION
    Creates a simple.omp.json theme file in the .poshthemes directory
    if it doesn't already exist.

.EXAMPLE
    Deploy-DefaultTheme
#>
function Deploy-DefaultTheme {
    [CmdletBinding()]
    param()

    Write-Info "Deploying default Oh-My-Posh theme..."
    $themePath = "$env:USERPROFILE\.poshthemes\simple.omp.json"

    if (Test-Path $themePath) {
        Write-Success "Theme file already exists: $themePath"
        return $true
    }

    try {
        # First ensure the directory exists
        if (-not (Initialize-PoshThemesDirectory)) {
            Write-WarningCustom "Failed to initialize .poshthemes directory"
            return $false
        }

        # Write the default theme
        Get-DefaultThemeContent | Out-File -FilePath $themePath -Encoding utf8
        Write-Success "Default theme created at: $themePath"
        return $true
    } catch {
        Write-ErrorCustom "Failed to create default theme: $_"
        return $false
    }
}

<#
.SYNOPSIS
    Try to download or use built-in Oh-My-Posh themes.

.DESCRIPTION
    Attempts to use oh-my-posh to get the themes cache path and
    downloads themes if needed.

.EXAMPLE
    Get-BuiltinThemes
#>
function Get-BuiltinThemes {
    [CmdletBinding()]
    param()

    Write-Info "Checking for built-in Oh-My-Posh themes..."

    if (-not (Get-Command oh-my-posh -ErrorAction SilentlyContinue)) {
        Write-WarningCustom "Oh-My-Posh not installed, skipping built-in themes"
        return $false
    }

    try {
        # Try to get the cache path where themes are stored
        $cachePath = & oh-my-posh cache path 2>$null

        if ($cachePath -and (Test-Path $cachePath)) {
            Write-Success "Oh-My-Posh cache path: $cachePath"
            return $true
        } else {
            Write-WarningCustom "Could not determine Oh-My-Posh cache path"
            return $false
        }
    } catch {
        Write-WarningCustom "Failed to get Oh-My-Posh theme information: $_"
        return $false
    }
}

<#
.SYNOPSIS
    Deploy .vim directory to Windows Neovim runtime path.

.DESCRIPTION
    On Windows, Neovim uses $env:LOCALAPPDATA\nvim-data\vimfiles\ as the runtime path
    (equivalent to ~/.vim on Unix). This function copies .vim contents there.
    Uses XDG_DATA_HOME environment variable if set for better XDG compliance.

.PARAMETER SourcePath
    Path to the source .vim directory (default: ".vim" relative to current location).

.EXAMPLE
    Deploy-VimRuntime
#>
function Deploy-VimRuntime {
    [CmdletBinding()]
    param(
        [string]$SourcePath = ".vim"
    )

    Write-Info "Deploying Vim runtime files (.vim)..."

    # Use XDG_DATA_HOME if set, otherwise fall back to default Windows path
    if ($env:XDG_DATA_HOME) {
        $vimTarget = Join-Path $env:XDG_DATA_HOME "vim-data\vimfiles"
        Write-Info "Using XDG_DATA_HOME for vimfiles: $vimTarget"
    } else {
        $vimTarget = "$env:LOCALAPPDATA\nvim-data\vimfiles"
        Write-Info "Using default Windows path for vimfiles: $vimTarget"
    }

    if (-not (Test-Path $SourcePath)) {
        Write-WarningCustom ".vim directory not found in dotfile, skipping"
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
        Copy-Item -Path "$SourcePath\*" -Destination $vimTarget -Recurse -Force -ErrorAction Stop
        Write-Success "Vim runtime files deployed to: $vimTarget"
        return $true
    } catch {
        Write-ErrorCustom "Failed to deploy Vim runtime files: $_"
        return $false
    }
}

<#
.SYNOPSIS
    Deploy .config/nvim to Windows Neovim config path with XDG support.

.DESCRIPTION
    On Windows, Neovim uses $env:LOCALAPPDATA\nvim\ as the config path
    (equivalent to ~/.config/nvim on Unix). This function:
    1. Sets XDG_CONFIG_HOME environment variable permanently
    2. Keeps Windows path as backup while using Linux path as primary
    3. Ensures lazy-lock.json is included in sync
    4. Provides proper error handling and user feedback

.PARAMETER SourcePath
    Path to the source nvim config directory (default: ".config\nvim" relative to current location).

.EXAMPLE
    Deploy-NeovimConfig
#>
function Deploy-NeovimConfig {
    [CmdletBinding()]
    param(
        [string]$SourcePath = ".config\nvim"
    )

    Write-Info "Deploying Neovim configuration (.config/nvim)..."

    # Define both paths for dual deployment
    if ($env:XDG_CONFIG_HOME) {
        $nvimTargetLinux = Join-Path $env:XDG_CONFIG_HOME "nvim"
        Write-Info "Using XDG_CONFIG_HOME for nvim config: $nvimTargetLinux"
    } else {
        # Set XDG_CONFIG_HOME to ~/.local if not already set
        $env:XDG_CONFIG_HOME = "$env:USERPROFILE\.local\config"
        $nvimTargetLinux = Join-Path $env:XDG_CONFIG_HOME "nvim"
        Write-Info "Setting XDG_CONFIG_HOME to: $env:XDG_CONFIG_HOME"
    }

    $nvimTargetWindows = "$env:LOCALAPPDATA\nvim"

    if (-not (Test-Path $SourcePath)) {
        Write-WarningCustom ".config/nvim directory not found in dotfile, skipping"
        return $false
    }

    # Deploy to Linux-style path (primary)
    Write-Info "Deploying to primary config path (XDG): $nvimTargetLinux"
    if (-not (Test-Path $nvimTargetLinux)) {
        New-Item -ItemType Directory -Path $nvimTargetLinux -Force | Out-Null
        Write-Info "Created directory: $nvimTargetLinux"
    }

    # Backup existing nvim config if it exists
    if (Test-Path "$nvimTargetLinux\*") {
        $backupPath = "$env:USERPROFILE\.nvim_config_backup_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
        Write-Info "Backing up existing Neovim config to: $backupPath"
        Copy-Item -Path $nvimTargetLinux -Destination $backupPath -Recurse -Force
    }

    # Copy contents to Linux path
    try {
        Copy-Item -Path "$SourcePath\*" -Destination $nvimTargetLinux -Recurse -Force -ErrorAction Stop
        Write-Success "Neovim configuration deployed to primary path: $nvimTargetLinux"

        # Verify lazy-lock.json is included
        $lazyLockFile = Join-Path $nvimTargetLinux "lazy-lock.json"
        if (Test-Path $lazyLockFile) {
            Write-Success "lazy-lock.json is present in configuration"
        } else {
            Write-Info "lazy-lock.json not found (will be generated by lazy.nvim)"
        }

        # Also create symlink/copy to Windows path for compatibility
        Write-Info "Creating backup copy to Windows path for compatibility: $nvimTargetWindows"
        if (-not (Test-Path $nvimTargetWindows)) {
            New-Item -ItemType Directory -Path $nvimTargetWindows -Force | Out-Null
        }
        Copy-Item -Path "$SourcePath\*" -Destination $nvimTargetWindows -Recurse -Force -ErrorAction Stop
        Write-Success "Backup copy created at: $nvimTargetWindows"

        # Set XDG_CONFIG_HOME permanently in user environment
        try {
            $currentXdgConfig = [System.Environment]::GetEnvironmentVariable("XDG_CONFIG_HOME", "User")
            if (-not $currentXdgConfig) {
                Write-Info "Setting XDG_CONFIG_HOME permanently in user environment..."
                [System.Environment]::SetEnvironmentVariable("XDG_CONFIG_HOME", $env:XDG_CONFIG_HOME, "User")
                Write-Success "XDG_CONFIG_HOME set to: $env:XDG_CONFIG_HOME"
                Write-Info "You may need to restart your shell for this to take effect"
            } else {
                Write-Success "XDG_CONFIG_HOME already set in user environment: $currentXdgConfig"
            }
        } catch {
            Write-WarningCustom "Could not set XDG_CONFIG_HOME permanently: $_"
            Write-Info "XDG_CONFIG_HOME will be available for current session only"
        }

        return $true
    } catch {
        Write-ErrorCustom "Failed to deploy Neovim configuration: $_"
        return $false
    }
}

<#
.SYNOPSIS
    Deploy all Neovim-related configuration for Windows.

.DESCRIPTION
    Orchestrates deployment of both Vim runtime files and Neovim config
    with verification steps to ensure everything is working correctly.

.EXAMPLE
    Deploy-AllNeovimConfig
#>
function Deploy-AllNeovimConfig {
    [CmdletBinding()]
    param()

    Write-SectionHeader "Deploying Neovim configuration for Windows"

    $vimRuntimeResult = Deploy-VimRuntime
    $nvimConfigResult = Deploy-NeovimConfig

    if ($vimRuntimeResult -or $nvimConfigResult) {
        Write-Success "Neovim configuration deployment completed"
        Write-Info "Neovim paths:"

        # Show both XDG and Windows paths
        if ($env:XDG_CONFIG_HOME) {
            Write-Info "  - Config (XDG):   $env:XDG_CONFIG_HOME\nvim"
        } else {
            Write-Info "  - Config (XDG):   $env:USERPROFILE\.local\config\nvim"
        }
        Write-Info "  - Config (Windows): $env:LOCALAPPDATA\nvim"

        if ($env:XDG_DATA_HOME) {
            Write-Info "  - Runtime (XDG):   $env:XDG_DATA_HOME\vim-data\vimfiles"
        } else {
            Write-Info "  - Runtime (XDG):   $env:USERPROFILE\.local\data\vim-data\vimfiles"
        }
        Write-Info "  - Runtime (Windows): $env:LOCALAPPDATA\nvim-data\vimfiles"

        return $true
    } else {
        Write-WarningCustom "No Neovim configuration files found to deploy"
        return $false
    }
}

<#
.SYNOPSIS
    Deploy PowerShell profile configuration.

.PARAMETER SourcePath
    Path to the source profile.ps1 file (default: ".config/powershell/profile.ps1").

.EXAMPLE
    Deploy-PowerShellProfile
#>
function Deploy-PowerShellProfile {
    [CmdletBinding()]
    param(
        [string]$SourcePath = ".config/powershell/profile.ps1"
    )

    Write-Info "Configuring PowerShell Profile..."
    $profileDir = Split-Path -Parent $PROFILE.CurrentUserCurrentHost
    $profilePath = $PROFILE.CurrentUserCurrentHost

    if (-not (Test-Path $profileDir)) {
        New-Item -ItemType Directory -Path $profileDir -Force | Out-Null
    }

    if (Test-Path $profilePath) {
        $backupPath = "$profilePath.backup"
        Write-WarningCustom "Existing profile found, backing up to: $backupPath"
        Copy-Item $profilePath $backupPath -Force
    }

    if (Test-Path $SourcePath) {
        Write-Info "Deploying profile from dotfile..."
        Copy-Item $SourcePath $profilePath -Force
    } else {
        Write-WarningCustom "Profile not found in dotfile, creating default profile..."
        # Create a minimal default profile
        $defaultProfile = @'
# ============================================
# PowerShell Configuration
# ============================================

# Oh-My-Posh Theme Engine
$env:POSH_THEMES_PATH = "$env:USERPROFILE\.poshthemes"
if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) {
    # Try to use a custom theme, fall back to built-in theme
    $customTheme = "$env:POSH_THEMES_PATH\simple.omp.json"
    if (Test-Path $customTheme) {
        oh-my-posh init pwsh --config $customTheme | Invoke-Expression
    } else {
        # Use built-in theme as fallback
        oh-my-posh init pwsh --config "$env:POSH_THEMES_PATH\jandedobbeleer.omp.json" | Invoke-Expression
    }
}

# PSReadLine - Compatible with version 2.0.0+
if (Get-Module -ListAvailable -Name PSReadLine) {
    Import-Module PSReadLine
    # Basic key bindings that work with all PSReadLine versions
    Set-PSReadLineKeyHandler -Key "Tab" -Function MenuComplete
    Set-PSReadLineKeyHandler -Key "Ctrl+d" -Function DeleteChar
    Set-PSReadLineKeyHandler -Key "Ctrl+w" -Function BackwardDeleteWord
}

# Terminal-Icons
if (Get-Module -ListAvailable -Name Terminal-Icons) {
    Import-Module Terminal-Icons
}

# zoxide
if (Get-Command zoxide -ErrorAction SilentlyContinue) {
    Invoke-Expression (& { (zoxide init powershell | Out-String) })
}

# PSFzf
if (Get-Module -ListAvailable -Name PSFzf) {
    Import-Module PSFzf
    Set-PsFzfOption -PSReadlineChordProvider Ctrl+t -PsReadlineChordReverseHistory Ctrl+r
}

# dotfile management
function dot {
    git --git-dir="$env:USERPROFILE\.dotfile" --work-tree="$env:USERPROFILE" $args
}

# Aliases (avoiding conflicts with built-in aliases)
Set-Alias ll Get-ChildItem
Set-Alias grep Select-String

# Custom functions
function Edit-Profile { & $env:EDITOR $PROFILE.CurrentUserCurrentHost }
function Reload-Profile { . $PROFILE.CurrentUserCurrentHost }
function Show-Env { Get-ChildItem Env: | Format-Table -AutoSize }
'@
        $defaultProfile | Out-File -FilePath $profilePath -Encoding utf8
    }

    # Ensure the theme directory and default theme are deployed
    Deploy-DefaultTheme

    Write-Success "PowerShell Profile configuration completed"
    Write-Info "Please run '. \$PROFILE' or restart PowerShell to apply configuration"
}

<#
.SYNOPSIS
    Deploy Windows Terminal settings.

.PARAMETER SourcePath
    Path to the source settings.json file (default: ".config/windows-terminal/settings.json").

.EXAMPLE
    Deploy-WindowsTerminalSettings
#>
function Deploy-WindowsTerminalSettings {
    [CmdletBinding()]
    param(
        [string]$SourcePath = ".config/windows-terminal/settings.json"
    )

    Write-Info "Configuring Windows Terminal..."
    $terminalSettingsPath = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"

    if (-not (Test-Path $terminalSettingsPath)) {
        Write-WarningCustom "Windows Terminal configuration file not found, skipping"
        return
    }

    $backupPath = "$terminalSettingsPath.backup"
    Write-Info "Backing up existing configuration to: $backupPath"
    Copy-Item $terminalSettingsPath $backupPath -Force

    if (Test-Path $SourcePath) {
        Write-Info "Deploying Windows Terminal configuration from dotfile..."
        Copy-Item $SourcePath $terminalSettingsPath -Force
        Write-Success "Windows Terminal configuration completed"
        Write-Info "Please restart Windows Terminal to apply configuration"
    } else {
        Write-WarningCustom "Windows Terminal configuration not found in dotfile"
    }
}

<#
.SYNOPSIS
    Configure Oh-My-Posh themes.

.DESCRIPTION
    Initializes the themes directory, deploys the default theme,
    and checks for built-in themes.

.EXAMPLE
    Configure-OhMyPoshThemes
#>
function Configure-OhMyPoshThemes {
    [CmdletBinding()]
    param()

    Write-SectionHeader "Configuring Oh-My-Posh themes"
    Initialize-PoshThemesDirectory
    Deploy-DefaultTheme
    Get-BuiltinThemes
}

# Export module members
Export-ModuleMember -Function @(
    'Initialize-PoshThemesDirectory',
    'Deploy-DefaultTheme',
    'Get-DefaultThemeContent',
    'Get-BuiltinThemes',
    'Deploy-VimRuntime',
    'Deploy-NeovimConfig',
    'Deploy-AllNeovimConfig',
    'Deploy-PowerShellProfile',
    'Deploy-WindowsTerminalSettings',
    'Configure-OhMyPoshThemes'
)
