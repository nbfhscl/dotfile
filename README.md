# Cross-Platform Dotfile Manager

跨平台 dotfile 管理，统一安装、更新、离线部署。

## 快速开始

### 在线安装（日常开发机）

**Linux / macOS**
```bash
bash install.sh install    # 一键安装
bash install.sh update     # 更新配置
```

**Windows**
```powershell
.\install.ps1 -Action Install
.\install.ps1 -Action Update
```

或远程一键安装：
```powershell
irm https://raw.githubusercontent.com/nbfhscl/dotfile/refs/heads/master/install.ps1 | iex
```

### 离线部署（隔离环境/灾备）

**生成离线包**
```bash
bash install.sh package
# 产物：scripts/dist/dotfiles-offline-<version>.sh
```

**目标机器部署**
```bash
bash install.sh offline-deploy ./scripts/dist/dotfiles-offline-<version>.sh
```

## 生命周期动作

| 动作 | Linux / macOS | Windows | 说明 |
|------|--------------|---------|------|
| 安装 | `install` | `Install` | 工具 + 配置 |
| 仅部署 | `deploy` | `Deploy` | 仅配置 |
| 更新 | `update` | `Update` | 拉取 + 重部署 |
| 状态 | `status` | `Status` | 查看路径与状态 |
| 验证 | `verify` | `Verify` | 校验安装结果 |
| 打包 | `package` | `Package` | 生成离线包 |
| 离线部署 | `offline-deploy <bundle>` | `OfflineDeploy` | 使用离线包 |
| 卸载 | `uninstall` | `Uninstall` | 卸载配置 |
| 重装 | `reinstall` | `Reinstall` | 卸载后重装 |

## XDG 路径

三平台统一使用 XDG 语义：

| 语义 | Unix | Windows |
|------|------|---------|
| 配置 | `$HOME/.config` | `%USERPROFILE%\.config` |
| 数据 | `$HOME/.local/share` | `%USERPROFILE%\.local\share` |
| 状态 | `$HOME/.local/state` | `%USERPROFILE%\.local\state` |
| 缓存 | `$HOME/.cache` | `%USERPROFILE%\.cache` |

## 高级用法

### 预览模式

```bash
DRY_RUN=1 bash install.sh install
```

```powershell
.\install.ps1 -DryRun
```

### 非交互模式

```bash
AUTO_YES=1 bash install.sh package
```

## 目录结构

```
.
├── install.sh           # Unix 主入口
├── install.ps1          # Windows 主入口
├── scripts/
│   ├── lib/             # 共享库
│   ├── offline-collect.sh
│   ├── offline-package.sh
│   └── offline-export.sh
├── .config/             # XDG 配置
├── .vim/                # 兼容项
└── tests/               # 契约测试
```

## 详细文档

- [Scripts 说明](scripts/README.md) - Unix 辅助脚本与离线打包流程
- [Docker 测试说明](docs/DOCKER-TEST-CLARIFICATION.md) - E2E 测试范围与结果说明
- [工具测试说明](docs/TOOLS-TESTING.md) - 安装后工具验证说明

## 验证

```bash
bats tests/install_contract.bats
```
