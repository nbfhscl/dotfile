# ============================================
# Verifier Module - Verification and Validation Functions
# ============================================

<#
.SYNOPSIS
    Provides functions for verifying system environment and tool installations.

.DESCRIPTION
    This module contains functions to check PowerShell version, winget availability,
    administrator privileges, and verify various configurations.

.EXPORTED FUNCTIONS
    Test-PowerShellVersion, Test-WingetAvailable, Test-Administrator,
    Verify-NeovimConfig, Verify-ToolInstallation
#>

# Import UI module for output functions
Import-Module (Join-Path $PSScriptRoot 'UI.psm1') -ErrorAction SilentlyContinue

<#
.SYNOPSIS
    Check if the current PowerShell version meets requirements.

.DESCRIPTION
    Checks the PowerShell version and warns if running on versions older than 7.0.
    Note: Continues with PowerShell 5.1 for compatibility but recommends 7+.

.EXAMPLE
    Test-PowerShellVersion
#>
function Test-PowerShellVersion {
    [CmdletBinding()]
    param()

    $currentVersion = $PSVersionTable.PSVersion
    Write-Info "Current PowerShell version: $currentVersion"

    if ($currentVersion.Major -lt 7) {
        Write-WarningCustom "PowerShell 7.0 or higher is recommended, but continuing with PowerShell 5.1"
    } else {
        Write-Success "PowerShell version check passed"
    }

    return $true
}

<#
.SYNOPSIS
    Check if winget (Windows Package Manager) is available.

.DESCRIPTION
    Tests if the winget command is available in the current environment.
    Returns true if available, false otherwise.

.EXAMPLE
    Test-WingetAvailable
#>
function Test-WingetAvailable {
    [CmdletBinding()]
    param()

    if (Get-Command winget -ErrorAction SilentlyContinue) {
        Write-Success "winget is installed"
        return $true
    } else {
        Write-WarningCustom "winget is not installed"
        Write-Info "Please install Windows Package Manager from Microsoft Store"
        return $false
    }
}

<#
.SYNOPSIS
    Check if the current session has administrator privileges.

.DESCRIPTION
    Tests if the current PowerShell session is running with administrator rights.
    Returns true if running as admin, false otherwise.

.EXAMPLE
    Test-Administrator
#>
function Test-Administrator {
    [CmdletBinding()]
    param()

    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    $isAdmin = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

    if ($isAdmin) {
        Write-Success "Administrator privileges check passed"
        return $true
    } else {
        Write-WarningCustom "Administrator privileges not detected"
        Write-Info "Some operations may require administrator privileges"
        return $false
    }
}

<#
.SYNOPSIS
    Verify Neovim configuration works correctly.

.DESCRIPTION
    Verifies that:
    - Neovim recognizes the correct config path
    - All files are synced correctly
    - XDG environment variables are set

.EXAMPLE
    Verify-NeovimConfig
#>
function Verify-NeovimConfig {
    [CmdletBinding()]
    param()

    Write-Info "Verifying Neovim configuration..."

    # Check if Neovim is installed
    if (-not (Get-Command nvim -ErrorAction SilentlyContinue)) {
        Write-WarningCustom "Neovim is not installed or not in PATH"
        Write-Info "Skipping verification"
        return $false
    }

    # Check XDG environment variables
    Write-Info "Checking XDG environment variables..."
    if ($env:XDG_CONFIG_HOME) {
        Write-Success "XDG_CONFIG_HOME: $env:XDG_CONFIG_HOME"
    } else {
        Write-WarningCustom "XDG_CONFIG_HOME not set in current session"
        Write-Info "It may be set permanently but requires shell restart"
    }

    if ($env:XDG_DATA_HOME) {
        Write-Success "XDG_DATA_HOME: $env:XDG_DATA_HOME"
    } else {
        Write-Info "XDG_DATA_HOME not set (using default)"
    }

    # Check if config directories exist
    Write-Info "Checking configuration directories..."
    $configPaths = @()

    if ($env:XDG_CONFIG_HOME) {
        $configPaths += Join-Path $env:XDG_CONFIG_HOME "nvim"
    } else {
        $configPaths += Join-Path $env:USERPROFILE ".local\config\nvim"
    }

    $configPaths += "$env:LOCALAPPDATA\nvim"

    foreach ($path in $configPaths) {
        if (Test-Path $path) {
            Write-Success "Config directory exists: $path"

            # Count files
            $fileCount = (Get-ChildItem -Path $path -Recurse -File -ErrorAction SilentlyContinue).Count
            Write-Info "  Files: $fileCount"

            # Check for key files
            $initLua = Join-Path $path "init.lua"
            $lazyLock = Join-Path $path "lazy-lock.json"

            if (Test-Path $initLua) {
                Write-Success "  init.lua found"
            } else {
                Write-WarningCustom "  init.lua not found"
            }

            if (Test-Path $lazyLock) {
                Write-Success "  lazy-lock.json found"
            } else {
                Write-Info "  lazy-lock.json not found (will be generated by lazy.nvim)"
            }
        } else {
            Write-WarningCustom "Config directory not found: $path"
        }
    }

    # Try to get Neovim's view of config paths
    Write-Info "Checking Neovim's configuration paths..."
    try {
        $nvimStdConfig = nvim --headless "+echo stdpath('config')" +qa 2>&1
        if ($nvimStdConfig -match 'C:\\') {
            Write-Success "Neovim config path: $nvimStdConfig"
        }
    } catch {
        Write-WarningCustom "Could not query Neovim for config path: $_"
    }

    Write-Success "Verification completed"
    return $true
}

<#
.SYNOPSIS
    Verify if a tool is installed and accessible.

.PARAMETER ToolName
    The name of the tool/command to verify.

.PARAMETER DisplayName
    The display name for the tool (optional, defaults to ToolName).

.EXAMPLE
    Verify-ToolInstallation -ToolName "nvim" -DisplayName "Neovim"
#>
function Verify-ToolInstallation {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ToolName,
        [string]$DisplayName = $ToolName
    )

    if (Get-Command $ToolName -ErrorAction SilentlyContinue) {
        Write-Success "$DisplayName is installed"
        return $true
    } else {
        Write-WarningCustom "$DisplayName is not installed or not in PATH"
        return $false
    }
}

<#
.SYNOPSIS
    Run all environment checks.

.DESCRIPTION
    Runs all environment detection functions and reports the results.

.EXAMPLE
    Test-Environment
#>
function Test-Environment {
    [CmdletBinding()]
    param()

    Write-SectionHeader "Running environment detection"

    Test-PowerShellVersion
    Test-WingetAvailable
    Test-Administrator

    Write-Success "Environment detection completed"
}

<#
.SYNOPSIS
    Verify all installed tools.

.DESCRIPTION
    Checks for the presence of all commonly used development tools.

.EXAMPLE
    Verify-AllTools
#>
function Verify-AllTools {
    [CmdletBinding()]
    param()

    Write-SectionHeader "Verifying installed tools"

    $tools = @(
        @{ Command = "git"; Name = "Git" },
        @{ Command = "node"; Name = "Node.js" },
        @{ Command = "npm"; Name = "npm" },
        @{ Command = "nvim"; Name = "Neovim" },
        @{ Command = "oh-my-posh"; Name = "Oh-My-Posh" },
        @{ Command = "zoxide"; Name = "zoxide" }
    )

    $results = @()
    foreach ($tool in $tools) {
        $results += [PSCustomObject]@{
            Tool = $tool.Name
            Installed = Verify-ToolInstallation -ToolName $tool.Command -DisplayName $tool.Name
        }
    }

    # Check PowerShell modules
    Write-Info ""
    Write-Info "PowerShell Modules:"
    $modules = @("PSReadLine", "Terminal-Icons", "PSFzf")
    foreach ($module in $modules) {
        if (Get-Module -ListAvailable -Name $module) {
            Write-Success "  $module is installed"
        } else {
            Write-WarningCustom "  $module is not installed"
        }
    }

    # Return summary
    $installedCount = ($results | Where-Object { $_.Installed -eq $true }).Count
    Write-Info ""
    Write-Info "Tools installed: $installedCount / $($tools.Count)"

    return $results
}

# Export module members
Export-ModuleMember -Function @(
    'Test-PowerShellVersion',
    'Test-WingetAvailable',
    'Test-Administrator',
    'Verify-NeovimConfig',
    'Verify-ToolInstallation',
    'Test-Environment',
    'Verify-AllTools'
)
