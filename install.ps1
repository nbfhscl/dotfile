#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Windows 开发环境自动安装脚本

.DESCRIPTION
    自动安装和配置 Windows 开发工具，包括：
    - Windows Terminal, PowerShell 7
    - Git, Node.js, Neovim
    - Oh-My-Posh, PSReadLine 等增强工具
    - dotfile 自动部署

    使用方式（一键安装）: irm https://raw.githubusercontent.com/nbfhscl/dotfile/refs/heads/master/install.ps1 | iex

.EXAMPLE
    .\install.ps1

.EXAMPLE
    .\install.ps1 -SkipTools -OnlyDotfile

.EXAMPLE
    irm https://raw.githubusercontent.com/nbfhscl/dotfile/refs/heads/master/install.ps1 | iex

.EXAMPLE
    irm https://raw.githubusercontent.com/nbfhscl/dotfile/refs/heads/master/install.ps1 | iex; .\install.ps1 -OnlyDotfile

.PARAMETER SkipTools
    跳过工具安装，只部署 dotfile

.PARAMETER OnlyDotfile
    只部署 dotfile，不安装任何工具

.PARAMETER DryRun
    预演模式，只显示将要执行的操作
#>

param(
    [switch]$SkipTools = $false,
    [switch]$OnlyDotfile = $false,
    [switch]$DryRun = $false
)

# 如果指定了 OnlyDotfile，自动设置 SkipTools
if ($OnlyDotfile) {
    $SkipTools = $true
}

# 配置
$REPO_URL = "https://github.com/nbfhscl/dotfile.git"
$DOT_DIR = "$env:USERPROFILE\.dotfile"
$BACKUP_DIR = "$env:USERPROFILE\.dotfile_backup_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
$ALIAS_NAME = "dot"

# 颜色输出辅助函数
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

# 环境检测函数
function Test-PowerShellVersion {
    $currentVersion = $PSVersionTable.PSVersion
    Write-Info "当前 PowerShell 版本: $currentVersion"

    if ($currentVersion.Major -lt 7) {
        Write-Error "需要 PowerShell 7.0 或更高版本"
        Write-Info "请运行: winget install Microsoft.PowerShell"
        exit 1
    }

    Write-Success "PowerShell 版本检查通过"
    return $true
}

function Test-WingetAvailable {
    if (Get-Command winget -ErrorAction SilentlyContinue) {
        Write-Success "winget 已安装"
        return $true
    } else {
        Write-Warning "winget 未安装"
        Write-Info "请从 Microsoft Store 安装 Windows Package Manager"
        return $false
    }
}

function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    $isAdmin = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

    if ($isAdmin) {
        Write-Success "管理员权限检测通过"
        return $true
    } else {
        Write-Warning "未检测到管理员权限"
        Write-Info "某些操作可能需要管理员权限"
        return $false
    }
}

# 手动安装下载链接
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
        Write-Warning "请手动安装 $ToolName:"
        Write-Info "下载地址: $($ManualInstallLinks[$ToolName])"
    }
}

function Install-Package {
    param(
        [string]$PackageName,
        [string]$WingetId,
        [switch]$Required = $true
    )

    if ($DryRun) {
        Write-Info "[DRY-RUN] 将安装 $PackageName (使用 winget)"
        return $true
    }

    # 检查是否已安装
    $packageCommand = $PackageName -replace ' ', ''
    if (Get-Command $packageCommand -ErrorAction SilentlyContinue) {
        Write-Success "$PackageName 已安装"
        return $true
    }

    Write-Info "正在安装 $PackageName..."

    if (-not (Test-WingetAvailable)) {
        if ($Required) {
            Write-Error "winget 不可用，无法安装 $PackageName"
            Show-ManualInstallHelp -ToolName $PackageName
            return $false
        } else {
            Write-Warning "跳过可选工具 $PackageName"
            return $true
        }
    }

    # 使用 winget 安装
    $result = & winget install --id $WingetId --accept-source-agreements --accept-package-agreements -e 2>&1

    if ($LASTEXITCODE -eq 0) {
        Write-Success "$PackageName 安装完成"

        # 刷新环境变量
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
        return $true
    } else {
        Write-Error "$PackageName 安装失败"
        if ($Required) {
            Show-ManualInstallHelp -ToolName $PackageName
        }
        return $false
    }
}

# 核心工具安装函数
function Install-WindowsTerminal {
    if (Get-Command wt -ErrorAction SilentlyContinue) {
        Write-Success "Windows Terminal 已安装"
        return $true
    }
    Write-Info "正在安装 Windows Terminal..."
    Install-Package -PackageName "Windows Terminal" -WingetId "Microsoft.WindowsTerminal"
}

function Install-PowerShell7 {
    if ($PSVersionTable.PSVersion.Major -ge 7) {
        Write-Success "PowerShell 7 已安装"
        return $true
    }
    Write-Info "正在安装 PowerShell 7..."
    Install-Package -PackageName "PowerShell" -WingetId "Microsoft.PowerShell"
}

function Install-Git {
    Write-Info "正在安装 Git..."
    Install-Package -PackageName "Git" -WingetId "Git.Git" -Required
}

function Install-Nodejs {
    Write-Info "正在安装 Node.js 和 npm..."
    Install-Package -PackageName "Node.js" -WingetId "OpenJS.NodeJS.LTS" -Required
}

function Install-Neovim {
    Write-Info "正在安装 Neovim..."
    Install-Package -PackageName "Neovim" -WingetId "Neovim.Neovim" -Required
}

# ============================================
# Task 5: PowerShell 模块安装
# ============================================

function Install-OhMyPosh {
    if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) {
        Write-Success "Oh-My-Posh 已安装"
        return $true
    }
    Write-Info "正在安装 Oh-My-Posh..."
    if ($DryRun) { return $true }
    try {
        & winget install --id JanDeDobbeleer.OhMyPosh -e --accept-source-agreements --accept-package-agreements 2>&1 | Out-Null
        if ($LASTEXITCODE -eq 0) {
            Write-Success "Oh-My-Posh 安装完成"
            return $true
        } else {
            # 备用：使用 PowerShell 模块
            Install-Module -Name oh-my-posh -Force -Scope CurrentUser -AllowClobber
            return $true
        }
    } catch {
        Write-Error "Oh-My-Posh 安装失败: $_"
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
            Write-Success "$moduleName 已安装"
            continue
        }
        Write-Info "正在安装 $moduleName..."
        if ($DryRun) { continue }
        try {
            Install-Module -Name $moduleName -Force -Scope CurrentUser -AllowClobber -ErrorAction Stop
            Write-Success "$moduleName 安装完成"
        } catch {
            if ($required) {
                Write-Error "$moduleName 安装失败: $_"
            } else {
                Write-Warning "$moduleName 安装失败（可选工具）"
            }
        }
    }
}

function Install-Zoxide {
    if (Get-Command zoxide -ErrorAction SilentlyContinue) {
        Write-Success "zoxide 已安装"
        return $true
    }
    Write-Info "正在安装 zoxide..."
    Install-Package -PackageName "zoxide" -WingetId "ajeetdsouza.zoxide" -Required:$false
}

# ============================================
# Task 6: PowerShell Profile 配置
# ============================================

function Deploy-PowerShellProfile {
    Write-Info "正在配置 PowerShell Profile..."
    $profileDir = Split-Path -Parent $PROFILE.CurrentUserCurrentHost
    $profilePath = $PROFILE.CurrentUserCurrentHost

    if (-not (Test-Path $profileDir)) {
        New-Item -ItemType Directory -Path $profileDir -Force | Out-Null
    }

    if (Test-Path $profilePath) {
        $backupPath = "$profilePath.backup"
        Write-Warning "发现现有 profile，备份到: $backupPath"
        Copy-Item $profilePath $backupPath -Force
    }

    $sourceProfile = ".config/powershell/profile.ps1"
    if (Test-Path $sourceProfile) {
        Write-Info "从 dotfile 部署 profile..."
        Copy-Item $sourceProfile $profilePath -Force
    } else {
        Write-Warning "未找到 dotfile 中的 profile，跳过"
    }

    Write-Success "PowerShell Profile 配置完成"
    Write-Info "请运行 '. \$PROFILE' 或重启 PowerShell 以应用配置"
}

# ============================================
# Task 7: dotfile 部署
# ============================================

function Initialize-DotfileRepo {
    if (Test-Path $DOT_DIR) {
        Write-Warning ".dotfile 目录已存在，将更新而非重新克隆"
        Push-Location $DOT_DIR
        & git fetch origin 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Success "dotfile 仓库更新完成"
        } else {
            Write-Warning "更新失败，将继续使用现有版本"
        }
        Pop-Location
    } else {
        Write-Info "正在克隆 dotfile 仓库..."
        & git clone --bare $REPO_URL $DOT_DIR 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Success "dotfile 仓库克隆完成"
        } else {
            Write-Error "无法克隆 dotfile 仓库"
            exit 1
        }
    }
}

function Deploy-Dotfiles {
    Write-Info "正在部署 dotfile..."

    function dot {
        & git --git-dir="$DOT_DIR" --work-tree="$env:USERPROFILE" $args
    }

    Write-Info "检查文件冲突..."
    $trackedFiles = dot ls-tree -r --name-only HEAD 2>$null
    $conflicts = @()

    foreach ($file in $trackedFiles) {
        $targetPath = Join-Path $env:USERPROFILE $file
        if (Test-Path $targetPath) {
            $conflicts += $file
        }
    }

    if ($conflicts.Count -gt 0) {
        Write-Warning "发现 $($conflicts.Count) 个冲突文件，将备份..."
        New-Item -ItemType Directory -Path $BACKUP_DIR -Force | Out-Null

        foreach ($file in $conflicts) {
            $sourcePath = Join-Path $env:USERPROFILE $file
            $backupPath = Join-Path $BACKUP_DIR $file
            $backupDir = Split-Path -Parent $backupPath

            if (-not (Test-Path $backupDir)) {
                New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
            }

            Copy-Item $sourcePath $backupPath -Force
            Write-Info "  → 备份: $file"
        }

        Write-Success "备份已保存至: $BACKUP_DIR"
    } else {
        Write-Success "没有发现冲突文件"
    }

    Write-Info "正在部署 dotfile..."
    dot checkout -f 2>$null

    if ($LASTEXITCODE -eq 0) {
        Write-Success "dotfile 部署完成"
        dot config --local status.showUntrackedFiles no
        Deploy-WindowsTerminalSettings
        Add-DotAliasToProfile
        return $true
    } else {
        Write-Error "dotfile 部署失败"
        return $false
    }
}

function Deploy-WindowsTerminalSettings {
    Write-Info "正在配置 Windows Terminal..."
    $terminalSettingsPath = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
    if (-not (Test-Path $terminalSettingsPath)) {
        Write-Warning "未找到 Windows Terminal 配置文件，跳过"
        return
    }
    $backupPath = "$terminalSettingsPath.backup"
    Write-Info "备份现有配置到: $backupPath"
    Copy-Item $terminalSettingsPath $backupPath -Force
    $sourceSettings = ".config/windows-terminal/settings.json"
    if (Test-Path $sourceSettings) {
        Write-Info "从 dotfile 部署 Windows Terminal 配置..."
        Copy-Item $sourceSettings $terminalSettingsPath -Force
        Write-Success "Windows Terminal 配置完成"
        Write-Info "请重启 Windows Terminal 以应用配置"
    } else {
        Write-Warning "未找到 dotfile 中的 Windows Terminal 配置"
    }
}

function Add-DotAliasToProfile {
    $profilePath = $PROFILE.CurrentUserCurrentHost
    $aliasLine = "function dot { git --git-dir=`$env:USERPROFILE\.dotfile --work-tree=`$env:USERPROFILE `$args }"

    if (-not (Test-Path $profilePath)) { return }

    $profileContent = Get-Content $profilePath -Raw
    if ($profileContent -notmatch 'function dot') {
        Write-Info "添加 'dot' 别名到 PowerShell Profile..."
        Add-Content -Path $profilePath -Value "`n# dotfile alias (自动添加)`n$aliasLine"
        Write-Success "'dot' 别名已添加"
    }
}

# ============================================
# 主流程
# ============================================

function Install-AllTools {
    Write-Info "=========================================="
    Write-Info "开始安装开发工具"
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
    Write-Success "开发工具安装完成"
    Write-Success "=========================================="
}

function main {
    Write-Info "=========================================="
    Write-Info "Windows 开发环境安装脚本"
    Write-Info "=========================================="

    if ($DryRun) {
        Write-Warning "预演模式已启用，只显示将要执行的操作"
    }

    # 环境检测
    Test-PowerShellVersion
    Test-WingetAvailable
    Test-Administrator

    # 安装工具
    if (-not $SkipTools) {
        Install-AllTools
    } else {
        Write-Info "跳过工具安装（已指定 -SkipTools 或 -OnlyDotfile）"
    }

    # 部署 dotfile
    Write-Info "=========================================="
    Write-Info "开始部署 dotfile"
    Write-Info "=========================================="

    Initialize-DotfileRepo
    Deploy-Dotfiles
    Deploy-PowerShellProfile

    Write-Success "=========================================="
    Write-Success "全部完成！"
    Write-Success "=========================================="
    Write-Info "请重启 PowerShell 或运行 '. \$PROFILE' 以应用所有配置"
}

# 执行主流程
main
