# Windows 开发环境一键部署

一个完整的 Windows 开发环境自动化部署和配置管理系统。

## 🚀 功能特性

- 一键安装所有开发工具（Git, Node.js, Neovim, PowerShell 等）
- 自动部署配置文件（PowerShell, Neovim, Oh-My-Posh）
- XDG Base Directory 支持，Linux 风格的配置路径
- 完整的卸载功能，可选择性清理
- 离线部署支持，内网机器工具分发

## 📁 目录结构

```
.
├── install.ps1                    # Windows PowerShell 主安装脚本
├── install.sh                     # Linux/macOS Bash 安装脚本
├── scripts/                       # 功能脚本
│   ├── Install-Tools.ps1         # 仅安装工具
│   ├── Deploy-Dotfiles.ps1       # 仅部署配置
│   ├── Verify-Configuration.ps1  # 验证配置
│   ├── Update-Dotfiles.ps1       # 更新配置
│   ├── Show-DotfileStatus.ps1    # 显示状态
│   ├── Uninstall-Dotfile.ps1    # 完整卸载
│   ├── Quick-Uninstall.ps1      # 快速卸载
│   └── Collect-Local-Tools.ps1   # 收集本地工具（离线部署）
├── .config/powershell/           # Windows 模块化代码
│   └── modules/
│       ├── UI.psm1              # 用户界面
│       ├── ToolInstaller.psm1    # 工具安装
│       ├── ConfigDeployer.psm1  # 配置部署
│       ├── Verifier.psm1        # 验证功能
│       └── DotfileInstaller.psm1 # dotfile 管理
└── README.md                     # 说明文档
```

## 🚀 安装方式

### Windows PowerShell 安装

```powershell
# 方式 1: 直接从 GitHub 安装
irm https://raw.githubusercontent.com/nbfhscl/dotfile/refs/heads/master/install.ps1 | iex

# 方式 2: 下载后本地运行
.\install.ps1

# 方式 3: 只部署配置，不安装工具
.\install.ps1 -OnlyDotfile

# 方式 4: 模拟运行，查看将要执行的操作
.\install.ps1 -DryRun
```

### Linux/macOS Bash 安装

```bash
# 方式 1: 直接运行（安装 dotfile + 工具）
bash install.sh install

# 方式 2: 预览模式（不执行实际操作）
DRY_RUN=1 bash install.sh install

# 方式 3: 只部署 dotfile（跳过工具安装）
SKIP_INSTALL=1 bash install.sh install

# 卸载
bash install.sh uninstall
```

## 🛠️ 安装方式

### 1. 一键完整安装（推荐）

```powershell
# 直接从 GitHub 安装
irm https://raw.githubusercontent.com/nbfhscl/dotfile/refs/heads/master/install.ps1 | iex

# 或下载后本地运行
.\install.ps1
```

### 2. 自定义安装

```powershell
# 只部署配置，不安装工具
.\install.ps1 -OnlyDotfile

# 只安装工具，不部署配置
.\install.ps1 -SkipTools

# 模拟运行，查看将要执行的操作
.\install.ps1 -DryRun
```

## 🔧 工具列表

### 核心工具
- **Git** - 版本控制
- **Node.js LTS** - JavaScript 运行环境
- **Neovim** - 现代化 Vim 编辑器
- **PowerShell** - Windows PowerShell
- **Oh-My-Posh** - PowerShell 主题引擎

### 可选工具
- **Windows Terminal** - 现代终端
- **VS Code** - 代码编辑器
- **Python** - Python 解释器
- **.NET SDK 8** - .NET 开发环境
- **Docker Desktop** - 容器化平台

## 🎨 配置特性

### XDG Base Directory 支持
- Neovim 配置路径：`~/.config/nvim`
- 自动创建 XDG 环境变量
- 兼容 Linux 和 Windows

### Oh-My-Posh 主题
- 自动检测并安装主题
- 支持自定义主题文件
- 错误降级到默认主题

### PowerShell 增强
- PSReadLine 自动补全
- Terminal-Icons 文件图标
- PSFzf 模糊搜索
- 自定义 `dot` 命令管理 dotfiles

## 🔍 验证和更新

### 验证安装
```powershell
# 验证所有配置
.\scripts\Verify-Configuration.ps1

# 查看详细输出
.\scripts\Verify-Configuration.ps1 -Verbose
```

### 更新配置
```powershell
# 更新 dotfiles
.\scripts\Update-Dotfiles.ps1

# 查看状态
.\scripts\Show-DotfileStatus.ps1
```

## 🧹 卸载功能

### 快速卸载（推荐）
```powershell
# 移除配置但保留工具
.\install.ps1 -Uninstall

# 或使用独立脚本
.\scripts\Quick-Uninstall.ps1

# 静默模式并删除备份
.\scripts\Quick-Uninstall.ps1 -Quiet -RemoveBackups
```

### 完整卸载
```powershell
# 完全卸载所有内容
.\scripts\Uninstall-Dotfile.ps1

# 自定义选项
.\scripts\Uninstall-Dotfile.ps1 -RemoveBackups -KeepProfile
```

## 📦 离线部署

### 1. 从已安装系统收集工具
```powershell
# 收集所有工具
.\scripts\Collect-Local-Tools.ps1

# 收集指定工具
.\scripts\Collect-Local-Tools.ps1 -IncludeTools "Git", "NodeJS", "Neovim"

# 创建压缩包
.\scripts\Collect-Local-Tools.ps1 -Compress -PackageName "DevTools-Offline"
```

### 2. 部署到离线机器
1. 将生成的 `offline-deployment` 文件夹复制到离线机器
2. 以管理员身份运行 PowerShell
3. 执行：
```powershell
cd offline-deployment
.\Deploy-To-Offline-Machine.ps1
```

## ⚙️ 使用场景

### 场景1：全新开发环境
```powershell
# 一键安装所有内容
.\install.ps1
```

### 场景2：迁移开发环境
```powershell
# 在新电脑上只部署配置
.\install.ps1 -OnlyDotfile
```

### 场景3：更新工具配置
```powershell
# 更新 dotfiles
.\scripts\Update-Dotfiles.ps1

# 验证配置
.\scripts\Verify-Configuration.ps1
```

### 场景4：内网离线部署
```powershell
# 收集工具
.\scripts\Collect-Local-Tools.ps1 -Compress

# 在离线机器部署
.\Deploy-To-Offline-Machine.ps1
```

## 🔧 高级配置

### 环境变量
脚本会自动设置以下环境变量：
- `XDG_CONFIG_HOME` - 配置文件目录
- `XDG_DATA_HOME` - 数据文件目录
- `XDG_STATE_HOME` - 状态文件目录

### 自定义主题
Oh-My-Posh 主题文件存放在 `~/.poshthemes` 目录

### Git 配置
自动添加 `dot` 命令，用于管理 dotfiles：
```powershell
dot status      # 查看配置文件状态
dot add .vimrc  # 添加配置文件
dot push        # 提交配置更改
```

## 📋 系统要求

- Windows 10 或更高版本
- PowerShell 5.1 或更高版本
- 管理员权限（用于安装工具）
- 网络连接（首次安装时）

## 🚨 注意事项

1. **管理员权限**：某些工具安装需要管理员权限
2. **备份重要配置**：卸载前请备份重要配置文件
3. **重启 PowerShell**：某些更改需要重启 PowerShell 才能生效
4. **网络连接**：首次安装需要稳定的网络连接

## 📞 故障排除

### 常见问题

**1. PowerShell 语法错误**
```powershell
# 检查 PowerShell 版本
$PSVersionTable.PSVersion
```

**2. 工具安装失败**
```powershell
# 查看安装日志
Get-Content "$env:TEMP\dotfile_install_*.log"
```

**3. XDG 路径问题**
```powershell
# 检查 XDG 变量
echo $env:XDG_CONFIG_HOME
```

### 获取帮助

每个脚本都包含详细的帮助信息：
```powershell
# 查看主安装脚本帮助
Get-Help .\install.ps1 -Full

# 或使用 -? 参数
.\install.ps1 -?
```

---

*最后更新：2026-03-05*