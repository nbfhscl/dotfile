# ============================================
# Config.psm1 Usage Examples
# ============================================
#
# This file demonstrates how to use the Config.psm1 module
# in other scripts and modules.

# ============================================
# Example 1: Import and Basic Usage
# ============================================

# Import the configuration module
Import-Module (Join-Path $PSScriptRoot 'Config.psm1') -Force

# Get tool definitions
$tools = Get-ToolDefinitions

# Access a specific tool
$git = $tools.Git
Write-Host "Git Winget ID: $($git.WingetId)"
Write-Host "Git Min Version: $($git.MinVersion)"

# ============================================
# Example 2: Refactoring ToolInstaller.psm1
# ============================================

# BEFORE (hardcoded):
# function Install-Git {
#     Install-Package -PackageName "Git" -WingetId "Git.Git" -Required
# }

# AFTER (using Config):
function Install-GitFromConfig {
    [CmdletBinding()]
    param()

    $tools = Get-ToolDefinitions
    $git = $tools.Git

    Write-Host "Installing $($git.DisplayName)..."
    & winget install --id $git.WingetId --accept-source-agreements --accept-package-agreements -e
}

# ============================================
# Example 3: Installing All Required Tools
# ============================================

function Install-RequiredTools {
    [CmdletBinding()]
    param()

    $tools = Get-ToolDefinitions
    $requiredTools = $tools.GetEnumerator() | Where-Object { $_.Value.Required }

    foreach ($tool in $requiredTools) {
        $t = $tool.Value

        # Check if already installed
        if ($t.Command -and (Get-Command $t.Command -ErrorAction SilentlyContinue)) {
            Write-Host "[SKIP] $($t.DisplayName) is already installed" -ForegroundColor Yellow
            continue
        }

        Write-Host "[INSTALL] $($t.DisplayName)" -ForegroundColor Green

        # Execute installation script
        if ($t.InstallScript) {
            $result = Invoke-Expression $t.InstallScript
            if ($LASTEXITCODE -eq 0) {
                Write-Host "[SUCCESS] $($t.DisplayName) installed" -ForegroundColor Green
            } else {
                Write-Host "[ERROR] Failed to install $($t.DisplayName)" -ForegroundColor Red
            }
        }
    }
}

# ============================================
# Example 4: Verifying Tool Installation
# ============================================

function Test-ToolConfiguration {
    [CmdletBinding()]
    param()

    $tools = Get-ToolDefinitions
    $results = @()

    foreach ($tool in $tools.Values) {
        $installed = $false
        $version = $null

        if ($tool.Command) {
            $cmd = Get-Command $tool.Command -ErrorAction SilentlyContinue
            if ($cmd) {
                $installed = $true
                if ($tool.VerificationCommand) {
                    try {
                        $version = Invoke-Expression $tool.VerificationCommand 2>&1 | Select-Object -First 1
                    } catch {
                        $version = "Unknown"
                    }
                }
            }
        }

        $results += [PSCustomObject]@{
            Tool      = $tool.DisplayName
            Required  = $tool.Required
            Installed = $installed
            Version   = $version
            Category  = $tool.Category
        }
    }

    # Display results
    $results | Format-Table -AutoSize

    # Summary
    $requiredInstalled = ($results | Where-Object { $_.Required -and $_.Installed }).Count
    $requiredTotal = ($results | Where-Object { $_.Required }).Count
    $optionalInstalled = ($results | Where-Object { -not $_.Required -and $_.Installed }).Count
    $optionalTotal = ($results | Where-Object { -not $_.Required }).Count

    Write-Host "`nSummary:" -ForegroundColor Cyan
    Write-Host "  Required: $requiredInstalled / $requiredTotal" -ForegroundColor $(if ($requiredInstalled -eq $requiredTotal) { "Green" } else { "Yellow" })
    Write-Host "  Optional: $optionalInstalled / $optionalTotal" -ForegroundColor Gray

    return $results
}

# ============================================
# Example 5: Using XDG Configuration Paths
# ============================================

function Show-XDGPaths {
    [CmdletBinding()]
    param()

    $xdg = Get-XDGConfiguration

    Write-Host "XDG Base Directory Configuration:" -ForegroundColor Cyan
    Write-Host "  XDG_CONFIG_HOME: $($xdg.ConfigHome)" -ForegroundColor White
    Write-Host "  XDG_DATA_HOME:   $($xdg.DataHome)" -ForegroundColor White
    Write-Host "  XDG_STATE_HOME:  $($xdg.StateHome)" -ForegroundColor White
    Write-Host "  XDG_CACHE_HOME:  $($xdg.CacheHome)" -ForegroundColor White

    Write-Host "`nApplication Paths:" -ForegroundColor Cyan
    Write-Host "  Neovim Config: $($xdg.NeovimConfigPath)" -ForegroundColor White
    Write-Host "  Neovim Data:   $($xdg.NeovimDataPath)" -ForegroundColor White
    Write-Host "  Vim Runtime:   $($xdg.VimRuntimePath)" -ForegroundColor White
}

# ============================================
# Example 6: Creating Custom Tool Installer
# ============================================

function Install-ToolByName {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ToolName,

        [switch]$Force
    )

    $tools = Get-ToolDefinitions
    $tool = $tools[$ToolName]

    if (-not $tool) {
        Write-Error "Tool '$ToolName' not found in configuration"
        return
    }

    Write-Host "Tool: $($tool.DisplayName)" -ForegroundColor Cyan
    Write-Host "Winget ID: $($tool.WingetId)" -ForegroundColor Gray
    Write-Host "Required: $($tool.Required)" -ForegroundColor Gray
    Write-Host ""

    # Check dependencies
    if ($tool.Dependencies.Count -gt 0) {
        Write-Host "Dependencies: $($tool.Dependencies -join ', ')" -ForegroundColor Yellow
    }

    # Check if already installed
    if (-not $Force -and $tool.Command) {
        $installed = Get-Command $tool.Command -ErrorAction SilentlyContinue
        if ($installed) {
            Write-Host "Already installed: $($tool.Command)" -ForegroundColor Green
            return
        }
    }

    # Install
    Write-Host "Installing..." -ForegroundColor Green
    if ($tool.InstallScript) {
        Invoke-Expression $tool.InstallScript

        if ($LASTEXITCODE -eq 0) {
            Write-Host "Installation complete" -ForegroundColor Green
        } else {
            Write-Host "Installation failed" -ForegroundColor Red

            # Show manual installation URL
            $urls = Get-ManualInstallationUrls
            if ($urls.ContainsKey($ToolName)) {
                Write-Host "Manual installation: $($urls[$ToolName])" -ForegroundColor Yellow
            }
        }
    }
}

# ============================================
# Example 7: Generating Installation Report
# ============================================

function New-InstallationReport {
    [CmdletBinding()]
    param(
        [string]$OutputPath = ".\installation-report.json"
    )

    $tools = Get-ToolDefinitions
    $report = @{
        GeneratedAt = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        Tools       = @()
    }

    foreach ($tool in $tools.Values) {
        $installed = $false
        $version = $null

        if ($tool.Command) {
            $cmd = Get-Command $tool.Command -ErrorAction SilentlyContinue
            if ($cmd) {
                $installed = $true
                if ($tool.VerificationCommand) {
                    try {
                        $version = Invoke-Expression $tool.VerificationCommand 2>&1 | Select-Object -First 1
                    } catch {
                        $version = "Unknown"
                    }
                }
            }
        }

        $report.Tools += @{
            Name         = $tool.Name
            DisplayName  = $tool.DisplayName
            Required     = $tool.Required
            Installed    = $installed
            Version      = $version
            Category     = $tool.Category
            WingetId     = $tool.WingetId
            DownloadUrl  = $tool.DownloadUrl
        }
    }

    # Export to JSON
    $report | ConvertTo-Json -Depth 3 | Out-File -FilePath $OutputPath -Encoding utf8
    Write-Host "Report saved to: $OutputPath" -ForegroundColor Green

    return $report
}

# ============================================
# Example 8: Using Validation Rules
# ============================================

function Test-SystemRequirements {
    [CmdletBinding()]
    param()

    $rules = Get-ValidationRules
    $passed = $true

    Write-Host "Checking system requirements..." -ForegroundColor Cyan

    # Check PowerShell version
    $psVersion = $PSVersionTable.PSVersion
    $minVersion = [version]$rules.MinPowerShellVersion

    if ($psVersion -lt $minVersion) {
        Write-Host "[FAIL] PowerShell $psVersion (required: $minVersion)" -ForegroundColor Red
        $passed = $false
    } else {
        Write-Host "[PASS] PowerShell $psVersion" -ForegroundColor Green
    }

    # Check winget
    $winget = Get-Command winget -ErrorAction SilentlyContinue
    if ($winget) {
        Write-Host "[PASS] winget is installed" -ForegroundColor Green
    } elseif ($rules.RequireWinget) {
        Write-Host "[FAIL] winget is required but not installed" -ForegroundColor Red
        $passed = $false
    } else {
        Write-Host "[WARN] winget not installed (optional)" -ForegroundColor Yellow
    }

    # Check administrator
    $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

    if ($isAdmin) {
        Write-Host "[INFO] Running as administrator" -ForegroundColor Green
    } else {
        Write-Host "[INFO] Not running as administrator" -ForegroundColor Yellow
    }

    return $passed
}

# ============================================
# Example 9: Using UI Configuration
# ============================================

function Show-ColoredMessage {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,

        [ValidateSet("Info", "Success", "Warning", "Error", "Muted", "Accent")]
        [string]$Level = "Info"
    )

    $ui = Get-UIConfiguration
    $color = $ui.Colors[$Level]

    $icon = switch ($Level) {
        "Success" { $ui.Icons.Success }
        "Error"   { $ui.Icons.Error }
        "Warning" { $ui.Icons.Warning }
        "Info"    { $ui.Icons.Info }
        default   { "" }
    }

    Write-Host "$icon $Message" -ForegroundColor $color
}

# ============================================
# Example 10: Complete Installation Workflow
# ============================================

function Start-ConfigurationWorkflow {
    [CmdletBinding()]
    param()

    Write-Host "=== Dotfile Configuration Workflow ===" -ForegroundColor Cyan
    Write-Host ""

    # Step 1: Validate system
    Write-Host "Step 1: Validating system requirements..." -ForegroundColor Cyan
    $systemOk = Test-SystemRequirements
    if (-not $systemOk) {
        Write-Host "System requirements not met. Aborting." -ForegroundColor Red
        return
    }
    Write-Host ""

    # Step 2: Check configuration integrity
    Write-Host "Step 2: Validating configuration..." -ForegroundColor Cyan
    $configOk = Test-ConfigurationIntegrity
    if (-not $configOk) {
        Write-Host "Configuration validation failed. Aborting." -ForegroundColor Red
        return
    }
    Write-Host ""

    # Step 3: Show current status
    Write-Host "Step 3: Checking tool installation status..." -ForegroundColor Cyan
    $status = Test-ToolConfiguration
    Write-Host ""

    # Step 4: Install missing tools (optional)
    $response = Read-Host "Install missing required tools? (Y/N)"
    if ($response -eq 'Y') {
        Write-Host "Step 4: Installing required tools..." -ForegroundColor Cyan
        Install-RequiredTools
    }
    Write-Host ""

    # Step 5: Generate report
    Write-Host "Step 5: Generating installation report..." -ForegroundColor Cyan
    $report = New-InstallationReport -OutputPath ".\installation-report.json"
    Write-Host ""

    Write-Host "=== Workflow Complete ===" -ForegroundColor Green
}

# ============================================
# Run Examples (commented out by default)
# ============================================

# Show-XDGPaths
# Test-ToolConfiguration
# Install-ToolByName -ToolName "Git"
# Start-ConfigurationWorkflow

Write-Host "Config.psm1 examples loaded. Run Start-ConfigurationWorkflow to see a complete demo." -ForegroundColor Green
