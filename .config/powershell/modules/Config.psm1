# ============================================
# Config Module - Centralized Configuration Data
# ============================================

<#
.SYNOPSIS
    Centralized configuration module for the dotfile management system.

.DESCRIPTION
    This module serves as the single source of truth for all configuration data
    in the dotfile management system. It consolidates:
    - Tool definitions (Git, Node.js, Neovim, PowerShell, etc.)
    - Download URLs and installation parameters
    - PowerShell modules with versions
    - Configuration file paths and templates
    - XDG Base Directory configuration
    - Offline deployment settings
    - Color scheme and UI configuration
    - Validation rules and requirements

    All other modules should import this module for configuration data
    instead of defining their own constants or hardcoded values.

.NOTES
    Version: 1.0.0
    Author: Dotfile Management System
    Last Updated: 2025-01-06
#>

# ============================================
# Script-Level Variables (Private)
# ============================================

$script:ConfigVersion = "1.0.0"
$script:ConfigLastUpdated = "2025-01-06"

# ============================================
# Public Configuration Data
# ============================================

<#
.SYNOPSIS
    Get all tool definitions.

.DESCRIPTION
    Returns a hashtable containing all tool definitions with their properties
    including display names, winget IDs, versions, URLs, and installation parameters.
#>
function Get-ToolDefinitions {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param()

    return @{
        # Git - Version Control System
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
            InstallScript       = "winget install --id Git.Git --accept-source-agreements --accept-package-agreements -e"
            VerificationCommand = "git --version"
            Description         = "Distributed version control system"
        }

        # Node.js - JavaScript Runtime
        NodeJS = @{
            Name                = "Node.js"
            DisplayName         = "Node.js LTS"
            WingetId            = "OpenJS.NodeJS.LTS"
            MinVersion          = "18.17.0"
            Command             = "node"
            SecondaryCommands   = @("npm")
            DownloadUrl         = "https://nodejs.org/"
            Required            = $true
            Category            = "Development"
            Dependencies        = @("VCRedist2022")
            InstallScript       = "winget install --id OpenJS.NodeJS.LTS --accept-source-agreements --accept-package-agreements -e"
            VerificationCommand = "node --version"
            Description         = "JavaScript runtime and npm package manager"
        }

        # Neovim - Text Editor
        Neovim = @{
            Name                = "Neovim"
            DisplayName         = "Neovim"
            WingetId            = "Neovim.Neovim"
            MinVersion          = "0.9.0"
            Command             = "nvim"
            DownloadUrl         = "https://github.com/neovim/neovim/releases"
            Required            = $true
            Category            = "Development"
            Dependencies        = @()
            InstallScript       = "winget install --id Neovim.Neovim --accept-source-agreements --accept-package-agreements -e"
            VerificationCommand = "nvim --version"
            ConfigPaths         = @(
                "$env:USERPROFILE\.config\nvim",
                "$env:LOCALAPPDATA\nvim"
            )
            Description         = "Vim-fork focused on extensibility and usability"
        }

        # Windows Terminal - Terminal Emulator
        WindowsTerminal = @{
            Name                = "Windows Terminal"
            DisplayName         = "Windows Terminal"
            WingetId            = "Microsoft.WindowsTerminal"
            Command             = "wt"
            DownloadUrl         = "https://aka.ms/terminal"
            Required            = $false
            Category            = "System"
            Dependencies        = @()
            InstallScript       = "winget install --id Microsoft.WindowsTerminal --accept-source-agreements --accept-package-agreements -e"
            ConfigPath          = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
            Description         = "Modern terminal application for Windows"
        }

        # PowerShell 7 - Shell
        PowerShell = @{
            Name                = "PowerShell"
            DisplayName         = "PowerShell 7"
            WingetId            = "Microsoft.PowerShell"
            MinVersion          = "7.0.0"
            Command             = "pwsh"
            DownloadUrl         = "https://github.com/PowerShell/PowerShell/releases"
            Required            = $true
            Category            = "System"
            Dependencies        = @()
            InstallScript       = "winget install --id Microsoft.PowerShell --accept-source-agreements --accept-package-agreements -e"
            VerificationCommand = "`$PSVersionTable.PSVersion"
            Description         = "Modern command-line shell and scripting language"
        }

        # Oh-My-Posh - Theme Engine
        OhMyPosh = @{
            Name                = "Oh-My-Posh"
            DisplayName         = "Oh-My-Posh"
            WingetId            = "JanDeDobbeleer.OhMyPosh"
            Command             = "oh-my-posh"
            DownloadUrl         = "https://ohmyposh.dev/"
            Required            = $true
            Category            = "Productivity"
            Dependencies        = @()
            InstallScript       = "winget install --id JanDeDobbeleer.OhMyPosh --accept-source-agreements --accept-package-agreements -e"
            ThemePath           = "$env:USERPROFILE\.poshthemes"
            Description         = "Prompt theme engine for shells"
        }

        # Zoxide - Smart cd Command
        Zoxide = @{
            Name                = "Zoxide"
            DisplayName         = "Zoxide"
            WingetId            = "ajeetdsouza.zoxide"
            Command             = "zoxide"
            DownloadUrl         = "https://github.com/ajeetdsouza/zoxide"
            Required            = $false
            Category            = "Productivity"
            Dependencies        = @()
            InstallScript       = "winget install --id ajeetdsouza.zoxide --accept-source-agreements --accept-package-agreements -e"
            Description         = "A faster way to navigate your filesystem"
        }

        # Python - Programming Language
        Python = @{
            Name                = "Python"
            DisplayName         = "Python 3"
            WingetId            = "Python.Python.3"
            MinVersion          = "3.10.0"
            Command             = "python"
            SecondaryCommands   = @("pip")
            DownloadUrl         = "https://www.python.org/downloads/"
            Required            = $false
            Category            = "Development"
            Dependencies        = @("VCRedist2022")
            InstallScript       = "winget install --id Python.Python.3 --accept-source-agreements --accept-package-agreements -e"
            VerificationCommand = "python --version"
            Description         = "Programming language and runtime"
        }

        # .NET SDK - Development Framework
        DotNetSDK = @{
            Name                = "DotNetSDK"
            DisplayName         = ".NET SDK"
            WingetId            = "Microsoft.DotNet.SDK.8"
            MinVersion          = "8.0.0"
            Command             = "dotnet"
            DownloadUrl         = "https://dotnet.microsoft.com/download"
            Required            = $false
            Category            = "Development"
            Dependencies        = @()
            InstallScript       = "winget install --id Microsoft.DotNet.SDK.8 --accept-source-agreements --accept-package-agreements -e"
            VerificationCommand = "dotnet --version"
            Description         = ".NET development framework and SDK"
        }

        # Docker Desktop - Container Platform
        DockerDesktop = @{
            Name                = "Docker Desktop"
            DisplayName         = "Docker Desktop"
            WingetId            = "Docker.DockerDesktop"
            Command             = "docker"
            DownloadUrl         = "https://www.docker.com/products/docker-desktop/"
            Required            = $false
            Category            = "Development"
            Dependencies        = @()
            SizeWarning         = "Large package (~1GB)"
            InstallScript       = "winget install --id Docker.DockerDesktop --accept-source-agreements --accept-package-agreements -e"
            Description         = "Container platform for development"
        }

        # Visual Studio Code - Editor
        VSCode = @{
            Name                = "VSCode"
            DisplayName         = "Visual Studio Code"
            WingetId            = "Microsoft.VisualStudioCode"
            Command             = "code"
            DownloadUrl         = "https://code.visualstudio.com/"
            Required            = $false
            Category            = "Development"
            Dependencies        = @()
            InstallScript       = "winget install --id Microsoft.VisualStudioCode --accept-source-agreements --accept-package-agreements -e"
            Description         = "Code editor redefined and optimized for building"
        }
    }
}

<#
.SYNOPSIS
    Get PowerShell module definitions.

.DESCRIPTION
    Returns a hashtable of PowerShell modules with their versions and requirements.
#>
function Get-PowerShellModules {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param()

    return @{
        Required = @(
            @{ Name = "PSReadLine"; MinVersion = "2.2.0"; Description = "Improved command-line editing experience" },
            @{ Name = "Terminal-Icons"; MinVersion = "0.7.0"; Description = "Glyph icons for PowerShell files and folders" },
            @{ Name = "PSFzf"; MinVersion = "2.2.0"; Description = "Fuzzy finder integration for PowerShell" }
        )
        Optional = @(
            @{ Name = "posh-git"; MinVersion = "1.0.0"; Description = "Git integration for PowerShell" },
            @{ Name = "zoxide"; MinVersion = "0.7.0"; Description = "Smart cd command" }
        )
    }
}

<#
.SYNOPSIS
    Get PowerShell module definitions.

.DESCRIPTION
    Returns a hashtable of PowerShell modules with their versions and requirements.
#>
function Get-ModuleDefinitions {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param()

    return @{
        PSReadLine = @{
            Name        = "PSReadLine"
            MinVersion  = "2.2.0"
            Required    = $true
            Description = "Improved command-line editing experience"
            ImportName  = "PSReadLine"
        }
        TerminalIcons = @{
            Name        = "Terminal-Icons"
            MinVersion  = "0.7.0"
            Required    = $true
            Description = "Glyph icons for PowerShell files and folders"
            ImportName  = "Terminal-Icons"
        }
        PSFzf = @{
            Name        = "PSFzf"
            MinVersion  = "2.2.0"
            Required    = $true
            Description = "Fuzzy finder integration for PowerShell"
            ImportName  = "PSFzf"
        }
    }
}

<#
.SYNOPSIS
    Get runtime dependency definitions.

.DESCRIPTION
    Returns runtime dependencies like VC++ Redistributables.
#>
function Get-RuntimeDefinitions {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param()

    return @{
        VCRedist2022 = @{
            Name        = "VC++ Redistributable 2022"
            DisplayName = "Microsoft Visual C++ 2015-2022 Redistributable (x64)"
            DownloadUrl = "https://aka.ms/vs/17/release/vc_redist.x64.exe"
            Required    = $true
            Category    = "Runtime"
            Description = "Visual C++ libraries runtime"
        }
    }
}

<#
.SYNOPSIS
    Get dotfile repository configuration.

.DESCRIPTION
    Returns configuration settings for the dotfile bare repository.
#>
function Get-DotfileConfiguration {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param()

    return @{
        RepoUrl        = "https://github.com/nbfhscl/dotfile.git"
        DotDir         = "$env:USERPROFILE\.dotfile"
        AliasName      = "dot"
        Branch         = "master"
        BackupPattern  = ".dotfile_backup_{0}"
    }
}

<#
.SYNOPSIS
    Get XDG Base Directory configuration.

.DESCRIPTION
    Returns XDG Base Directory paths for Windows with defaults.
#>
function Get-XDGConfiguration {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param()

    return @{
        # XDG_CONFIG_HOME - User config files
        ConfigHome = $(
            if ($env:XDG_CONFIG_HOME) {
                $env:XDG_CONFIG_HOME
            } else {
                Join-Path $env:USERPROFILE ".config"
            }
        )

        # XDG_DATA_HOME - User data files
        DataHome = $(
            if ($env:XDG_DATA_HOME) {
                $env:XDG_DATA_HOME
            } else {
                Join-Path $env:USERPROFILE ".local\share"
            }
        )

        # XDG_STATE_HOME - User state files
        StateHome = $(
            if ($env:XDG_STATE_HOME) {
                $env:XDG_STATE_HOME
            } else {
                Join-Path $env:USERPROFILE ".local\state"
            }
        )

        # XDG_CACHE_HOME - User cache files
        CacheHome = $(
            if ($env:XDG_CACHE_HOME) {
                $env:XDG_CACHE_HOME
            } else {
                Join-Path $env:USERPROFILE ".cache"
            }
        )

        # Tool-specific paths
        NeovimConfigPath = $(
            if ($env:XDG_CONFIG_HOME) {
                Join-Path $env:XDG_CONFIG_HOME "nvim"
            } else {
                Join-Path $env:USERPROFILE ".config\nvim"
            }
        )

        NeovimDataPath = $(
            if ($env:XDG_DATA_HOME) {
                Join-Path $env:XDG_DATA_HOME "vim-data"
            } else {
                Join-Path $env:USERPROFILE ".local\share\vim-data"
            }
        )

        VimRuntimePath = $(
            if ($env:XDG_DATA_HOME) {
                Join-Path $env:XDG_DATA_HOME "vim-data\vimfiles"
            } else {
                Join-Path $env:USERPROFILE ".local\share\vim-data\vimfiles"
            }
        )
    }
}

<#
.SYNOPSIS
    Get configuration file paths.

.DESCRIPTION
    Returns all configuration file paths used by the dotfile system.
#>
function Get-ConfigurationPaths {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param()

    $xdg = Get-XDGConfiguration

    return @{
        # PowerShell
        PowerShellProfile         = $PROFILE.CurrentUserCurrentHost
        PowerShellProfileDir      = Split-Path -Parent $PROFILE.CurrentUserCurrentHost
        PowerShellConfigPath      = Join-Path $xdg.ConfigHome "powershell"

        # Neovim
        NeovimConfig              = $xdg.NeovimConfigPath
        NeovimData                = $xdg.NeovimDataPath
        NeovimRuntime             = $xdg.VimRuntimePath

        # Windows Terminal
        WindowsTerminalSettings   = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"

        # Oh-My-Posh
        OhMyPoshThemesPath        = "$env:USERPROFILE\.poshthemes"
        OhMyPoshDefaultTheme      = "$env:USERPROFILE\.poshthemes\simple.omp.json"

        # Git
        GitConfig                 = "$env:USERPROFILE\.gitconfig"
        GitIgnore                 = "$env:USERPROFILE\.gitignore"

        # Vim
        VimConfig                 = "$env:USERPROFILE\.vimrc"
        VimDirectory              = "$env:USERPROFILE\.vim"
    }
}

<#
.SYNOPSIS
    Get offline deployment configuration.

.DESCRIPTION
    Returns settings for creating and managing offline deployment packages.
#>
function Get-OfflineDeploymentConfiguration {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param()

    return @{
        # Package structure
        OutputDir              = ".\offline-package"
        PackageName            = "devtools-offline"
        CompressionFormat      = "zip"

        # Directory structure
        ToolsDirectory         = "tools"
        ModulesDirectory       = "modules"
        ConfigDirectory        = "config"
        ScriptsDirectory       = "scripts"
        DocumentationDirectory = "documentation"
        RuntimesDirectory      = "runtimes"

        # Tool-specific offline paths
        OfflinePaths = @{
            Git              = "tools\git"
            NodeJS           = "tools\nodejs"
            Neovim           = "tools\neovim"
            WindowsTerminal  = "tools\windows-terminal"
            PowerShell       = "tools\powershell"
            OhMyPosh         = "tools\oh-my-posh"
            Python           = "tools\python"
            DotNetSDK        = "tools\dotnet-sdk"
            DockerDesktop    = "tools\docker-desktop"
            VSCode           = "tools\vscode"
        }

        # Module offline paths
        ModulePaths = @{
            PSReadLine    = "modules\psreadline"
            TerminalIcons = "modules\terminal-icons"
            PSFzf         = "modules\psfzf"
        }

        # Runtime offline paths
        RuntimePaths = @{
            VCRedist2022 = "runtimes\vc-redist-2022"
        }
    }
}

<#
.SYNOPSIS
    Get UI and color scheme configuration.

.DESCRIPTION
    Returns color schemes and UI settings for console output.
#>
function Get-UIConfiguration {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param()

    return @{
        # Console colors
        Colors = @{
            Info     = "Cyan"
            Success  = "Green"
            Warning  = "Yellow"
            Error    = "Red"
            Muted    = "Gray"
            Accent   = "Blue"
        }

        # Section header styling
        SectionHeader = @{
            Character  = "="
            Width      = 42
            Prefix     = ""
        }

        # Icons and symbols (for future use with terminal icons)
        Icons = @{
            Success = "[+]"
            Error   = "[x]"
            Warning = "[!]"
            Info    = "[i]"
            Arrow   = "->"
            Bullet  = "*"
        }

        # Output formatting
        Formatting = @{
            Indent      = "  "
            DoubleIndent = "    "
            Separator   = "-"
        }
    }
}

<#
.SYNOPSIS
    Get manual installation download URLs.

.DESCRIPTION
    Returns URLs for manual tool installation when automated installation fails.
#>
function Get-ManualInstallationUrls {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param()

    return @{
        Git              = "https://git-scm.com/download/win"
        Node             = "https://nodejs.org/"
        Neovim           = "https://github.com/neovim/neovim/releases"
        WindowsTerminal  = "https://aka.ms/terminal"
        PowerShell       = "https://github.com/PowerShell/PowerShell/releases"
        OhMyPosh         = "https://ohmyposh.dev/"
        Python           = "https://www.python.org/downloads/"
        DotNet           = "https://dotnet.microsoft.com/download"
        Docker           = "https://www.docker.com/products/docker-desktop/"
        VSCode           = "https://code.visualstudio.com/"
        Winget           = "https://github.com/microsoft/winget-cli/releases"
        VCRedist         = "https://aka.ms/vs/17/release/vc_redist.x64.exe"
    }
}

<#
.SYNOPSIS
    Get validation rules and requirements.

.DESCRIPTION
    Returns minimum system requirements and validation rules.
#>
function Get-ValidationRules {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param()

    return @{
        # System requirements
        MinPowerShellVersion        = "7.0"
        MinPowerShellVersionWarn    = "5.1"
        MinWindowsVersion           = "10.0.19041" # Windows 10 2004
        RecommendedRAM              = 8 # GB
        RequiredDiskSpace           = 5 # GB

        # Tool requirements
        RequireWinget               = $true
        RequireAdministrator        = $false  # Some operations work without admin

        # Network requirements
        InternetRequired            = $true
        OfflineModeSupported        = $true

        # Installation behavior
        AutoBackup                  = $true
        ForceOverwrite              = $false
        CreateBackups               = $true

        # Validation behavior
        SkipOptionalTools           = $false
        ContinueOnRequiredFailure   = $false
        ContinueOnOptionalFailure   = $true
    }
}

<#
.SYNOPSIS
    Get logging configuration.

.DESCRIPTION
    Returns settings for logging and debugging.
#>
function Get-LoggingConfiguration {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param()

    return @{
        LogDirectory       = "$env:USERPROFILE\.dotfile\logs"
        LogNameFormat      = "{0}_{1}.log"
        TimestampFormat    = "yyyy-MM-dd HH:mm:ss"
        DateFormat         = "yyyyMMdd"

        # Log levels
        DefaultLevel       = "Info"
        DebugMode          = $false
        VerboseMode        = $false

        # Log retention
        MaxLogAgeDays      = 30
        MaxLogSizeMB       = 10
        CompressOldLogs    = $true
    }
}

<#
.SYNOPSIS
    Get one-click install configuration.

.DESCRIPTION
    Returns settings for the one-click installation via web.
#>
function Get-OneClickInstallConfiguration {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param()

    return @{
        InstallScriptUrl        = "https://raw.githubusercontent.com/nbfhscl/dotfile/refs/heads/master/install.ps1"
        RepositoryUrl           = "https://github.com/nbfhscl/dotfile.git"
        DocumentationUrl         = "https://github.com/nbfhscl/dotfile"
        IssuesUrl               = "https://github.com/nbfhscl/dotfile/issues"

        # Installation behavior
        DefaultBranch           = "master"
        IncludeDotfileDeploy    = $true
        IncludeToolInstall      = $true
    }
}

<#
.SYNOPSIS
    Get all configuration as a consolidated object.

.DESCRIPTION
    Returns a single hashtable containing all configuration sections.
    Useful for exporting or inspecting the complete configuration.
#>
function Get-AllConfiguration {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param()

    return @{
        Version                 = $script:ConfigVersion
        LastUpdated             = $script:ConfigLastUpdated
        Tools                   = Get-ToolDefinitions
        Modules                 = Get-ModuleDefinitions
        Runtimes                = Get-RuntimeDefinitions
        Dotfile                 = Get-DotfileConfiguration
        XDG                     = Get-XDGConfiguration
        Paths                   = Get-ConfigurationPaths
        OfflineDeployment       = Get-OfflineDeploymentConfiguration
        UI                      = Get-UIConfiguration
        ManualInstallationUrls  = Get-ManualInstallationUrls
        ValidationRules         = Get-ValidationRules
        Logging                 = Get-LoggingConfiguration
        OneClickInstall         = Get-OneClickInstallConfiguration
    }
}

<#
.SYNOPSIS
    Export configuration to JSON file.

.DESCRIPTION
    Exports the complete configuration to a JSON file for inspection or backup.

.PARAMETER OutputPath
    Path to save the JSON file (default: .\configuration-export.json).

.PARAMETER PrettyPrint
    Format JSON with indentation (default: true).

.EXAMPLE
    Export-ConfigurationToJson -OutputPath "config-backup.json"
#>
function Export-ConfigurationToJson {
    [CmdletBinding()]
    param(
        [string]$OutputPath = ".\configuration-export.json",
        [switch]$PrettyPrint = $true
    )

    $config = Get-AllConfiguration

    try {
        if ($PrettyPrint) {
            $config | ConvertTo-Json -Depth 10 | Out-File -FilePath $OutputPath -Encoding utf8
        } else {
            $config | ConvertTo-Json -Compress -Depth 10 | Out-File -FilePath $OutputPath -Encoding utf8
        }
        Write-Host "Configuration exported to: $OutputPath" -ForegroundColor Green
        return $true
    } catch {
        Write-Host "Failed to export configuration: $_" -ForegroundColor Red
        return $false
    }
}

<#
.SYNOPSIS
    Validate configuration integrity.

.DESCRIPTION
    Performs validation checks on the configuration data to ensure
    all required fields are present and valid.

.EXAMPLE
    Test-ConfigurationIntegrity
#>
function Test-ConfigurationIntegrity {
    [CmdletBinding()]
    [OutputType([bool])]
    param()

    Write-Host "Validating configuration integrity..." -ForegroundColor Cyan

    $errors = 0
    $warnings = 0

    # Validate tool definitions
    $tools = Get-ToolDefinitions
    foreach ($tool in $tools.GetEnumerator()) {
        if (-not $tool.Value.Name) {
            Write-Host "  [ERROR] Tool '$($tool.Key)' missing Name" -ForegroundColor Red
            $errors++
        }
        if (-not $tool.Value.WingetId) {
            Write-Host "  [WARN] Tool '$($tool.Key)' missing WingetId" -ForegroundColor Yellow
            $warnings++
        }
    }

    # Validate module definitions
    $modules = Get-ModuleDefinitions
    foreach ($module in $modules.GetEnumerator()) {
        if (-not $module.Value.Name) {
            Write-Host "  [ERROR] Module '$($module.Key)' missing Name" -ForegroundColor Red
            $errors++
        }
    }

    # Validate XDG paths
    $xdg = Get-XDGConfiguration
    if (-not $xdg.ConfigHome) {
        Write-Host "  [ERROR] XDG ConfigHome is not set" -ForegroundColor Red
        $errors++
    }

    # Print summary
    Write-Host "`nConfiguration validation complete:" -ForegroundColor Cyan
    Write-Host "  Tools defined: $($tools.Count)" -ForegroundColor Green
    Write-Host "  Modules defined: $($modules.Count)" -ForegroundColor Green
    Write-Host "  Errors found: $errors" -ForegroundColor $(if ($errors -eq 0) { "Green" } else { "Red" })
    Write-Host "  Warnings: $warnings" -ForegroundColor Yellow

    return $errors -eq 0
}

<#
.SYNOPSIS
    Get configuration help and documentation.

.DESCRIPTION
    Displays help information about the configuration system.

.EXAMPLE
    Show-ConfigurationHelp
#>
function Show-ConfigurationHelp {
    [CmdletBinding()]
    param()

    $helpText = @"

========================================
Dotfile Configuration System Help
========================================

This Config.psm1 module is the single source of truth for all configuration data.

USAGE:
  Import-Module Config.psm1
  $tools = Get-ToolDefinitions
  $paths = Get-ConfigurationPaths
  $xdg = Get-XDGConfiguration

AVAILABLE FUNCTIONS:
  Get-ToolDefinitions           - Get all tool definitions
  Get-ModuleDefinitions          - Get PowerShell module definitions
  Get-RuntimeDefinitions         - Get runtime dependency definitions
  Get-DotfileConfiguration       - Get dotfile repository settings
  Get-XDGConfiguration           - Get XDG Base Directory paths
  Get-ConfigurationPaths         - Get all configuration file paths
  Get-OfflineDeploymentConfiguration - Get offline deployment settings
  Get-UIConfiguration            - Get UI and color scheme settings
  Get-ManualInstallationUrls     - Get manual download URLs
  Get-ValidationRules            - Get system requirements and validation rules
  Get-LoggingConfiguration       - Get logging and debugging settings
  Get-OneClickInstallConfiguration - Get one-click install settings
  Get-AllConfiguration           - Get complete configuration as one object

UTILITY FUNCTIONS:
  Export-ConfigurationToJson     - Export configuration to JSON file
  Test-ConfigurationIntegrity    - Validate configuration data
  Show-ConfigurationHelp         - Display this help message

CONFIGURATION SECTIONS:
  - Tools: Git, Node.js, Neovim, PowerShell, Oh-My-Posh, etc.
  - Modules: PSReadLine, Terminal-Icons, PSFzf
  - Paths: All configuration file locations
  - XDG: XDG Base Directory support for Windows
  - Offline: Offline deployment package configuration
  - UI: Color schemes and formatting
  - Validation: System requirements and rules

For more information, see the module documentation.
"@

    Write-Host $helpText -ForegroundColor Cyan
}

# ============================================
# Module Exports
# ============================================

Export-ModuleMember -Function @(
    # Tool Configuration
    'Get-ToolDefinitions',
    'Get-ModuleDefinitions',
    'Get-RuntimeDefinitions',
    'Get-PowerShellModules',

    # Path Configuration
    'Get-DotfileConfiguration',
    'Get-XDGConfiguration',
    'Get-ConfigurationPaths',

    # Deployment Configuration
    'Get-OfflineDeploymentConfiguration',
    'Get-OneClickInstallConfiguration',

    # UI Configuration
    'Get-UIConfiguration',
    'Get-ManualInstallationUrls',

    # System Configuration
    'Get-ValidationRules',
    'Get-LoggingConfiguration',

    # Utility Functions
    'Get-AllConfiguration',
    'Export-ConfigurationToJson',
    'Test-ConfigurationIntegrity',
    'Show-ConfigurationHelp'
)
