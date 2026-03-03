# Windows 安装指南

## 系统要求
- Windows 10 1903+ 或 Windows 11
- PowerShell 7.0+
- winget
- 管理员权限
- 互联网连接

## 安装步骤

### 1. 安装前置组件
```powershell
winget install Microsoft.PowerShell
```

### 2. 克隆仓库
```powershell
git clone https://github.com/nbfhscl/dotfile.git
cd dotfile
```

### 3. 运行安装脚本
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
.\install.ps1
```

### 4. 重启 PowerShell
```powershell
. $PROFILE
```

## 故障排除

### winget 不可用
从 Microsoft Store 安装 Windows Package Manager。

### 权限错误
右键 PowerShell，选择"以管理员身份运行"。

### Neovim 插件安装失败
手动运行：`:Lazy sync`

## 配置自定义

### PowerShell Profile
编辑 `$PROFILE.CurrentUserCurrentHost`

### Windows Terminal
配置文件位于 Windows Terminal 设置中

## 常见问题

**Q: 需要使用 WSL 吗？**
A: 不需要。本脚本为 Windows 原生环境设计。

**Q: 如何卸载？**
A: 运行卸载脚本或手动删除工具和配置。

**Q: 能与现有配置共存吗？**
A: 可以。脚本会自动备份现有配置。