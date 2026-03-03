# Dotfile 仓库

个人开发环境的配置文件仓库，支持 Linux/macOS 和 Windows 10/11。

## Linux/macOS 安装

使用 Bash 安装脚本：

```bash
# 方式 1: 直接运行
./install.sh

# 方式 2: 预览模式
./install.sh --dry-run

# 方式 3: 只部署 dotfile
./install.sh --only-dotfile
```

## Windows 安装

在 Windows 10/11 上使用 PowerShell 安装：

```powershell
# 方式 1: 直接运行
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
.\install.ps1

# 方式 2: 预览模式
.\install.ps1 -DryRun

# 方式 3: 只部署 dotfile
.\install.ps1 -OnlyDotfile
```

### 前置要求
- Windows 10 1903+ 或 Windows 11
- PowerShell 7.0+
- Windows Package Manager (winget)

### WSL 用户
如果你更喜欢使用 WSL，可以直接运行 `install.sh`。

详细文档：[Windows 安装指南](docs/windows-installation-guide.md)