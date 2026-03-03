# Windows PowerShell 安装脚本实现计划

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**目标:** 创建一个 Windows PowerShell 自动安装脚本，为 Windows 开发者配置完整的开发环境（Git, Node.js, Neovim, PowerShell 7, Oh-My-Posh 等）

**架构:** 单文件 PowerShell 脚本，使用 winget 包管理器安装工具，通过 PowerShell Gallery 安装模块，配置 Windows Terminal 和 PowerShell Profile

**技术栈:** PowerShell 7+, winget, PowerShell Gallery, Windows Terminal

---

## Task 1: 创建基础脚本结构和辅助函数

**Files:**
- Create: `install.ps1`

**Step 1: 写脚本基础结构和参数定义**

```powershell
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

.EXAMPLE
    .\install.ps1

.EXAMPLE
    .\install.ps1 -SkipTools -OnlyDotfile

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
```

**Step 2: 添加日志输出辅助函数**

```powershell
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
```

**Step 3: 提交基础结构**

```bash
git add install.ps1
git commit -m "feat: 添加 Windows PowerShell 安装脚本基础结构

- 添加脚本参数和配置
- 添加日志输出辅助函数
- 添加脚本文档注释"
```

---

## Task 2: 实现环境检测函数

**Files:**
- Modify: `install.ps1`

**Step 1: 添加 PowerShell 版本检测**

```powershell
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
```

**Step 2: 添加 winget 可用性检测**

```powershell
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
```

**Step 3: 添加管理员权限检测**

```powershell
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
```

**Step 4: 提交环境检测函数**

```bash
git add install.ps1
git commit -m "feat: 添加环境检测函数

- 添加 PowerShell 版本检测 (需要 ≥ 7.0)
- 添加 winget 可用性检测
- 添加管理员权限检测"
```

---

## Task 3: 实现包安装函数

**Files:**
- Modify: `install.ps1`

**Step 1: 添加通用包安装函数**

```powershell
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
```

**Step 2: 添加手动安装帮助函数**

```powershell
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
```

**Step 3: 提交包安装函数**

```bash
git add install.ps1
git commit -m "feat: 添加通用包安装函数

- 添加 Install-Package 函数支持 winget 安装
- 添加 Show-ManualInstallHelp 函数提供手动下载链接
- 自动刷新环境变量
- 支持 DRY_RUN 模式"
```

---

## Task 4: 实现核心工具安装

**Files:**
- Modify: `install.ps1`

**Step 1: 添加 Windows Terminal 安装**

```powershell
function Install-WindowsTerminal {
    if (Get-Command wt -ErrorAction SilentlyContinue) {
        Write-Success "Windows Terminal 已安装"
        return $true
    }

    Write-Info "正在安装 Windows Terminal..."
    Install-Package -PackageName "Windows Terminal" -WingetId "Microsoft.WindowsTerminal"
}
```

**Step 2: 添加 PowerShell 7 安装**

```powershell
function Install-PowerShell7 {
    # 已经在 Test-PowerShellVersion 中检查，这里只安装
    if ($PSVersionTable.PSVersion.Major -ge 7) {
        Write-Success "PowerShell 7 已安装"
        return $true
    }

    Write-Info "正在安装 PowerShell 7..."
    Install-Package -PackageName "PowerShell" -WingetId "Microsoft.PowerShell"
}
```

**Step 3: 添加 Git 安装**

```powershell
function Install-Git {
    Write-Info "正在安装 Git..."
    Install-Package -PackageName "Git" -WingetId "Git.Git" -Required
}
```

**Step 4: 添加 Node.js 安装**

```powershell
function Install-Nodejs {
    Write-Info "正在安装 Node.js 和 npm..."
    Install-Package -PackageName "Node.js" -WingetId "OpenJS.NodeJS.LTS" -Required
}
```

**Step 5: 添加 Neovim 安装**

```powershell
function Install-Neovim {
    Write-Info "正在安装 Neovim..."
    Install-Package -PackageName "Neovim" -WingetId "Neovim.Neovim" -Required
}
```

**Step 6: 提交核心工具安装函数**

```bash
git add install.ps1
git commit -m "feat: 添加核心工具安装函数

- 添加 Install-WindowsTerminal
- 添加 Install-PowerShell7
- 添加 Install-Git
- 添加 Install-Nodejs
- 添加 Install-Neovim"
```

---

## Task 5: 实现 PowerShell 模块安装

**Files:**
- Modify: `install.ps1`

**Step 1: 添加 Oh-My-Posh 安装**

```powershell
function Install-OhMyPosh {
    if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) {
        Write-Success "Oh-My-Posh 已安装"
        return $true
    }

    Write-Info "正在安装 Oh-My-Posh..."

    if ($DryRun) {
        Write-Info "[DRY-RUN] 将安装 Oh-My-Posh"
        return $true
    }

    try {
        & winget install --id JanDeDobbeleer.OhMyPosh -e --accept-source-agreements --accept-package-agreements 2>&1 | Out-Null

        if ($LASTEXITCODE -eq 0) {
            Write-Success "Oh-My-Posh 安装完成"
            return $true
        } else {
            Write-Warning "Oh-My-Posh 安装失败，尝试备用方法..."
            # 备用：使用 PowerShell 模块
            Install-Module -Name oh-my-posh -Force -Scope CurrentUser -AllowClobber
            return $true
        }
    } catch {
        Write-Error "Oh-My-Posh 安装失败: $_"
        return $false
    }
}
```

**Step 2: 添加 PowerShell 模块安装函数**

```powershell
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

        if ($DryRun) {
            Write-Info "[DRY-RUN] 将安装 $moduleName"
            continue
        }

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
```

**Step 3: 添加 zoxide 安装**

```powershell
function Install-Zoxide {
    if (Get-Command zoxide -ErrorAction SilentlyContinue) {
        Write-Success "zoxide 已安装"
        return $true
    }

    Write-Info "正在安装 zoxide..."
    Install-Package -PackageName "zoxide" -WingetId "ajeetdsouza.zoxide" -Required:$false
}
```

**Step 4: 提交 PowerShell 模块安装函数**

```bash
git add install.ps1
git commit -m "feat: 添加 PowerShell 模块安装函数

- 添加 Install-OhMyPosh (主题引擎)
- 添加 Install-PSModules (PSReadLine, Terminal-Icons, PSFzf)
- 添加 Install-Zoxide (智能目录跳转)"
```

---

## Task 6: 实现 PowerShell Profile 配置

**Files:**
- Create: `.config/powershell/profile.ps1`
- Modify: `install.ps1`

**Step 1: 创建 PowerShell Profile 模板**

创建文件 `.config/powershell/profile.ps1`:

```powershell
# ============================================
# PowerShell 7 配置
# 自动生成于: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
# ============================================

# Oh-My-Posh 主题引擎
$env:POSH_THEMES_PATH = "$env:USERPROFILE\.poshthemes"
if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) {
    oh-my-posh init pwsh --config "$env:POSH_THEMES_PATH\paradox.omp.json" | Invoke-Expression
}

# PSReadLine - 命令行编辑增强
if (Get-Module -ListAvailable -Name PSReadLine) {
    Import-Module PSReadLine
    Set-PSReadLineOption -PredictionSource History
    Set-PSReadLineOption -PredictionViewStyle ListView
    Set-PSReadLineKeyHandler -Key "Tab" -Function MenuComplete
}

# Terminal-Icons - 文件/文件夹图标
if (Get-Module -ListAvailable -Name Terminal-Icons) {
    Import-Module Terminal-Icons
}

# zoxide - 智能目录跳转
if (Get-Command zoxide -ErrorAction SilentlyContinue) {
    Invoke-Expression (& { (zoxide init powershell | Out-String) })
}

# PSFzf - 模糊搜索
if (Get-Module -ListAvailable -Name PSFzf) {
    Import-Module PSFzf
    Set-PsFzfOption -PSReadlineChordProvider Ctrl+t -PsReadlineChordReverseHistory Ctrl+r
}

# ============================================
# dotfile 管理
# ============================================

function dot {
    git --git-dir="$env:USERPROFILE\.dotfile" --work-tree="$env:USERPROFILE" $args
}

# ============================================
# 别名
# ============================================

Set-Alias ll Get-ChildItem
Set-Alias grep Select-String
Set-Alias cat Get-Content

# ============================================
# 自定义函数
# ============================================

# 快速编辑 profile
function Edit-Profile {
    & $EDITOR $PROFILE.CurrentUserCurrentHost
}

# 重新加载 profile
function Reload-Profile {
    . $PROFILE.CurrentUserCurrentHost
}

# 显示所有环境变量
function Show-Env {
    Get-ChildItem Env: | Format-Table -AutoSize
}
```

**Step 2: 添加 Profile 部署函数到 install.ps1**

```powershell
function Deploy-PowerShellProfile {
    Write-Info "正在配置 PowerShell Profile..."

    $profileDir = Split-Path -Parent $PROFILE.CurrentUserCurrentHost
    $profilePath = $PROFILE.CurrentUserCurrentHost

    # 确保目录存在
    if (-not (Test-Path $profileDir)) {
        New-Item -ItemType Directory -Path $profileDir -Force | Out-Null
    }

    # 备份现有 profile
    if (Test-Path $profilePath) {
        $backupPath = "$profilePath.backup"
        Write-Warning "发现现有 profile，备份到: $backupPath"
        Copy-Item $profilePath $backupPath -Force
    }

    # 从 dotfile 复制或创建新 profile
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
```

**Step 3: 提交 Profile 配置**

```bash
git add .config/powershell/profile.ps1 install.ps1
git commit -m "feat: 添加 PowerShell Profile 配置

- 创建 PowerShell Profile 模板
- 配置 Oh-My-Posh, PSReadLine, Terminal-Icons
- 配置 zoxide, PSFzf 集成
- 添加 dot 命令和实用别名
- 添加 Deploy-PowerShellProfile 函数"
```

---

## Task 7: 实现 dotfile 部署函数

**Files:**
- Modify: `install.ps1`

**Step 1: 添加 dotfile 克隆/更新函数**

```powershell
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
```

**Step 2: 添加 dotfile 部署函数**

```powershell
function Deploy-Dotfiles {
    Write-Info "正在部署 dotfile..."

    # 定义 dot 函数
    function dot {
        & git --git-dir="$DOT_DIR" --work-tree="$env:USERPROFILE" $args
    }

    # 检查冲突文件
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

        # 创建备份目录
        New-Item -ItemType Directory -Path $BACKUP_DIR -Force | Out-Null

        foreach ($file in $conflicts) {
            $sourcePath = Join-Path $env:USERPROFILE $file
            $backupPath = Join-Path $BACKUP_DIR $file

            # 确保备份目录存在
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

    # 强制检出配置
    Write-Info "正在部署 dotfile..."
    dot checkout -f 2>$null

    if ($LASTEXITCODE -eq 0) {
        Write-Success "dotfile 部署完成"

        # 隐藏未跟踪文件
        dot config --local status.showUntrackedFiles no

        # 添加 alias 到 profile
        Add-DotAliasToProfile

        return $true
    } else {
        Write-Error "dotfile 部署失败"
        return $false
    }
}
```

**Step 3: 添加 dot alias 配置函数**

```powershell
function Add-DotAliasToProfile {
    $profilePath = $PROFILE.CurrentUserCurrentHost
    $aliasLine = "function dot { git --git-dir=`$env:USERPROFILE\.dotfile --work-tree=`$env:USERPROFILE `$args }"

    if (-not (Test-Path $profilePath)) {
        return
    }

    $profileContent = Get-Content $profilePath -Raw

    if ($profileContent -notmatch 'function dot') {
        Write-Info "添加 'dot' 别名到 PowerShell Profile..."
        Add-Content -Path $profilePath -Value "`n# dotfile alias (自动添加)`n$aliasLine"
        Write-Success "'dot' 别名已添加"
    }
}
```

**Step 4: 提交 dotfile 部署函数**

```bash
git add install.ps1
git commit -m "feat: 添加 dotfile 部署函数

- 添加 Initialize-DotfileRepo (克隆/更新仓库)
- 添加 Deploy-Dotfiles (部署配置文件)
- 添加冲突检测和备份
- 添加 Add-DotAliasToProfile"
```

---

## Task 8: 实现主流程和验证

**Files:**
- Modify: `install.ps1`

**Step 1: 添加工具安装主函数**

```powershell
function Install-AllTools {
    Write-Info "开始安装工具..."
    Write-Host ""

    $failedInstalls = @()

    # Windows Terminal 和 PowerShell 7
    Install-WindowsTerminal
    Install-PowerShell7

    # 核心开发工具
    if (-not (Install-Git)) { $failedInstalls += "Git" }
    if (-not (Install-Nodejs)) { $failedInstalls += "Node.js" }
    if (-not (Install-Neovim)) { $failedInstalls += "Neovim" }

    # PowerShell 模块
    Install-OhMyPosh
    Install-PSModules
    Install-Zoxide

    # 显示失败的安装
    if ($failedInstalls.Count -gt 0) {
        Write-Host ""
        Write-Warning "以下工具安装失败："
        foreach ($tool in $failedInstalls) {
            Write-Host "  - $tool"
        }
    }

    return $failedInstalls.Count -eq 0
}
```

**Step 2: 添加验证函数**

```powershell
function Invoke-Verification {
    Write-Host ""
    Write-Info "正在验证安装..."
    Write-Host ""

    $failed = 0
    $tools = @(
        @{ Name = "Git"; Command = "git" },
        @{ Name = "Node.js"; Command = "node" },
        @{ Name = "npm"; Command = "npm" },
        @{ Name = "Neovim"; Command = "nvim" },
        @{ Name = "PowerShell 7"; Test = { $PSVersionTable.PSVersion.Major -ge 7 } }
    )

    foreach ($tool in $tools) {
        $installed = $false

        if ($tool.Command) {
            $installed = Get-Command $tool.Command -ErrorAction SilentlyContinue
        } elseif ($tool.Test) {
            $installed = & $tool.Test
        }

        if ($installed) {
            Write-Success "  ✓ $($tool.Name) 已安装"
        } else {
            Write-Warning "  ✗ $($tool.Name) 未安装"
            $failed++
        }
    }

    # 检查 PowerShell 模块
    $modules = @("PSReadLine", "Terminal-Icons", "oh-my-posh")
    foreach ($module in $modules) {
        $installed = Get-Module -ListAvailable -Name $module
        if ($installed) {
            Write-Success "  ✓ $module 已安装"
        } else {
            Write-Warning "  ✗ $module 未安装"
            $failed++
        }
    }

    Write-Host ""

    if ($failed -eq 0) {
        Write-Success "所有工具安装成功！"
        return $true
    } else {
        Write-Warning "有 $failed 项工具安装失败或未安装"
        return $false
    }
}
```

**Step 3: 添加主函数**

```powershell
function main {
    Write-Host ""
    Write-Host "=========================================="
    Write-Host "  Windows 开发环境自动安装脚本"
    Write-Host "=========================================="
    Write-Host ""

    if ($DryRun) {
        Write-Warning "DRY-RUN 模式：只显示将要执行的操作"
        Write-Host ""
    }

    # 环境检测
    Write-Info "正在检测环境..."
    Test-PowerShellVersion
    Test-WingetAvailable
    Test-Administrator
    Write-Host ""

    # 按依赖顺序安装工具
    if (-not $SkipTools) {
        Write-Info "开始安装工具..."
        Write-Host ""
        Install-AllTools
        Write-Host ""
    } else {
        Write-Info "跳过工具安装 (SkipTools=$true)"
        Write-Host ""
    }

    # 部署 dotfile
    Write-Info "正在部署 dotfile..."
    Write-Host ""
    Initialize-DotfileRepo
    Deploy-PowerShellProfile
    Deploy-Dotfiles
    Write-Host ""

    Write-Host "=========================================="
    Write-Success "安装完成！"
    Write-Host "=========================================="
    Write-Host ""

    # 验证安装
    Invoke-Verification

    # 后续步骤
    Write-Host ""
    Write-Info "后续步骤："
    Write-Host "  1. 重启 PowerShell 或运行: . \`$PROFILE"
    Write-Host "  2. 首次启动 Neovim 会自动安装插件，请耐心等待"
    Write-Host "  3. 使用 'dot' 命令管理 dotfile: dot status"
    Write-Host ""
}

# 运行主程序
main
```

**Step 4: 提交主流程和验证**

```bash
git add install.ps1
git commit -m "feat: 完成主流程和验证功能

- 添加 Install-AllTools 主安装函数
- 添加 Invoke-Verification 验证函数
- 添加 main 主函数
- 添加后续步骤指引"
```

---

## Task 9: 添加 Windows Terminal 配置

**Files:**
- Create: `.config/windows-terminal/settings.json`
- Modify: `install.ps1`

**Step 1: 创建 Windows Terminal 配置模板**

创建文件 `.config/windows-terminal/settings.json`:

```json
{
  "profiles": {
    "defaults": {
      "fontFace": "Cascadia Code",
      "fontSize": 11,
      "cursorShape": "bar",
      "colorScheme": "One Dark Pro",
      "useAcrylic": false,
      "padding": "8, 8, 8, 8"
    },
    "list": [
      {
        "guid": "{574e775e-4f2a-5b96-ac1e-a2962a402336}",
        "name": "PowerShell 7",
        "commandline": "pwsh.exe",
        "hidden": false,
        "icon": "https://raw.githubusercontent.com/microsoft/terminal/main/res/Powershell_32.png"
      }
    ]
  },
  "schemes": [
    {
      "name": "One Dark Pro",
      "background": "#282c34",
      "foreground": "#abb2bf",
      "cursorColor": "#abb2bf",
      "black": "#282c34",
      "red": "#e06c75",
      "green": "#98c379",
      "yellow": "#e5c07b",
      "blue": "#61afef",
      "purple": "#c678dd",
      "cyan": "#56b6c2",
      "white": "#abb2bf",
      "brightBlack": "#5c6370",
      "brightRed": "#e06c75",
      "brightGreen": "#98c379",
      "brightYellow": "#e5c07b",
      "brightBlue": "#61afef",
      "brightPurple": "#c678dd",
      "brightCyan": "#56b6c2",
      "brightWhite": "#ffffff"
    }
  ],
  "theme": "dark"
}
```

**Step 2: 添加 Windows Terminal 配置部署函数**

```powershell
function Deploy-WindowsTerminalSettings {
    Write-Info "正在配置 Windows Terminal..."

    $terminalSettingsPath = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"

    if (-not (Test-Path $terminalSettingsPath)) {
        Write-Warning "未找到 Windows Terminal 配置文件，跳过"
        return
    }

    # 备份现有配置
    $backupPath = "$terminalSettingsPath.backup"
    Write-Info "备份现有配置到: $backupPath"
    Copy-Item $terminalSettingsPath $backupPath -Force

    # 合并配置（简单实现：直接替换）
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
```

**Step 3: 将配置函数集成到主流程**

在 `Deploy-Dotfiles` 函数中添加：

```powershell
function Deploy-Dotfiles {
    # ... 现有代码 ...

    # 配置 Windows Terminal
    Deploy-WindowsTerminalSettings

    # ... 现有代码 ...
}
```

**Step 4: 提交 Windows Terminal 配置**

```bash
git add .config/windows-terminal/settings.json install.ps1
git commit -m "feat: 添加 Windows Terminal 配置

- 创建 Windows Terminal 配置模板
- 配置 One Dark Pro 主题
- 添加 PowerShell 7 配置文件
- 添加 Deploy-WindowsTerminalSettings 函数"
```

---

## Task 10: 更新 README 和文档

**Files:**
- Modify: `README.md`
- Create: `docs/windows-installation-guide.md`

**Step 1: 在 README.md 中添加 Windows 安装说明**

在 README.md 末尾添加：

```markdown
## Windows 安装

在 Windows 10/11 上使用 PowerShell 安装：

```powershell
# 方式 1: 直接运行（需要允许执行脚本）
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
.\install.ps1

# 方式 2: 预览模式
.\install.ps1 -DryRun

# 方式 3: 只部署 dotfile，跳过工具安装
.\install.ps1 -OnlyDotfile
```

### 前置要求

- Windows 10 1903+ 或 Windows 11
- PowerShell 7.0+ (脚本会自动安装)
- Windows Package Manager (winget)
- 互联网连接

### 安装的工具

- Windows Terminal
- PowerShell 7
- Git, Node.js, Neovim
- Oh-My-Posh, PSReadLine, Terminal-Icons
- zoxide, PSFzf

### WSL 用户

如果你更喜欢使用 WSL，可以直接运行 `install.sh`：

```bash
# 在 WSL 中
bash install.sh
```

详细文档请参考：[Windows 安装指南](docs/windows-installation-guide.md)
```

**Step 2: 创建 Windows 安装详细指南**

创建文件 `docs/windows-installation-guide.md`:

```markdown
# Windows 安装指南

本指南详细介绍如何在 Windows 上安装和配置 dotfile 开发环境。

## 系统要求

- Windows 10 版本 1903 或更高
- Windows 11（推荐）
- 管理员权限（某些操作需要）
- 稳定的互联网连接

## 安装步骤

### 1. 安装前置组件

#### Windows Package Manager (winget)

Windows 11 已预装 winget。Windows 10 用户需要从 [Microsoft Store](https://aka.ms/terminal) 安装。

#### PowerShell 7

```powershell
winget install Microsoft.PowerShell
```

### 2. 克隆仓库

```powershell
git clone https://github.com/nbfhscl/dotfile.git $env:USERPROFILE\dotfile-temp
cd $env:USERPROFILE\dotfile-temp
```

### 3. 运行安装脚本

```powershell
# 允许执行脚本
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# 运行安装
.\install.ps1
```

### 4. 重启 PowerShell

安装完成后，重启 PowerShell 或运行：

```powershell
. $PROFILE
```

## 故障排除

### winget 不可用

如果系统提示 winget 不可用，请从 [Microsoft Store](https://apps.microsoft.com/store/detail/windows-package-manager/9MMS1HRRNGKG) 安装。

### 权限错误

某些操作需要管理员权限。右键点击 PowerShell，选择"以管理员身份运行"。

### Neovim 插件安装失败

首次启动 Neovim 时，插件会自动安装。如果失败，请手动运行：

```vim
:Lazy sync
```

## 配置自定义

### PowerShell Profile

编辑 `$PROFILE.CurrentUserCurrentHost`（通常在 `~\Documents\PowerShell\Microsoft.PowerShell_profile.ps1`）

### Windows Terminal

配置文件位于：`$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json`

### Neovim

配置文件位于：`~\App\Local\nvim\init.lua`

## 常见问题

**Q: 需要使用 WSL 吗？**

A: 不需要。本脚本为 Windows 原生环境设计。如果你更喜欢 Linux 环境，可以在 WSL 中运行 `install.sh`。

**Q: 如何卸载？**

A: 运行 `.\uninstall.ps1` 或手动删除已安装的工具和配置。

**Q: 能与现有配置共存吗？**

A: 可以。脚本会自动备份现有配置文件。

## 下一步

- 配置 Git 用户信息
- 安装项目特定的开发工具
- 探索 [PowerShell 文档](https://docs.microsoft.com/powershell/)
```

**Step 3: 提交文档更新**

```bash
git add README.md docs/windows-installation-guide.md
git commit -m "docs: 添加 Windows 安装文档

- 在 README 中添加 Windows 安装说明
- 创建详细的 Windows 安装指南
- 添加故障排除和常见问题"
```

---

## Task 11: 测试和验证

**Files:**
- N/A (测试)

**Step 1: 语法检查**

```bash
pwsh -NoProfile -Command "Get-Command -Syntax Install-PSModules"
```

预期：无语法错误

**Step 2: DRY_RUN 模式测试**

```powershell
.\install.ps1 -DryRun
```

预期：显示将要执行的操作，但不实际安装

**Step 3: 参数测试**

```powershell
# 测试 SkipTools 参数
.\install.ps1 -SkipTools

# 测试 OnlyDotfile 参数
.\install.ps1 -OnlyDotfile
```

预期：跳过工具安装，只部署 dotfile

**Step 4: 部分功能测试**

在已有工具的系统上测试：

```powershell
# 只测试环境检测
pwsh -NoProfile -Command ". .\install.ps1; Test-PowerShellVersion"

# 测试 Profile 部署（不安装工具）
.\install.ps1 -SkipTools
```

**Step 5: 创建测试清单文档**

创建文件 `docs/windows-testing-checklist.md`:

```markdown
# Windows 安装脚本测试清单

## 环境检测测试

- [ ] PowerShell 版本检测（< 7.0 应报错）
- [ ] winget 可用性检测
- [ ] 管理员权限检测
- [ ] 已安装工具检测

## 工具安装测试

- [ ] Windows Terminal 安装
- [ ] PowerShell 7 安装
- [ ] Git 安装
- [ ] Node.js 安装
- [ ] Neovim 安装

## PowerShell 模块测试

- [ ] Oh-My-Posh 安装
- [ ] PSReadLine 安装
- [ ] Terminal-Icons 安装
- [ ] zoxide 安装
- [ ] PSFzf 安装（可选）

## dotfile 部署测试

- [ ] dotfile 仓库克隆
- [ ] 配置文件备份
- [ ] PowerShell Profile 部署
- [ ] Windows Terminal 配置部署
- [ ] dot alias 添加

## 验证测试

- [ ] 所有工具验证通过
- [ ] 版本信息显示正确
- [ ] 后续步骤指引显示

## 参数测试

- [ ] -DryRun 参数工作正常
- [ ] -SkipTools 参数工作正常
- [ ] -OnlyDotfile 参数工作正常

## 集成测试

- [ ] 全新 Windows 11 系统完整安装
- [ ] 部分工具已存在的系统
- [ ] 非 PowerShell 7 环境的错误处理
- [ ] 无网络环境的错误处理
```

**Step 6: 提交测试文档**

```bash
git add docs/windows-testing-checklist.md
git commit -m "test: 添加 Windows 安装脚本测试清单

- 创建详细的测试清单文档
- 覆盖所有功能测试点
- 包含集成测试场景"
```

---

## Task 12: 最终检查和发布准备

**Files:**
- Modify: `install.ps1` (如需调整)
- Create: `CHANGELOG.md` (如不存在)

**Step 1: 添加脚本注释和文档**

确保 `install.ps1` 有完整的帮助文档：

```powershell
<#
.SYNOPSIS
    Windows 开发环境自动安装脚本

.DESCRIPTION
    自动安装和配置 Windows 开发工具，包括：
    - Windows Terminal, PowerShell 7
    - Git, Node.js, Neovim
    - Oh-My-Posh, PSReadLine 等增强工具
    - dotfile 自动部署

.PARAMETER SkipTools
    跳过工具安装，只部署 dotfile

.PARAMETER OnlyDotfile
    只部署 dotfile，不安装任何工具

.PARAMETER DryRun
    预演模式，只显示将要执行的操作

.EXAMPLE
    .\install.ps1
    完整安装所有工具和配置

.EXAMPLE
    .\install.ps1 -DryRun
    预览将要执行的操作

.EXAMPLE
    .\install.ps1 -SkipTools
    只部署 dotfile，不安装工具

.NOTES
    Version: 1.0.0
    Author: Claude Sonnet + User
    Requires: PowerShell 7.0+
#>
```

**Step 2: 创建 CHANGELOG 条目**

如果 `CHANGELOG.md` 不存在，创建它：

```markdown
# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Windows PowerShell 安装脚本 (install.ps1)
- Windows Terminal 配置支持
- PowerShell 7 + Oh-My-Posh 配置
- dotfile Windows 支持

### Changed
- 增强 install.sh 的 Neovim 安装（从 GitHub 下载最新版本）
- 添加 GLIBC 检测和源码编译回退

### Fixed
- 修复代码审查发现的 6 个关键问题
- 修复版本比较函数边界情况
- 修复 GitHub API 调用缺少超时

## [1.0.0] - 2026-03-03

### Added
- 初始版本
- Linux/macOS 自动安装脚本 (install.sh)
- zsh + oh-my-zsh 配置
- tmux + TPM 配置
- Neovim + LazyVim 配置
```

**Step 3: 完整性检查**

运行以下检查：

```bash
# PowerShell 语法检查
pwsh -NoProfile -File install.ps1 -DryRun

# 文件结构检查
git ls-files

# 文档完整性检查
ls -la docs/plans/
ls -la .config/powershell/
ls -la .config/windows-terminal/
```

**Step 4: 提交最终版本**

```bash
git add install.ps1 CHANGELOG.md
git commit -m "release: 完成 Windows PowerShell 安装脚本 v1.0.0

功能完整：
- ✅ 环境检测（PowerShell, winget, 管理员权限）
- ✅ 工具安装（Git, Node.js, Neovim）
- ✅ PowerShell 增强（Oh-My-Posh, PSReadLine 等）
- ✅ dotfile 自动部署
- ✅ Windows Terminal 配置
- ✅ 完整文档和测试清单

变更日志：
- 添加 CHANGELOG.md
- 完成所有实现任务
- 准备发布"
```

**Step 5: 创建版本标签**

```bash
git tag -a v1.0.0 -m "Windows PowerShell 安装脚本 v1.0.0

完整支持 Windows 10/11 开发环境自动配置"
git push origin v1.0.0
```

---

## 实施说明

### 前置条件
- Windows 10/11 系统
- PowerShell 7.0+ (脚本会引导安装)
- Git 客户端
- 管理员权限（推荐）

### 开发环境
- Windows Terminal
- PowerShell 7
- VS Code (可选，用于编辑)

### 测试策略
- 每个 Task 独立测试
- 使用 `-DryRun` 参数进行预演
- 在虚拟机中测试完整安装
- 验证所有工具和配置

### 提交策略
- 每个 Task 完成后立即提交
- 使用语义化提交消息
- 频繁提交，小步快跑

### 回滚计划
如果某个 Task 失败：
```bash
git reset --hard HEAD~1
# 检查问题，修复后继续
```

---

**总计 12 个任务，预计完成时间：2-4 小时**
