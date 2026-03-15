# Cross-Platform Dotfile Manager

这个仓库维护一套面向 Linux、macOS、Windows 的个人 dotfile，并把安装、更新、离线部署、卸载、重装统一到两套入口脚本：

- `install.sh`：Linux / macOS
- `install.ps1`：Windows

当前推荐使用统一生命周期动作，而不是分别记忆多套历史脚本。

## 生命周期契约

| 动作 | Linux / macOS | Windows | 说明 |
|------|----------------|---------|------|
| 安装 | `bash install.sh install` | `.\install.ps1 -Action Install` | 一键安装工具与配置 |
| 仅部署 | `bash install.sh deploy` | `.\install.ps1 -Action Deploy` | 只部署 dotfile，跳过工具安装 |
| 更新 | `bash install.sh update` | `.\install.ps1 -Action Update` | 拉取最新仓库并重新部署 |
| 状态 | `bash install.sh status` | `.\install.ps1 -Action Status` | 查看 XDG 路径与仓库状态 |
| 验证 | `bash install.sh verify` | `.\install.ps1 -Action Verify` | 校验安装结果 |
| 打包 | `bash install.sh package` | `.\install.ps1 -Action Package` | 生成离线部署包 |
| 离线部署 | `bash install.sh offline-deploy <bundle>` | `.\install.ps1 -Action OfflineDeploy` | 使用已有离线包执行部署 |
| 卸载 | `bash install.sh uninstall` | `.\install.ps1 -Action Uninstall` | 手动卸载已部署配置 |
| 重装 | `bash install.sh reinstall` | `.\install.ps1 -Action Reinstall` | 卸载后重新安装 |

## XDG 路径策略

三平台都按统一语义使用 XDG 目录，默认值如下：

| 语义 | Unix 默认值 | Windows 默认值 |
|------|-------------|----------------|
| 配置 | `$HOME/.config` | `%USERPROFILE%\.config` |
| 数据 | `$HOME/.local/share` | `%USERPROFILE%\.local\share` |
| 状态 | `$HOME/.local/state` | `%USERPROFILE%\.local\state` |
| 缓存 | `$HOME/.cache` | `%USERPROFILE%\.cache` |

对于不支持 XDG 的兼容项，仓库仍会保留必要的传统文件，例如 `.vim`、`.zprofile` 和 PowerShell bootstrap profile。

## 一键安装与自动更新

在线安装路径适合日常开发环境。安装完成后，通过 `update` 动作执行自动更新。

### Linux / macOS

```bash
bash install.sh install
bash install.sh deploy
bash install.sh update
bash install.sh status
bash install.sh verify
```

### Windows

```powershell
.\install.ps1 -Action Install
.\install.ps1 -Action Deploy
.\install.ps1 -Action Update
.\install.ps1 -Action Status
.\install.ps1 -Action Verify
```

Windows 兼容模式仍然保留：

```powershell
.\install.ps1
.\install.ps1 -SkipTools
.\install.ps1 -OnlyDotfile
.\install.ps1 -DryRun
.\install.ps1 -Uninstall
```

如果你直接从远程执行 Windows 一键安装，入口仍然是：

```powershell
irm https://raw.githubusercontent.com/nbfhscl/dotfile/refs/heads/master/install.ps1 | iex
```

## 离线打包与离线部署

### Linux / macOS

`install.sh package` 现在明确表示“生成离线包”，底层调用 `scripts/offline-export.sh`。

```bash
# 生成离线包
bash install.sh package

# 非交互批量打包
AUTO_YES=1 bash scripts/offline-export.sh

# 预览打包动作
DRY_RUN=1 bash install.sh package

# 在目标机器上使用离线包
bash install.sh offline-deploy ./scripts/dist/dotfiles-offline-<version>.sh
```

### Windows

```powershell
.\install.ps1 -Action Package
.\install.ps1 -Action Package -Compress
.\install.ps1 -Action OfflineDeploy
```

Windows 离线包会把安装脚本、PowerShell 模块、工具安装器和当前配置快照一起打包，并在包内生成 `scripts\offline-install.ps1`。

## 卸载与重装

两个入口都支持手动卸载和重装：

```bash
bash install.sh uninstall
bash install.sh reinstall
```

```powershell
.\install.ps1 -Action Uninstall
.\install.ps1 -Action Reinstall
```

Windows 兼容模式仍保留 `-Uninstall` 开关；Unix 端可通过 `NO_BACKUP=1` 控制是否跳过卸载前备份。

## 预览与非交互模式

### Linux / macOS

```bash
DRY_RUN=1 bash install.sh install
DRY_RUN=1 bash install.sh reinstall
DRY_RUN=1 bash install.sh package
AUTO_YES=1 bash scripts/offline-export.sh
```

### Windows

```powershell
.\install.ps1 -DryRun
.\install.ps1 -Action Package -IncludeDocumentation
.\install.ps1 -Action Uninstall -Quiet -RemoveBackups
```

## 目录结构

```text
.
├── install.sh
├── install.ps1
├── .config/
├── .vim/
├── scripts/
│   ├── lib/
│   ├── export.sh
│   ├── collect.sh
│   ├── package.sh
│   ├── offline-collect.sh
│   ├── offline-package.sh
│   └── offline-export.sh
├── tests/
│   └── install_contract.bats
└── docs/
```

## 旧脚本状态

- `scripts/export.sh` 仍保留，但属于 legacy 在线导出路径，不再代表 Unix 主入口的 `package` 动作。
- `scripts/offline-export.sh` 是 Unix 离线打包的底层脚本，推荐通过 `bash install.sh package` 调用。
- Windows 推荐入口只有 `install.ps1`；不要再把旧的分散包装脚本当作主流程文档。

## 验证

仓库提供基础契约测试，重点防止安装动作、帮助文本和 XDG 约定回退：

```bash
bats tests/install_contract.bats
bash -n install.sh
bash -n scripts/offline-export.sh
```
