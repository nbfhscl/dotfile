# ============================================
# ToolInstaller Module - Tool Installation Functions
# ============================================

<#
.SYNOPSIS
    Provides functions for installing development tools via winget and other package managers.

.DESCRIPTION
    This module handles the installation of various development tools including
    Windows Terminal, PowerShell 7, Git, Node.js, Neovim, Oh-My-Posh, and PowerShell modules.

.EXPORTED FUNCTIONS
    Install-Package, Install-WindowsTerminal, Install-PowerShell7, Install-Git,
    Install-Nodejs, Install-Neovim, Install-OhMyPosh, Install-PSModules, Install-Zoxide
#>

# Import UI module for output functions
Import-Module (Join-Path $PSScriptRoot 'UI.psm1') -ErrorAction SilentlyContinue

<#
.SYNOPSIS
    Generic package installer using winget.

.PARAMETER PackageName
    The display name of the package.

.PARAMETER WingetId
    The winget package ID.

.PARAMETER Required
    Whether the package is required (default: true).

.PARAMETER DryRun
    Dry run mode - only show what would be installed.

.EXAMPLE
    Install-Package -PackageName "Git" -WingetId "Git.Git"
#>
function Install-Package {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$PackageName,
        [Parameter(Mandatory = $true)]
        [string]$WingetId,
        [switch]$Required = $true,
        [switch]$DryRun = $false
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
            Write-ErrorCustom "winget is not available, cannot install $PackageName"
            Show-ManualInstallHelp -ToolName $PackageName
            return $false
        } else {
            Write-WarningCustom "Skipping optional tool $PackageName"
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
        Write-ErrorCustom "$PackageName installation failed"
        if ($Required) {
            Show-ManualInstallHelp -ToolName $PackageName
        }
        return $false
    }
}

<#
.SYNOPSIS
    Install Windows Terminal.

.EXAMPLE
    Install-WindowsTerminal
#>
function Install-WindowsTerminal {
    [CmdletBinding()]
    param(
        [switch]$DryRun = $false
    )

    if (Get-Command wt -ErrorAction SilentlyContinue) {
        Write-Success "Windows Terminal is installed"
        return $true
    }
    Write-Info "Installing Windows Terminal..."
    Install-Package -PackageName "Windows Terminal" -WingetId "Microsoft.WindowsTerminal" -DryRun:$DryRun
}

<#
.SYNOPSIS
    Install PowerShell 7.

.EXAMPLE
    Install-PowerShell7
#>
function Install-PowerShell7 {
    [CmdletBinding()]
    param(
        [switch]$DryRun = $false
    )

    if ($PSVersionTable.PSVersion.Major -ge 7) {
        Write-Success "PowerShell 7 is installed"
        return $true
    }
    Write-Info "Installing PowerShell 7..."
    Install-Package -PackageName "PowerShell" -WingetId "Microsoft.PowerShell" -DryRun:$DryRun
}

<#
.SYNOPSIS
    Install Git.

.EXAMPLE
    Install-Git
#>
function Install-Git {
    [CmdletBinding()]
    param(
        [switch]$DryRun = $false
    )

    Write-Info "Installing Git..."
    Install-Package -PackageName "Git" -WingetId "Git.Git" -Required -DryRun:$DryRun
}

<#
.SYNOPSIS
    Install Node.js and npm.

.EXAMPLE
    Install-Nodejs
#>
function Install-Nodejs {
    [CmdletBinding()]
    param(
        [switch]$DryRun = $false
    )

    Write-Info "Installing Node.js and npm..."
    Install-Package -PackageName "Node.js" -WingetId "OpenJS.NodeJS.LTS" -Required -DryRun:$DryRun
}

<#
.SYNOPSIS
    Install Neovim.

.EXAMPLE
    Install-Neovim
#>
function Install-Neovim {
    [CmdletBinding()]
    param(
        [switch]$DryRun = $false
    )

    Write-Info "Installing Neovim..."
    $result = Install-Package -PackageName "Neovim" -WingetId "Neovim.Neovim" -Required -DryRun:$DryRun

    if ($result -and -not $DryRun) {
        Write-Info "Verifying Neovim installation..."
        if (Get-Command nvim -ErrorAction SilentlyContinue) {
            $nvimVersion = & nvim --version | Select-Object -First 1
            Write-Success "Neovim is installed: $nvimVersion"
        } else {
            Write-WarningCustom "Neovim installation completed, but 'nvim' command not found in PATH"
            Write-Info "You may need to restart your shell or refresh your PATH"
        }
    }

    return $result
}

<#
.SYNOPSIS
    Install Oh-My-Posh theme engine.

.EXAMPLE
    Install-OhMyPosh
#>
function Install-OhMyPosh {
    [CmdletBinding()]
    param(
        [switch]$DryRun = $false
    )

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

            # Refresh environment variables after installation
            $machinePath = [System.Environment]::GetEnvironmentVariable("Path", "Machine")
            $userPath = [System.Environment]::GetEnvironmentVariable("Path", "User")
            $env:Path = $machinePath + ";" + $userPath

            # Verify the command is available
            if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) {
                Write-Success "Oh-My-Posh command verified"
                return $true
            } else {
                Write-WarningCustom "Oh-My-Posh installed but command not found in PATH. You may need to restart your shell."
                return $true
            }
        } else {
            # Fallback: use PowerShell module
            Write-WarningCustom "Winget installation failed, trying PowerShell module..."
            try {
                Install-Module -Name oh-my-posh -Force -Scope CurrentUser -AllowClobber -ErrorAction Stop
                Write-Success "Oh-My-Posh installed via PowerShell module"
                return $true
            } catch {
                Write-ErrorCustom "Oh-My-Posh PowerShell module installation also failed: $_"
                return $false
            }
        }
    } catch {
        Write-ErrorCustom "Oh-My-Posh installation failed: $_"
        return $false
    }
}

<#
.SYNOPSIS
    Install PowerShell modules (PSReadLine, Terminal-Icons, PSFzf).

.EXAMPLE
    Install-PSModules
#>
function Install-PSModules {
    [CmdletBinding()]
    param(
        [switch]$DryRun = $false
    )

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

            # Special handling for PSReadLine - update to version 2.0.0+ for compatibility
            if ($moduleName -eq "PSReadLine") {
                Write-Info "Updating PSReadLine to latest version for compatibility..."
                try {
                    Update-Module -Name PSReadLine -Force -ErrorAction Stop
                    Write-Success "PSReadLine updated successfully"
                } catch {
                    Write-WarningCustom "PSReadLine update failed (optional): $_"
                }
            }
        } catch {
            if ($required) {
                Write-ErrorCustom "$moduleName installation failed: $_"
            } else {
                Write-WarningCustom "$moduleName installation failed (optional tool)"
            }
        }
    }
}

<#
.SYNOPSIS
    Install zoxide ( smarter cd command).

.EXAMPLE
    Install-Zoxide
#>
function Install-Zoxide {
    [CmdletBinding()]
    param(
        [switch]$DryRun = $false
    )

    if (Get-Command zoxide -ErrorAction SilentlyContinue) {
        Write-Success "zoxide is installed"
        return $true
    }
    Write-Info "Installing zoxide..."
    Install-Package -PackageName "zoxide" -WingetId "ajeetdsouza.zoxide" -Required:$false -DryRun:$DryRun
}

<#
.SYNOPSIS
    Install all development tools.

.PARAMETER DryRun
    Dry run mode - only show what would be installed.

.EXAMPLE
    Install-AllDevelopmentTools
#>
function Install-AllDevelopmentTools {
    [CmdletBinding()]
    param(
        [switch]$DryRun = $false
    )

    Write-SectionHeader "Starting development tools installation"

    Install-WindowsTerminal -DryRun:$DryRun
    Install-PowerShell7 -DryRun:$DryRun
    Install-Git -DryRun:$DryRun
    Install-Nodejs -DryRun:$DryRun
    Install-Neovim -DryRun:$DryRun
    Install-OhMyPosh -DryRun:$DryRun
    Install-PSModules -DryRun:$DryRun
    Install-Zoxide -DryRun:$DryRun

    Write-SectionComplete "Development tools installation completed"
}

# Internal helper function - not exported
function Test-WingetAvailable {
    if (Get-Command winget -ErrorAction SilentlyContinue) {
        return $true
    } else {
        return $false
    }
}

# Export module members
Export-ModuleMember -Function @(
    'Install-Package',
    'Install-WindowsTerminal',
    'Install-PowerShell7',
    'Install-Git',
    'Install-Nodejs',
    'Install-Neovim',
    'Install-OhMyPosh',
    'Install-PSModules',
    'Install-Zoxide',
    'Install-AllDevelopmentTools'
)
