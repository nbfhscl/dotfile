# PowerShell 脚本使用指南

## 📁 脚本结构

```
D:\develop\dotfile\
├── install.ps1                    # 主安装脚本（支持卸载）
├── scripts/
│   ├── Install-Tools.ps1         # 仅安装工具
│   ├── Deploy-Dotfiles.ps1       # 仅部署配置
│   ├── Verify-Configuration.ps1  # 验证配置
│   ├── Update-Dotfiles.ps1       # 更新配置
│   ├── Show-DotfileStatus.ps1    # 显示状态
│   ├── Uninstall-Dotfile.ps1    # 完整卸载
│   └── Quick-Uninstall.ps1      # 快速卸载
└── .config/powershell/
    └── modules/                  # 模块化代码
        ├── UI.psm1              # 用户界面
        ├── ToolInstaller.psm1    # 工具安装
        ├── ConfigDeployer.psm1  # 配置部署
        ├── Verifier.psm1        # 验证功能
        └── DotfileInstaller.psm1 # dotfile管理
```

## 🚀 主安装脚本使用方法

### 安装模式

```powershell
# 1. 一键完整安装（推荐）
.\install.ps1

# 2. 只安装 dotfile（工具已存在）
.\install.ps1 -OnlyDotfile

# 3. 只安装工具（不部署配置）
.\install.ps1 -SkipTools

# 4. 模拟运行（不实际执行）
.\install.ps1 -DryRun
```

### 卸载模式

```powershell
# 1. 快速卸载（仅移除配置，保留工具）
.\install.ps1 -Uninstall

# 2. 完整卸载（所有选项）
.\install.ps1 -Uninstall -Quiet -RemoveBackups

# 3. 自定义卸载
.\install.ps1 -Uninstall -KeepProfile -KeepVimConfig
```

## 🛠️ 独立脚本使用

### 工具安装
```powershell
# 安装开发工具
.\scripts\Install-Tools.ps1
```

### 配置部署
```powershell
# 部置 dotfile 配置
.\scripts\Deploy-Dotfiles.ps1
```

### 验证配置
```powershell
# 验证所有配置是否正确
.\scripts\Verify-Configuration.ps1

# 带 详细输出
.\scripts\Verify-Configuration.ps1 -Verbose
```

### 更新配置
```powershell
# 从仓库更新并重新部署
.\scripts\Update-Dotfiles.ps1
```

### 状态查看
```powershell
# 查看 dotfile 仓库状态
.\scripts\Show-DotfileStatus.ps1
```

### 卸载功能

#### 快速卸载（推荐）
```powershell
# 移除配置但保留工具
.\scripts\Quick-Uninstall.ps1

# 静默模式
.\scripts\Quick-Uninstall.ps1 -Quiet -RemoveBackups
```

#### 完整卸载
```powershell
# 完全卸载所有内容
.\scripts\Uninstall-Dotfile.ps1

# 自定义选项
.\scripts\Uninstall-Dotfile.ps1 -RemoveBackups -KeepProfile -Quiet
```

## ⚙️ 参数说明

### 主安装脚本参数

| 参数 | 说明 | 示例 |
|------|------|------|
| `-SkipTools` | 跳过工具安装，只部署配置 | `.\install.ps1 -SkipTools` |
| `-OnlyDotfile` | 只部署配置，不安装工具 | `.\install.ps1 -OnlyDotfile` |
| `-DryRun` | 模拟运行，不实际执行 | `.\install.ps1 -DryRun` |
| `-Uninstall` | 卸载模式 | `.\install.ps1 -Uninstall` |

### 卸载脚本参数

| 参数 | 说明 | 示例 |
|------|------|------|
| `-Quiet` | 静默模式，不显示确认提示 | `.\Uninstall-Dotfile.ps1 -Quiet` |
| `-RemoveBackups` | 删除备份文件 | `.\Uninstall-Dotfile.ps1 -RemoveBackups` |
| `-KeepProfile` | 保留 PowerShell 配置文件 | `.\Uninstall-Dotfile.ps1 -KeepProfile` |
| `-KeepTerminalSettings` | 保留 Windows Terminal 设置 | `.\Uninstall-Dotfile.ps1 -KeepTerminalSettings` |
| `-KeepVimConfig` | 保留 Vim/Neovim 配置 | `.\Uninstall-Dotfile.ps1 -KeepVimConfig` |

## 🔧 使用场景

### 场景1：全新安装
```powershell
# 第一次使用 dotfile
.\install.ps1
```

### 场景2：更新 dotfile
```powershell
# 更新已有配置
.\scripts\Update-Dotfiles.ps1
```

### 场景3：迁移环境
```powershell
# 在新电脑上重新部署
.\install.ps1 -OnlyDotfile
```

### 场景4：调试问题
```powershell
# 验证配置是否正确
.\scripts\Verify-Configuration.ps1

# 查看状态
.\scripts\Show-DotfileStatus.ps1
```

### 场景5：清理配置
```powershell
# 移除 dotfile 但保留工具
.\install.ps1 -Uninstall

# 或使用独立脚本
.\scripts\Quick-Uninstall.ps1
```

## 🎯 最佳实践

### 1. 安装流程
```powershell
# 1. 首次安装
.\install.ps1

# 2. 后续更新
.\scripts\Update-Dotfiles.ps1

# 3. 偶尔验证
.\scripts\Verify-Configuration.ps1
```

### 2. 卸载流程
```powershell
# 1. 备份重要配置
Copy-Item $env:USERPROFILE\.vimrc $env:USERPROFILE\vimrc_backup.txt

# 2. 执行卸载
.\install.ps1 -Uninstall

# 3. 验证清理
Test-Path $env:USERPROFILE\.vimrc  # 应该返回 False
```

### 3. 问题排查
```powershell
# 1. 检查状态
.\scripts\Show-DotfileStatus.ps1

# 2. 验证配置
.\scripts\Verify-Configuration.ps1

# 3. 查看 log
Get-Content "$env:TEMP\dotfile_install_*.log"
```

## 💡 提示

1. **管理员权限**：某些工具安装需要管理员权限，请以管理员身份运行 PowerShell

2. **网络连接**：下载工具需要稳定的网络连接

3. **备份重要配置**：卸载前请备份重要配置文件

4. **重启 PowerShell**：某些更改需要重启 PowerShell 才能生效

5. **查看日志**：所有操作都会生成日志文件，位于 `$env:TEMP\` 目录下

## 📞 获取帮助

每个脚本都内联帮助文档：

```powershell
# 查看帮助
Get-Help .\install.ps1 -Full

# 或使用 -? 参数
.\install.ps1 -?
```

---

*更新时间：2026-03-05*