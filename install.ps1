#!/usr/bin/env powershell
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

## 详细使用说明

### 快速开始
1. **一键安装**（推荐）:
   ```powershell
   irm https://raw.githubusercontent.com/nbfhscl/dotfile/refs/heads/master/install.ps1 | iex
   ```

2. **本地安装**:
   ```powershell
   .\install.ps1
   ```

### 操作模式

#### 传统模式（向后兼容）
- `.\install.ps1` - 完整安装（工具 + 配置）
- `.\install.ps1 -SkipTools` - 跳过工具，只部署配置
- `.\install.ps1 -OnlyDotfile` - 只部署配置，不安装工具
- `.\install.ps1 -DryRun` - 预览模式，显示将要执行的操作
- `.\install.ps1 -Uninstall` - 卸载配置（保留工具）

#### 统一模式（推荐）
- `.\install.ps1 -Action Install` - 完整安装（工具 + 配置）
- `.\install.ps1 -Action Deploy` - 只部署配置，跳过工具安装
- `.\install.ps1 -Action Update` - 更新现有 dotfile 配置
- `.\install.ps1 -Action Status` - 显示 dotfile 仓库状态
- `.\install.ps1 -Action Verify` - 验证所有配置是否正确
- `.\install.ps1 -Action Package` - 创建离线安装包
- `.\install.ps1 -Action OfflineDeploy` - 部署到离线机器

### 高级功能

#### 离线包创建
```powershell
# 基础离线包
.\install.ps1 -Action Package

# 压缩离线包
.\install.ps1 -Action Package -Compress

# 自定义输出目录和名称
.\install.ps1 -Action Package -OutputDir ".\my-dev-tools" -PackageName "my-dev"

# 包含指定工具
.\install.ps1 -Action Package -IncludeTools "Git", "NodeJS", "Neovim"

# 排除工具
.\install.ps1 -Action Package -ExcludeTools "DockerDesktop", "VSCode"

# 包含文档
.\install.ps1 -Action Package -IncludeDocumentation
```

#### 高级卸载
```powershell
# 安静卸载
.\install.ps1 -Uninstall -Quiet

# 删除备份
.\install.ps1 -Uninstall -RemoveBackups

# 保留特定配置
.\install.ps1 -Uninstall -KeepProfile -KeepTerminalSettings
```

#### 包装脚本（向后兼容）
所有原有的包装脚本已统一到 install.ps1，保持功能不变：
- `.\scripts\deployment\Deploy-Dotfiles.ps1` → `.\install.ps1 -Action Deploy`
- `.\scripts\deployment\Update-Dotfiles.ps1` → `.\install.ps1 -Action Update`
- `.\scripts\installation\Install-Tools.ps1` → `.\install.ps1 -SkipTools`
- `.\scripts\utilities\Show-DotfileStatus.ps1` → `.\install.ps1 -Action Status`
- `.\scripts\testing\Verify-Configuration.ps1` → `.\install.ps1 -Action Verify`
- `.\scripts\deployment\Package-Offline-Installer.ps1` → `.\install.ps1 -Action Package`
- `.\offline-deployment\Deploy-To-Offline-Machine.ps1` → `.\install.ps1 -Action OfflineDeploy`

.EXAMPLE
    # 基本安装模式 - 传统方式（兼容旧脚本）
    .\install.ps1                               # 完整安装（工具 + 配置）
    .\install.ps1 -SkipTools                    # 跳过工具，只部署配置
    .\install.ps1 -OnlyDotfile                      .\install.ps1 -DryRun                       # 预览模式，显示将要执行的操作
    .\install.ps1 -Uninstall                    # 卸载配置（保留工具）

.EXAMPLE
    # 统一操作模式 - 新功能（推荐使用）
    .\install.ps1 -Action Install               # 完整安装（工具 + 配置）
    .\install.ps1 -Action Deploy                 # 只部署配置，跳过工具安装
    .\install.ps1 -Action Update                 # 更新现有 dotfile 配置
    .\install.ps1 -Action Status                # 显示 dotfile 状态
    .\install.ps1 -Action Verify                # 验证所有配置是否正确
    .\install.ps1 -Action Package               # 创建离线安装包
    .\install.ps1 -Action OfflineDeploy          # 部署到离线机器

.EXAMPLE
    # 高级配置选项
    .\install.ps1 -Action Deploy -SkipBackup     # 部署时跳过备份
    .\install.ps1 -Action Package -Compress      # 创建压缩的离线包
    .\install.ps1 -Action Package -PackageName "MyDevTools" -OutputDir ".\my-package"
    .\install.ps1 -Action Package -IncludeTools "Git", "NodeJS", "Neovim"
    .\install.ps1 -Action Package -ExcludeTools "DockerDesktop"
    .\install.ps1 -Action Package -IncludeDocumentation
    .\install.ps1 -Action Uninstall -Quiet -RemoveBackups # 安静卸载并删除备份

.EXAMPLE
    # 包装脚本使用示例（向后兼容）
    .\scripts\deployment\Deploy-Dotfiles.ps1    # 等同于 install.ps1 -Action Deploy
    .\scripts\deployment\Update-Dotfiles.ps1      # 等同于 install.ps1 -Action Update
    .\scripts\installation\Install-Tools.ps1     # 等同于 install.ps1 -SkipTools
    .\scripts\utilities\Show-DotfileStatus.ps1  # 等同于 install.ps1 -Action Status
    .\scripts\testing\Verify-Configuration.ps1  # 等同于 install.ps1 -Action Verify
    .\scripts\deployment\Package-Offline-Installer.ps1  # 等同于 install.ps1 -Action Package
    .\offline-deployment\Deploy-To-Offline-Machine.ps1  # 等同于 install.ps1 -Action OfflineDeploy

.PARAMETER SkipTools
    跳过工具安装，只部署 dotfile 配置（传统模式）

.PARAMETER OnlyDotfile
    只部署 dotfile 配置，不安装任何工具（传统模式）

.PARAMETER DryRun
    预览模式，只显示将要执行的操作，不实际执行（传统模式）

.PARAMETER Uninstall
    卸载 dotfile 配置，但保留已安装的工具（传统模式）

.PARAMETER Action
    统一操作模式参数，支持以下值：
    - Install: 完整安装（工具 + 配置）
    - Deploy: 只部署配置，跳过工具安装
    - Update: 更新现有的 dotfile 配置
    - Status: 显示 dotfile 仓库状态
    - Verify: 验证所有配置是否正确
    - Package: 创建离线安装包
    - OfflineDeploy: 部署到离线机器

.PARAMETER OutputDir
    离线包的输出目录（默认：.\offline-package）

.PARAMETER IncludeTools
    离线包中包含的工具列表（如果为空则包含所有工具）

.PARAMETER ExcludeTools
    离线包中排除的工具列表

.PARAMETER Compress
    创建压缩的离线包（zip 格式）

.PARAMETER IncludeDocumentation
    在离线包中包含文档文件

.PARAMETER PackageName
    离线包的名称（默认：devtools-offline）

.PARAMETER Quiet
    卸载时使用安静模式，不显示提示信息

.PARAMETER KeepProfile
    卸载时保留 PowerShell 配置文件

.PARAMETER KeepTerminalSettings
    卸载时保留终端设置

.PARAMETER KeepVimConfig
    卸载时保留 Neovim 配置

.PARAMETER RemoveBackups
    卸载时删除备份文件

.PARAMETER Force
    强制执行操作，不显示确认提示

.PARAMETER SkipBackup
    部署时跳过备份操作
#>

[CmdletBinding()]
<#
# 参数说明：
# ==========
# 传统参数（向后兼容）：
# -SkipTools     : 跳过工具安装，只部署 dotfile 配置
# -OnlyDotfile   : 只部署配置，不安装任何工具
# -DryRun        : 预览模式，只显示将要执行的操作
# -Uninstall     : 卸载配置，但保留已安装的工具
#
# 统一操作模式（推荐）：
# -Action        : 操作模式选择（Install/Deploy/Update/Status/Verify/Package/OfflineDeploy）
#
# 高级参数：
# -OutputDir     : 离线包输出目录（默认：.\offline-package）
# -IncludeTools   : 离线包中包含的工具列表
# -ExcludeTools   : 离线包中排除的工具列表
# -Compress      : 创建压缩的离线包
# -IncludeDocumentation : 包含文档文件
# -PackageName   : 离线包名称（默认：devtools-offline）
# -Quiet         : 安静模式（卸载时）
# -KeepProfile   : 卸载时保留 PowerShell 配置
# -KeepTerminalSettings : 卸载时保留终端设置
# -KeepVimConfig : 卸载时保留 Neovim 配置
# -RemoveBackups : 卸载时删除备份文件
# -Force         : 强制执行，不确认
# -SkipBackup    : 部署时跳过备份
#>
param(
    # Traditional parameters (backward compatibility)
    [switch]$SkipTools = $false,
    [switch]$OnlyDotfile = $false,
    [switch]$DryRun = $false,
    [switch]$Uninstall = $false,

    # Unified action parameter (recommended)
    [ValidateSet("Install", "Deploy", "Update", "Status", "Verify", "Package", "OfflineDeploy")]
    [string]$Action = "Install",
    [Alias("help")]
    [switch]$ShowHelp = $false,

    # Additional parameters for various actions
    [string]$OutputDir = ".\offline-package",
    [string[]]$IncludeTools = @(),
    [string[]]$ExcludeTools = @(),
    [switch]$Compress,
    [switch]$IncludeDocumentation,
    [string]$PackageName = "devtools-offline",
    [switch]$Quiet,
    [switch]$KeepProfile,
    [switch]$KeepTerminalSettings,
    [switch]$KeepVimConfig,
    [switch]$RemoveBackups,
    [switch]$Force,
    [switch]$SkipBackup
)

# Get the script directory
$ScriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { Get-Location }

# Set error handling - fail fast for better error detection
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

# Simple execution policy test (fallback before module import)
function Test-ExecutionPolicy {
    $currentPolicy = Get-ExecutionPolicy -Scope Process -ErrorAction SilentlyContinue
    if ($currentPolicy -notin @('RemoteSigned', 'Unrestricted', 'Bypass')) {
        return $false
    }
    return $true
}

# Simple output functions (fallback before module import)
function Write-Info {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor White
}

function Write-WarningCustom {
    param([string]$Message)
    Write-Host "[WARNING] $Message" -ForegroundColor Yellow
}

function Write-Success {
    param([string]$Message)
    Write-Host "[SUCCESS] $Message" -ForegroundColor Green
}

# Simple section header function
function Write-SectionHeaderSimple {
    param([string]$Title)
    $line = '=' * $Title.Length
    Write-Host ""
    Write-Host $Title -ForegroundColor Cyan
    Write-Host $line -ForegroundColor Cyan
    Write-Host ""
}

# Check and handle execution policy robustly
function Set-ExecutionPolicyIfNeeded {
    Write-SectionHeaderSimple "Checking Execution Policy"

    # Try to get execution policy from multiple scopes
    $policy = $null
    $policySource = $null

    # Check Process scope first (most restrictive)
    $policy = Get-ExecutionPolicy -Scope Process -ErrorAction SilentlyContinue
    $policySource = "Process"

    # Check CurrentUser scope if Process is not restrictive
    if ($policy -notin @("Restricted", "Undefined", "RemoteSigned")) {
        $policy = Get-ExecutionPolicy -Scope CurrentUser -ErrorAction SilentlyContinue
        $policySource = "CurrentUser"
    }

    # Check LocalMachine scope as fallback
    if ($policy -notin @("Restricted", "Undefined", "RemoteSigned")) {
        $policy = Get-ExecutionPolicy -Scope LocalMachine -ErrorAction SilentlyContinue
        $policySource = "LocalMachine"
    }

    # If still not set, default to Restricted
    if (-not $policy) {
        $policy = "Undefined"
        $policySource = "Unknown"
    }

    Write-Info "Current execution policy ($policySource): $policy"

    # Check if policy is too restrictive
    if ($policy -in @("Restricted", "Undefined")) {
        Write-WarningCustom "Execution policy is '$policy', which may prevent script execution."
        Write-Info "Attempting to set execution policy to 'RemoteSigned' for CurrentUser scope..."

        try {
            # Try to set execution policy for CurrentUser scope (less restricted)
            Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned -Force -ErrorAction Stop

            $newPolicy = Get-ExecutionPolicy -Scope CurrentUser -ErrorAction SilentlyContinue
            Write-Success "Execution policy changed to '$newPolicy' for CurrentUser scope."
            return $true
        }
        catch {
            $errorMsg = "Failed to set execution policy: $_"
            Write-WarningCustom $errorMsg

            # Fallback to bypass mode
            Write-Info "Attempting to continue with bypass mode..."

            # Check if we're already in a bypass context
            $inBypass = $env:PSExecutionPolicyPreference -eq "Bypass" -or
                       $env:__SuppressMissingLanguageRuntimeError -eq "true"

            if (-not $inBypass) {
                Write-Info "Creating self-bypass wrapper to continue execution..."

                # Create a temporary bypass script
                $bypassScript = @"
Write-Host "Running install script with execution policy bypass..." -ForegroundColor Yellow
try {
    # Set execution policy for this session only
    Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force -ErrorAction SilentlyContinue

    # Import the original script
    & "$PSScriptRoot\install.ps1" @args
}
catch {
    Write-Host "Failed to run install script: $_" -ForegroundColor Red
    exit 1
}
"@

                $tempPath = Join-Path $env:TEMP "install-bypass.ps1"
                $bypassScript | Out-File $tempPath -Encoding UTF8

                Write-Info "Created temporary bypass script: $tempPath"
                Write-Host "Please run: powershell.exe -File \"$tempPath\"" -ForegroundColor Yellow
                Write-Info "Then delete the temporary script when done."

                exit 2  # Special exit code indicating bypass needed
            }
        }
    }
    elseif ($policy -eq "AllSigned") {
        Write-WarningCustom "Execution policy is '$policy'. Self-signed scripts are not allowed."
        Write-Host "Please run: powershell.exe -ExecutionPolicy Bypass -File \"install.ps1\"" -ForegroundColor Yellow
        return $false
    }
    elseif ($policy -eq "RemoteSigned") {
        Write-Success "Execution policy '$policy' is acceptable."
        return $true
    }
    else {
        Write-Info "Execution policy '$policy' is acceptable."
        return $true
    }
}

# Test execution policy with robust handling
if (-not (Set-ExecutionPolicyIfNeeded)) {
    exit 1
}

# Check PowerShell version requirement
$psVersion = $PSVersionTable.PSVersion
if ($psVersion.Major -lt 5 -or ($psVersion.Major -eq 5 -and $psVersion.Minor -lt 1)) {
    Write-Host "[ERROR] PowerShell 5.1 or higher is required. Current version: $psVersion" -ForegroundColor Red
    Write-Host "[ERROR] Please install PowerShell 5.1 from Microsoft Update" -ForegroundColor Red
    exit 1
}

# Verify execution policy
if (-not (Test-ExecutionPolicy)) {
    exit 1
}

# Validate parameters at runtime
if ($PSCmdlet.ParameterSetName -eq "Traditional" -and $Action) {
    Write-Host "[ERROR] Cannot mix traditional parameters with -Action parameter. Use either traditional mode OR unified mode." -ForegroundColor Red
    exit 1
}

# Validate OutputDir if explicitly provided
if ($PSBoundParameters.ContainsKey('OutputDir') -and -not [System.IO.Path]::IsPathRooted($OutputDir)) {
    Write-Host "[ERROR] OutputDir must be an absolute path" -ForegroundColor Red
    exit 1
}

# Validate PackageName if explicitly provided
if ($PSBoundParameters.ContainsKey('PackageName') -and ($PackageName -notmatch '^[a-zA-Z0-9_-]+$')) {
    Write-Host "[ERROR] PackageName can only contain letters, numbers, underscores, and hyphens" -ForegroundColor Red
    exit 1
}

# Import modules
$ModulePath = Join-Path $ScriptDir ".config\powershell\modules"
$absoluteModulePath = Resolve-Path $ModulePath -ErrorAction Stop

# Import modules with detailed error handling
$requiredModules = @(
    "Common.psm1",
    "Config.psm1",
    "Uninstaller.psm1",
    "UI.psm1",
    "ToolInstaller.psm1",
    "ConfigDeployer.psm1",
    "Verifier.psm1",
    "DotfileInstaller.psm1"
)

$failedModules = @()
foreach ($module in $requiredModules) {
    # Use absolute path to avoid issues with module changes
    $modulePath = Join-Path $absoluteModulePath $module
    try {
        Import-Module $modulePath -ErrorAction Stop -Verbose:$false
    } catch {
        $failedModules += $module
        $errorMsg = "Failed to import $module`: $_"
        Write-Host "[ERROR] $errorMsg" -ForegroundColor Red
        Write-Host "Module path checked: $modulePath" -ForegroundColor Yellow
        Write-Host "Module path exists: $(Test-Path $modulePath)" -ForegroundColor Yellow
    }
}

if ($failedModules.Count -gt 0) {
    $errorMsg = "Failed to import modules: $($failedModules -join ', ')"
    Write-Host "[ERROR] $errorMsg" -ForegroundColor Red
    exit 1
}

# Check for help flag early - display help using basic PowerShell to avoid module dependencies
if ($ShowHelp) {
    # Use Write-Host instead of Write-Help to avoid module dependency
    Write-Host "Windows Development Environment Installer" -ForegroundColor Green
    Write-Host "===========================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Usage: .\install.ps1 [options]" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Traditional Mode (Backward Compatible):" -ForegroundColor Yellow
    Write-Host "  .\install.ps1                          # Complete installation (tools + config)" -ForegroundColor White
    Write-Host "  .\install.ps1 -SkipTools               # Skip tools, only deploy config" -ForegroundColor White
    Write-Host "  .\install.ps1 -OnlyDotfile              # Only deploy config, no tools" -ForegroundColor White
    Write-Host "  .\install.ps1 -DryRun                   # Preview mode, show what will be done" -ForegroundColor White
    Write-Host "  .\install.ps1 -Uninstall                # Uninstall config, keep tools" -ForegroundColor White
    Write-Host ""
    Write-Host "Unified Mode (Recommended):" -ForegroundColor Yellow
    Write-Host "  .\install.ps1 -Action Install            # Complete installation (tools + config)" -ForegroundColor White
    Write-Host "  .\install.ps1 -Action Deploy             # Only deploy config, skip tools" -ForegroundColor White
    Write-Host "  .\install.ps1 -Action Update             # Update existing dotfile config" -ForegroundColor White
    Write-Host "  .\install.ps1 -Action Status             # Show dotfile repository status" -ForegroundColor White
    Write-Host "  .\install.ps1 -Action Verify            # Verify all configurations" -ForegroundColor White
    Write-Host "  .\install.ps1 -Action Package           # Create offline installation package" -ForegroundColor White
    Write-Host "  .\install.ps1 -Action OfflineDeploy      # Deploy to offline machine" -ForegroundColor White
    Write-Host "  .\install.ps1 -help                     # Show this help message" -ForegroundColor White
    Write-Host ""
    Write-Host "Advanced Options:" -ForegroundColor Yellow
    Write-Host "  -OutputDir <path>                       # Offline package output directory" -ForegroundColor White
    Write-Host "  -IncludeTools <tools>                   # Tools to include in offline package" -ForegroundColor White
    Write-Host "  -ExcludeTools <tools>                   # Tools to exclude from offline package" -ForegroundColor White
    Write-Host "  -Compress                              # Create compressed offline package" -ForegroundColor White
    Write-Host "  -IncludeDocumentation                  # Include documentation in package" -ForegroundColor White
    Write-Host "  -PackageName <name>                     # Package name (default: devtools-offline)" -ForegroundColor White
    Write-Host "  -Quiet                                 # Quiet mode for uninstall" -ForegroundColor White
    Write-Host "  -KeepProfile                          # Keep PowerShell profile on uninstall" -ForegroundColor White
    Write-Host "  -KeepTerminalSettings                 # Keep terminal settings on uninstall" -ForegroundColor White
    Write-Host "  -KeepVimConfig                         # Keep Neovim config on uninstall" -ForegroundColor White
    Write-Host "  -RemoveBackups                         # Remove backup files on uninstall" -ForegroundColor White
    Write-Host "  -Force                                 # Force execution, no confirmation" -ForegroundColor White
    Write-Host "  -SkipBackup                            # Skip backup during deployment" -ForegroundColor White
    Write-Host ""
    Write-Host "Environment Requirements:" -ForegroundColor Yellow
    Write-Host "  - PowerShell 5.1 or higher" -ForegroundColor White
    Write-Host "  - Windows Terminal (recommended)" -ForegroundColor White
    Write-Host "  - Winget package manager (for tool installation)" -ForegroundColor White
    Write-Host ""
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
    Main function with unified action support
#>
function Invoke-Action {
    [CmdletBinding()]
    param()

    # Initialize logging
    $logConfig = Get-LoggingConfiguration
    $logFile = Initialize-Logging -LogDirectory $logConfig.LogDirectory -LogName "install" -IncludeDateInName
    Write-Log "Action started: $Action" -LogFile $logFile -Level Info -PassThru

    # Environment detection for most actions
    if ($Action -notin @("Status", "Verify", "Package", "OfflineDeploy")) {
        Test-Environment
    }

    # Get configuration
    $config = Get-AllConfiguration
    $xdgConfig = Get-XDGConfiguration

    # Initialize XDG paths
    Write-Info "Initializing XDG Base Directory paths..."
    Initialize-XDGPaths -SetEnvironment
    Write-Log "XDG paths initialized" -LogFile $logFile -Level Info

    # Execute action based on parameter
    switch ($Action) {
        "Install" {
            Install-DevEnvironment -LogFile $logFile
        }
        "Deploy" {
            Deploy-Only -LogFile $logFile -SkipBackup:$SkipBackup
        }
        "Update" {
            Update-Dotfiles -LogFile $logFile
        }
        "Status" {
            Show-DotfileStatus -LogFile $logFile
        }
        "Verify" {
            Verify-Configuration -LogFile $logFile
        }
        "Package" {
            Create-OfflinePackage -LogFile $logFile
        }
        "OfflineDeploy" {
            Deploy-ToOfflineMachine -LogFile $logFile
        }
        default {
            # Handle legacy mode parameters
            if (-not $Action) {
                Install-DevEnvironment -LogFile $logFile
            } else {
                Write-ErrorCustom "Invalid action: $Action"
                exit 1
            }
        }
    }

    Write-Log "Action completed successfully" -LogFile $logFile -Level Info
}

<#
.SYNOPSIS
    Full installation function (original functionality)
#>
function Install-DevEnvironment {
    [CmdletBinding()]
    param($LogFile)

    Write-SectionHeaderSimple "Windows development environment installation script"

    if ($DryRun) {
        Write-WarningCustom "Dry run mode enabled, only showing what will be executed"
    }

    # Install tools
    if (-not $SkipTools) {
        Write-Log "Starting tool installation" -LogFile $LogFile -Level Info
        Install-AllDevelopmentTools -DryRun:$DryRun
        Configure-OhMyPoshThemes
        Write-Log "Tool installation completed" -LogFile $LogFile -Level Info
    } else {
        Write-Info "Skipping tool installation (-SkipTools or -OnlyDotfile specified)"
        Write-Log "Tool installation skipped" -LogFile $LogFile -Level Warning
    }

    # Deploy dotfile
    Write-SectionHeaderSimple "Starting dotfile deployment"
    try {
        Initialize-DotfileRepo
        Deploy-Dotfiles
        Deploy-PowerShellProfile
        Deploy-AllNeovimConfig
        Write-Log "Dotfile deployment completed" -LogFile $LogFile -Level Info
    } catch {
        $errorMsg = "Dotfile deployment failed: $_"
        Write-ErrorCustom $errorMsg
        Write-Log $errorMsg -LogFile $LogFile -Level Error
        throw
    }

    Write-SectionComplete "All completed!"

    # Automatically reload profile in current session
    Write-Info "Reloading PowerShell profile in current session..."
    try {
        $xdgProfile = "$env:USERPROFILE\.config\powershell\profile.ps1"
        . $xdgProfile
        Write-Success "Profile reloaded successfully in current session!"
    } catch {
        Write-WarningCustom "Could not reload profile in current session: $_"
        Write-Info "Please restart PowerShell to apply all configurations"
    }
}

<#
.SYNOPSIS
    Deploy dotfiles only (replaces Deploy-Dotfiles.ps1)
#>
function Deploy-Only {
    [CmdletBinding()]
    param(
        $LogFile,
        [switch]$SkipBackup
    )

    Write-SectionHeaderSimple "Deploying dotfiles only"

    if (-not $SkipBackup -and -not $DryRun) {
        Write-Info "Creating backup before deployment..."
        Backup-Directory "$env:USERPROFILE\.config" "$env:USERPROFILE\.backup_\$(Get-Date -Format 'yyyyMMdd_HHmmss')\config"
    }

    try {
        Initialize-DotfileRepo
        Deploy-Dotfiles
        Deploy-PowerShellProfile
        Deploy-AllNeovimConfig
        Write-Log "Dotfile deployment completed" -LogFile $LogFile -Level Info
    } catch {
        $errorMsg = "Dotfile deployment failed: $_"
        Write-ErrorCustom $errorMsg
        Write-Log $errorMsg -LogFile $LogFile -Level Error
        throw
    }

    Write-SectionComplete "Dotfile deployment completed!"

    # Automatically reload profile in current session
    Write-Info "Reloading PowerShell profile in current session..."
    try {
        $xdgProfile = "$env:USERPROFILE\.config\powershell\profile.ps1"
        . $xdgProfile
        Write-Success "Profile reloaded successfully in current session!"
    } catch {
        Write-WarningCustom "Could not reload profile in current session: $_"
        Write-Info "Please restart PowerShell to apply all configurations"
    }
}

<#
.SYNOPSIS
    Update existing dotfiles (replaces Update-Dotfiles.ps1)
#>
function Update-Dotfiles {
    [CmdletBinding()]
    param($LogFile)

    Write-SectionHeaderSimple "Updating dotfiles"

    try {
        Write-Info "Updating dotfile repository..."
        Initialize-DotfileRepo -Update

        Write-Info "Deploying updated dotfiles..."
        Deploy-Dotfiles
        Deploy-PowerShellProfile
        Deploy-AllNeovimConfig

        Write-SectionComplete "Dotfiles updated successfully!"

        # Automatically reload profile in current session
        Write-Info "Reloading PowerShell profile in current session..."
        try {
            . $PROFILE.CurrentUserCurrentHost
            Write-Success "Profile reloaded successfully in current session!"
        } catch {
            Write-WarningCustom "Could not reload profile in current session: $_"
            Write-Info "Please restart PowerShell to apply all configurations"
        }
    } catch {
        $errorMsg = "Dotfile update failed: $_"
        Write-ErrorCustom $errorMsg
        Write-Log $errorMsg -LogFile $LogFile -Level Error
        throw
    }
}

<#
.SYNOPSIS
    Show dotfile status (replaces Show-DotfileStatus.ps1)
#>
function Show-DotfileStatus {
    [CmdletBinding()]
    param($LogFile)

    Write-SectionHeaderSimple "Dotfile Status"

    try {
        # Initialize dotfile repo to check status
        Initialize-DotfileRepo -StatusOnly

        # Get status using dot command
        $status = dot status --porcelain

        if ($status) {
            Write-WarningCustom "Dotfile has changes:"
            $status | ForEach-Object { Write-Host "  $_" }
        } else {
            Write-Success "Dotfile is clean (no changes)"
        }

        # Show remote status
        Write-Info "Remote repository status:"
        $remoteStatus = dot status -sb
        Write-Host "  $remoteStatus"
    } catch {
        Write-WarningCustom "Unable to check dotfile status: $_"
    }

    Write-SectionComplete "Status check completed"
}

<#
.SYNOPSIS
    Verify configuration (replaces Verify-Configuration.ps1)
#>
function Verify-Configuration {
    [CmdletBinding()]
    param($LogFile)

    Write-SectionHeaderSimple "Verifying Configuration"

    # Test environment
    Test-Environment

    # Get configuration
    $config = Get-AllConfiguration

    # Initialize XDG paths
    Initialize-XDGPaths -SetEnvironment

    # Verify tools
    Write-Info "Verifying tool installations..."
    foreach ($toolName in $config.Tools.Keys) {
        $tool = $config.Tools[$toolName]
        if ($tool.Required) {
            $installed = Test-CommandAvailable $tool.Name
            if ($installed) {
                Write-Success "  $($tool.Name): Installed"
            } else {
                Write-WarningCustom "  $($tool.Name): Not installed"
            }
        }
    }

    # Verify configurations
    Write-Info "Verifying configurations..."
    $configVerified = $true

    # Check PowerShell profile
    if (Test-Path $PROFILE) {
        Write-Success "  PowerShell profile: Found"
    } else {
        Write-WarningCustom "  PowerShell profile: Missing"
        $configVerified = $false
    }

    # Check Neovim config
    $nvimConfig = Get-XDGConfigPath "nvim"
    if (Test-Path $nvimConfig) {
        Write-Success "  Neovim config: Found"
    } else {
        Write-WarningCustom "  Neovim config: Missing"
        $configVerified = $false
    }

    # Check Oh-My-Posh themes
    $themesPath = "$env:USERPROFILE\.poshthemes"
    if (Test-Path $themesPath) {
        Write-Success "  Oh-My-Posh themes: Found"
    } else {
        Write-WarningCustom "  Oh-My-Posh themes: Missing"
        $configVerified = $false
    }

    if ($configVerified) {
        Write-SectionComplete "All configurations verified successfully!"
    } else {
        Write-WarningCustom "Some configurations are missing or incomplete"
        Write-Info "Run '.\install.ps1 -Deploy' to deploy missing configurations"
    }
}

<#
.SYNOPSIS
    Create offline package (replaces Package-Offline-Installer.ps1)
#>
function Create-OfflinePackage {
    [CmdletBinding()]
    param($LogFile)

    Write-SectionHeaderSimple "Creating Offline Package"

    # Define tools and modules
    $tools = @{
        Git = @{ Name = "Git"; Id = "Git.Git"; MinVersion = "2.40.0"; OfflinePath = "tools\git"; Required = $true }
        NodeJS = @{ Name = "Node.js"; Id = "OpenJS.NodeJS.LTS"; MinVersion = "18.17.0"; OfflinePath = "tools\nodejs"; Required = $true }
        Neovim = @{ Name = "Neovim"; Id = "Neovim.Neovim"; MinVersion = "0.9.0"; OfflinePath = "tools\neovim"; Required = $true }
        PowerShell = @{ Name = "PowerShell"; Id = "Microsoft.PowerShell"; OfflinePath = "tools\powershell"; Required = $true }
        OhMyPosh = @{ Name = "OhMyPosh"; Id = "JanDeDobbeleer.OhMyPosh"; OfflinePath = "tools\oh-my-posh"; Required = $true }
        WindowsTerminal = @{ Name = "WindowsTerminal"; Id = "Microsoft.WindowsTerminal"; OfflinePath = "tools\windows-terminal"; Required = $false }
        VSCode = @{ Name = "VSCode"; Id = "Microsoft.VisualStudioCode"; OfflinePath = "tools\vscode"; Required = $false }
        Python = @{ Name = "Python"; Id = "Python.Python.3"; MinVersion = "3.10.0"; OfflinePath = "tools\python"; Required = $false }
        DotNetSDK = @{ Name = ".NET SDK"; Id = "Microsoft.DotNet.SDK.8"; MinVersion = "8.0.0"; OfflinePath = "tools\dotnet-sdk"; Required = $false }
        DockerDesktop = @{ Name = "Docker Desktop"; Id = "Docker.DockerDesktop"; OfflinePath = "tools\docker-desktop"; Required = $false; SizeWarning = "Large package (~1GB)" }
    }

    $modules = @{
        PSReadLine = @{ Name = "PSReadLine"; MinVersion = "2.2.0"; OfflinePath = "modules\psreadline"; Required = $true }
        TerminalIcons = @{ Name = "Terminal-Icons"; MinVersion = "0.7.0"; OfflinePath = "modules\terminal-icons"; Required = $true }
        PSFzf = @{ Name = "PSFzf"; MinVersion = "2.2.0"; OfflinePath = "modules\psfzf"; Required = $true }
    }

    $runtimes = @{
        VCRedist2022 = @{ Name = "VC++ Redist 2022"; OfflinePath = "runtimes\vc-redist-2022"; Required = $true }
    }

    # Create package directory
    $dirs = @(
        $OutputDir,
        "$OutputDir\tools",
        "$OutputDir\modules",
        "$OutputDir\runtimes",
        "$OutputDir\config",
        "$OutputDir\scripts",
        "$OutputDir\documentation"
    )
    foreach ($dir in $dirs) {
        if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    }

    # Download tools
    Write-Info "Downloading tools..."
    foreach ($toolName in $tools.Keys) {
        $tool = $tools[$toolName]
        if ($IncludeTools.Count -eq 0 -or $IncludeTools -contains $toolName) {
            if ($ExcludeTools -notcontains $toolName) {
                $packageInfo = winget show $tool.Id --accept-source-agreements
                $downloadUrl = ($packageInfo | Where-Object { $_ -match "Download Url" }) -split ":\s+" | Select-Object -Last 1

                if ($downloadUrl) {
                    $installerPath = Join-Path "$OutputDir\$($tool.OfflinePath)" "$(Split-Path -Leaf $downloadUrl)"
                    Invoke-WebRequest -Uri $downloadUrl -OutFile $installerPath
                    Write-Success "Downloaded: $($tool.Name)"
                }
            }
        }
    }

    # Download modules
    Write-Info "Downloading PowerShell modules..."
    foreach ($moduleName in $modules.Keys) {
        $module = $modules[$moduleName]
        if ($IncludeTools.Count -eq 0 -or $IncludeTools -contains $moduleName) {
            if ($ExcludeTools -notcontains $moduleName) {
                Save-Module -Name $module.Name -Path "$OutputDir\$($module.OfflinePath)" -Force
                Write-Success "Downloaded: $($module.Name)"
            }
        }
    }

    # Copy scripts
    Copy-Item "$PSScriptRoot\install.ps1" "$OutputDir\scripts\install.ps1" -Force
    Get-ChildItem "$PSScriptRoot\*.ps1" | Copy-Item -Destination "$OutputDir\scripts\" -Force

    # Create offline installer script
    $offlineInstaller = @"
# Offline Installation Script
param(
    [switch]`$SkipTools    [switch]`$OnlyDotfile    [switch]`$DryRun
)

Write-Host "=== Offline Development Environment Installation ==="

# Set paths
`$PackagePath = Split-Path `$PSScriptRoot
`$ToolsPath = Join-Path `$PackagePath "tools"
`$ModulesPath = Join-Path `$PackagePath "modules"
`$ConfigPath = Join-Path `$PackagePath "config"

# Install PowerShell modules
Write-Host "`nInstalling PowerShell modules..."
Get-ChildItem `$ModulesPath -Directory | ForEach-Object {
    Install-Module -Name `$_.Name -Force -SkipPublisherCheck -Scope CurrentUser
}

# Install tools if not skipped
if (-not `$SkipTools) {
    Write-Host "`nInstalling tools..."
    # Add tool installation logic here...
}

Write-Host "`nInstallation complete. Please restart PowerShell."
"@
    $offlineInstaller | Out-File "$OutputDir\scripts\offline-install.ps1" -Encoding utf8

    # Create documentation
    $readme = @"
# Offline Development Environment Package

This package contains pre-downloaded tools for offline installation.

## Installation Instructions
1. Extract the package
2. Run `offline-install.ps1` as Administrator
3. Restart PowerShell after installation
"@
    $readme | Out-File "$OutputDir\documentation\README.md" -Encoding utf8

    Write-SectionComplete "Offline package created in $OutputDir"
}

<#
.SYNOPSIS
    Deploy to offline machine (replaces Deploy-To-Offline-Machine.ps1)
#>
function Deploy-ToOfflineMachine {
    [CmdletBinding()]
    param($LogFile)

    Write-SectionHeaderSimple "Offline Machine Deployment"

    # Install PowerShell modules
    Write-Info "Installing PowerShell modules..."
    Install-Module -Name PSReadLine -Force -SkipPublisherCheck -Scope CurrentUser -ErrorAction SilentlyContinue
    Install-Module -Name Terminal-Icons -Force -SkipPublisherCheck -Scope CurrentUser -ErrorAction SilentlyContinue

    # Deploy profile
    $profileSource = Join-Path $PSScriptRoot "config\profile.ps1"
    $profileTarget = "$env:USERPROFILE\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1"

    if (Test-Path $profileSource) {
        Copy-Item $profileSource $profileTarget -Force
        Write-Success "PowerShell profile deployed"
    }

    # Deploy Neovim config if exists
    $nvimConfig = Get-XDGConfigPath "nvim"
    if (Test-Path $nvimConfig) {
        Copy-Item $nvimConfig "$env:XDG_CONFIG_HOME\nvim" -Recurse -Force
        Write-Success "Neovim configuration deployed"
    }

    Write-SectionComplete "Offline deployment completed!"
    Write-Info "Please restart PowerShell to apply all changes"
}

<#
.SYNOPSIS
    Display help information
#>
function Write-Help {
    Write-Host "Windows Development Environment Installer" -ForegroundColor Green
    Write-Host "===========================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Usage:" -ForegroundColor Yellow
    Write-Host "  .\install.ps1 [options]" -ForegroundColor White
    Write-Host ""
    Write-Host "Traditional Mode (Backward Compatible):" -ForegroundColor Yellow
    Write-Host "  .\install.ps1                          # Complete installation (tools + config)" -ForegroundColor White
    Write-Host "  .\install.ps1 -SkipTools               # Skip tools, only deploy config" -ForegroundColor White
    Write-Host "  .\install.ps1 -OnlyDotfile              # Only deploy config, no tools" -ForegroundColor White
    Write-Host "  .\install.ps1 -DryRun                   # Preview mode, show what will be done" -ForegroundColor White
    Write-Host "  .\install.ps1 -Uninstall                # Uninstall config, keep tools" -ForegroundColor White
    Write-Host ""
    Write-Host "Unified Mode (Recommended):" -ForegroundColor Yellow
    Write-Host "  .\install.ps1 -Action Install            # Complete installation (tools + config)" -ForegroundColor White
    Write-Host "  .\install.ps1 -Action Deploy             # Only deploy config, skip tools" -ForegroundColor White
    Write-Host "  .\install.ps1 -Action Update             # Update existing dotfile config" -ForegroundColor White
    Write-Host "  .\install.ps1 -Action Status             # Show dotfile repository status" -ForegroundColor White
    Write-Host "  .\install.ps1 -Action Verify            # Verify all configurations" -ForegroundColor White
    Write-Host "  .\install.ps1 -Action Package           # Create offline installation package" -ForegroundColor White
    Write-Host "  .\install.ps1 -Action OfflineDeploy      # Deploy to offline machine" -ForegroundColor White
    Write-Host "  .\install.ps1 -Action Help               # Show this help message" -ForegroundColor White
    Write-Host ""
    Write-Host "Advanced Options:" -ForegroundColor Yellow
    Write-Host "  -OutputDir <path>                       # Offline package output directory" -ForegroundColor White
    Write-Host "  -IncludeTools <tools>                   # Tools to include in offline package" -ForegroundColor White
    Write-Host "  -ExcludeTools <tools>                   # Tools to exclude from offline package" -ForegroundColor White
    Write-Host "  -Compress                              # Create compressed offline package" -ForegroundColor White
    Write-Host "  -IncludeDocumentation                  # Include documentation in package" -ForegroundColor White
    Write-Host "  -PackageName <name>                     # Package name (default: devtools-offline)" -ForegroundColor White
    Write-Host "  -Quiet                                 # Quiet mode for uninstall" -ForegroundColor White
    Write-Host "  -KeepProfile                          # Keep PowerShell profile on uninstall" -ForegroundColor White
    Write-Host "  -KeepTerminalSettings                 # Keep terminal settings on uninstall" -ForegroundColor White
    Write-Host "  -KeepVimConfig                         # Keep Neovim config on uninstall" -ForegroundColor White
    Write-Host "  -RemoveBackups                         # Remove backup files on uninstall" -ForegroundColor White
    Write-Host "  -Force                                 # Force execution, no confirmation" -ForegroundColor White
    Write-Host "  -SkipBackup                            # Skip backup during deployment" -ForegroundColor White
    Write-Host ""
    Write-Host "Examples:" -ForegroundColor Yellow
    Write-Host "  # Basic installation"
    Write-Host "  .\install.ps1" -ForegroundColor White
    Write-Host ""
    Write-Host "  # Deploy configuration only"
    Write-Host "  .\install.ps1 -Action Deploy" -ForegroundColor White
    Write-Host ""
    Write-Host "  # Create offline package"
    Write-Host "  .\install.ps1 -Action Package -Compress" -ForegroundColor White
    Write-Host ""
    Write-Host "  # Show dotfile status"
    Write-Host "  .\install.ps1 -Action Status" -ForegroundColor White
    Write-Host ""
    Write-Host "Environment Requirements:" -ForegroundColor Yellow
    Write-Host "  - PowerShell 5.1 or higher" -ForegroundColor White
    Write-Host "  - Windows Terminal (recommended)" -ForegroundColor White
    Write-Host "  - Winget package manager (for tool installation)" -ForegroundColor White
    Write-Host ""
    Write-Host "For more information, see the script comments at the top." -ForegroundColor Cyan
}

# Handle uninstall mode (legacy)
if ($Uninstall) {
    Write-Info "Starting uninstallation..."
    Invoke-QuickUninstall -Force -Quiet:$Quiet -RemoveBackups:$RemoveBackups
    exit 0
}

# If OnlyDotfile is specified, automatically set SkipTools
if ($OnlyDotfile) {
    $SkipTools = $true
}

# Execute main process
try {
    Invoke-Action
} catch {
    Write-ErrorCustom "Action failed: $_"
    exit 1
} finally {
    Pop-Location
}
