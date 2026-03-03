# Windows PowerShell 安装脚本设计文档

**日期:** 2026-03-03
**作者:** Claude Sonnet + User
**状态:** 已批准

## 概述

创建一个 Windows PowerShell 安装脚本 (`install.ps1`)，为 Windows 开发者提供自动化的开发环境配置，功能与 Linux/macOS 的 `install.sh` 等效，但使用 Windows 原生工具和工作流。

## 目标用户

- Windows 10/11 桌面开发者
- 需要完整的开发工具链
- 希望使用 Windows 原生工具而非 WSL
- 追求自动化和可重复的环境配置

## 核心设计原则

1. **Windows 原生优先**: 使用 Windows Terminal、PowerShell 7、winget
2. **最小惊讶**: 与 install.sh 保持相同的功能结构
3. **渐进式增强**: 支持可选的 WSL 集成
4. **错误恢复**: 完善的错误处理和回滚机制
5. **用户友好**: 清晰的进度提示和后续步骤指引

## 功能规格

### 1. 核心开发工具

| 工具 | Winget 包 ID | 用途 | 必需 |
|------|--------------|------|------|
| Git | `Git.Git` | 版本控制 | ✅ |
| Node.js & npm | `OpenJS.NodeJS.LTS` | JavaScript 运行时 | ✅ |
| Neovim | `Neovim.Neovim` | 编辑器 | ✅ |
| Python | `Python.Python.3.12` | Python 运行时 | ⚙️ 可选 |

### 2. Windows 终端增强

| 组件 | 替代 Linux 工具 | 安装方式 | 必需 |
|------|-----------------|----------|------|
| Windows Terminal | tmux + 终端模拟器 | winget 或 Microsoft Store | ✅ |
| PowerShell 7 | zsh | winget | ✅ |
| Oh-My-Posh | oh-my-zsh 主题 | PowerShell Gallery | ✅ |
| PSReadLine | zsh 编辑功能 | PowerShell Gallery | ✅ |
| Terminal-Icons | LS 颜色/图标 | PowerShell Gallery | ✅ |
| zoxide | zoxide (同工具) | winget/scoop | ✅ |
| PSFzf | fzf | PowerShell Gallery | ⚙️ 可选 |

### 3. dotfile 管理

- 使用相同的 git bare repository 策略
- 路径适配：`$HOME` → `$env:USERPROFILE`
- 支持 PowerShell Profile 和 Neovim 配置

### 4. 可选功能

- WSL 检测和安装提示
- Windows Terminal 主题配置
- 字体安装 (Nerd Fonts)

## 技术架构

### 文件结构

```
dotfile/
├── install.ps1                    # 主安装脚本
├── docs/
│   └── plans/
│       └── 2026-03-03-windows-powershell-installer-design.md
├── .config/
│   ├── powershell/
│   │   └── profile.ps1            # PowerShell Profile
│   ├── windows-terminal/
│   │   └── settings.json          # Windows Terminal 配置
│   └── nvim/
│       └── init.lua               # Neovim 配置（跨平台共享）
└── README.md                      # 添加 Windows 安装说明
```

### 脚本流程

```
┌─────────────────────────────────────────────┐
│  1. 环境检测与前置检查                       │
│  ├─ PowerShell 版本 (≥ 7.0)                 │
│  ├─ winget 可用性                           │
│  ├─ 管理员权限                              │
│  └─ 已安装工具检测                          │
└─────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────┐
│  2. 安装 Windows Terminal 和 PowerShell 7   │
│  ├─ Windows Terminal (winget)               │
│  ├─ PowerShell 7 (winget)                   │
│  └─ 验证安装                                │
└─────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────┐
│  3. 安装核心开发工具                         │
│  ├─ Git                                     │
│  ├─ Node.js & npm                           │
│  ├─ Neovim                                  │
│  └─ Python (可选)                           │
└─────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────┐
│  4. 配置 PowerShell 7                       │
│  ├─ Oh-My-Posh 主题引擎                     │
│  ├─ PSReadLine 命令行编辑                   │
│  ├─ Terminal-Icons 图标                     │
│  ├─ zoxide 目录跳转                         │
│  └─ PSFzf 模糊搜索 (可选)                   │
└─────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────┐
│  5. 配置 Windows Terminal                    │
│  ├─ 导入 settings.json                      │
│  ├─ 配置配色方案                            │
│  ├─ 添加 PowerShell 7 配置文件              │
│  └─ 添加 WSL 配置文件 (如果检测到)          │
└─────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────┐
│  6. 部署 dotfile                            │
│  ├─ 克隆/更新 dotfile 仓库                  │
│  ├─ 备份现有配置文件                        │
│  ├─ 部署 PowerShell Profile                 │
│  ├─ 部署 Neovim 配置                        │
│  └─ 配置 dot alias                          │
└─────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────┐
│  7. 验证和后续步骤                           │
│  ├─ 验证所有工具安装                         │
│  ├─ 显示版本信息                            │
│  ├─ 运行 Neovim 插件安装                    │
│  └─ 提供后续步骤指引                        │
└─────────────────────────────────────────────┘
```

### 错误处理策略

```powershell
# 关键错误处理点
1. 网络下载失败 → 重试 3 次，提供手动下载链接
2. winget 失败 → 记录错误，继续安装其他工具
3. 权限不足 → 提示以管理员运行，优雅退出
4. 版本不兼容 → 提供升级指引
5. 配置文件冲突 → 自动备份，提示用户
```

## 配置文件示例

### PowerShell Profile

**路径:** `$PROFILE.CurrentUserCurrentHost` (通常在 `~\Documents\PowerShell\Microsoft.PowerShell_profile.ps1`)

```powershell
# ============================================
# PowerShell 7 配置
# ============================================

# Oh-My-Posh 主题引擎
$env:POSH_THEMES_PATH = "$env:USERPROFILE\.poshthemes"
oh-my-posh init pwsh --config "$env:POSH_THEMES_PATH\paradox.omp.json" | Invoke-Expression

# PSReadLine - 命令行编辑增强
Import-Module PSReadLine
Set-PSReadLineOption -PredictionSource History
Set-PSReadLineOption -PredictionViewStyle ListView
Set-PSReadLineKeyHandler -Key "Tab" -Function MenuComplete

# Terminal-Icons - 文件/文件夹图标
Import-Module Terminal-Icons

# zoxide - 智能目录跳转
Invoke-Expression (& { (zoxide init powershell | Out-String) })

# fzf - 模糊搜索 (可选)
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
```

### Windows Terminal 配置

**路径:** `$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json`

```json
{
  "profiles": {
    "defaults": {
      "fontFace": "Cascadia Code",
      "fontSize": 11,
      "colorScheme": "One Dark Pro"
    },
    "list": [
      {
        "guid": "{574e775e-4f2a-5b96-ac1e-a2962a402336}",
        "name": "PowerShell 7",
        "commandline": "pwsh.exe",
        "hidden": false
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
      "white": "#abb2bf"
    }
  ]
}
```

## 实现细节

### 主函数结构

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

.EXAMPLE
    .\install.ps1

.EXAMPLE
    .\install.ps1 -SkipTools -OnlyDotfile
#>
param(
    [switch]$SkipTools = $false,
    [switch]$OnlyDotfile = $false,
    [switch]$DryRun = $false
)

# 辅助函数
function Write-Info { ... }
function Write-Success { ... }
function Write-Warning { ... }
function Write-Error { ... }

# 环境检测
function Test-PowerShellVersion { ... }
function Test-WingetAvailable { ... }
function Test-Administrator { ... }

# 工具安装
function Install-WindowsTerminal { ... }
function Install-PowerShell7 { ... }
function Install-Tool { ... }

# PowerShell 配置
function Install-OhMyPosh { ... }
function Install-PSModules { ... }
function Copy-PowerShellProfile { ... }

# Windows Terminal 配置
function Copy-TerminalSettings { ... }

# dotfile 管理
function Deploy-Dotfile { ... }

# 主流程
function Install-AllTools { ... }
function Invoke-Verification { ... }

# 入口点
main
```

### 包管理器抽象

```powershell
function Install-Package {
    param(
        [string]$PackageName,
        [string]$WingetId,
        [switch]$Required = $true
    )

    if (Get-Command $PackageName -ErrorAction SilentlyContinue) {
        Write-Success "$PackageName 已安装"
        return
    }

    Write-Info "正在安装 $PackageName..."

    if (Get-Command winget -ErrorAction SilentlyContinue) {
        $result = & winget install --id $WingetId --accept-source-agreements --accept-package-agreements -e 2>&1

        if ($LASTEXITCODE -eq 0) {
            Write-Success "$PackageName 安装完成"
        } else {
            if ($Required) {
                Write-Error "$PackageName 安装失败"
                # 提供手动安装链接
            } else {
                Write-Warning "$PackageName 安装失败（可选工具）"
            }
        }
    } else {
        Write-Error "winget 不可用，无法安装 $PackageName"
    }
}
```

### 优雅降级

```powershell
# 如果 winget 不可用，提供手动下载链接
$ManualInstallLinks = @{
    "Git" = "https://git-scm.com/download/win"
    "Node.js" = "https://nodejs.org/"
    "Neovim" = "https://github.com/neovim/neovim/releases"
}

function Show-ManualInstallHelp {
    param([string]$ToolName)

    if ($ManualInstallLinks.ContainsKey($ToolName)) {
        Write-Warning "请手动安装 $ToolName:"
        Write-Info "下载地址: $($ManualInstallLinks[$ToolName])"
    }
}
```

## 测试计划

### 单元测试
- PowerShell 版本检测
- winget 可用性检测
- 包安装逻辑
- 配置文件备份

### 集成测试
- 全新 Windows 10/11 系统
- 已有部分工具的系统
- 非管理员权限场景

### 验收标准
- ✅ 所有核心工具安装成功
- ✅ PowerShell Profile 正确配置
- ✅ Windows Terminal 配置生效
- ✅ dotfile 正确部署
- ✅ 错误处理不中断脚本
- ✅ 提供清晰的后续步骤指引

## 已知限制

1. **操作系统**: 仅支持 Windows 10 1903+ 和 Windows 11
2. **PowerShell**: 需要 PowerShell 7.0+ (脚本会自动安装)
3. **网络**: 需要稳定的互联网连接
4. **权限**: 某些操作需要管理员权限
5. **WSL**: WSL 集成为可选功能，需要手动配置

## 后续增强

- [ ] 支持 Chocolatey 作为备选包管理器
- [ ] 添加交互式配置选项
- [ ] 支持自定义配置文件
- [ ] 添加卸载脚本
- [ ] 集成 WSL 自动安装和配置
- [ ] 添加开发环境预设（前端、后端、Go 等）

## 参考资料

- [Windows Terminal 文档](https://docs.microsoft.com/windows-terminal/)
- [Oh-My-Posh 文档](https://ohmyposh.dev/)
- [PowerShell Gallery](https://www.powershellgallery.com/)
- [winget 文档](https://docs.microsoft.com/windows/package-manager/)

## 变更历史

| 日期 | 版本 | 作者 | 变更说明 |
|------|------|------|----------|
| 2026-03-03 | 1.0 | Claude + User | 初始设计 |
