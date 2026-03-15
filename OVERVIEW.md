# Dotfile 安装体系概览

这份概览描述当前仓库采用的统一安装架构，而不是历史上的多套分散脚本体系。

## 当前架构

### 平台入口

- Linux / macOS：`install.sh`
- Windows：`install.ps1`

### 统一动作

| 动作 | 含义 |
|------|------|
| `install` | 安装工具并部署 dotfile |
| `deploy` | 只部署配置，不安装工具 |
| `update` | 更新仓库并重新部署 |
| `status` | 输出运行时状态、XDG 路径和仓库状态 |
| `verify` | 校验关键配置是否已就位 |
| `package` | 生成离线部署包 |
| `offline-deploy` | 用离线包执行安装 |
| `uninstall` | 卸载已部署配置 |
| `reinstall` | 卸载后重新安装 |

## XDG 设计

仓库现在统一使用 XDG 语义来表达三平台的部署目标：

| 目录语义 | Unix | Windows |
|----------|------|---------|
| 配置 | `$HOME/.config` | `%USERPROFILE%\.config` |
| 数据 | `$HOME/.local/share` | `%USERPROFILE%\.local\share` |
| 状态 | `$HOME/.local/state` | `%USERPROFILE%\.local\state` |
| 缓存 | `$HOME/.cache` | `%USERPROFILE%\.cache` |

这意味着无论入口脚本运行在哪个平台，配置定位方式都是一致的；不同之处只体现在平台原生工具安装和兼容文件处理上。

## 安装模式

### 在线一键安装

用于联网环境，特点是：

- 通过主入口脚本直接完成安装
- 后续可通过 `update` 动作执行自动更新
- 支持 `status` 和 `verify` 做安装后检查
- 支持 `uninstall` 和 `reinstall` 做人工恢复

示例：

```bash
bash install.sh install
bash install.sh update
```

```powershell
.\install.ps1 -Action Install
.\install.ps1 -Action Update
```

### 离线打包与离线部署

用于隔离环境，特点是：

- 在线机器先构建离线包
- 离线机器只消费离线包，不访问网络
- 离线部署同样保留卸载和重装动作

示例：

```bash
bash install.sh package
bash install.sh offline-deploy ./scripts/dist/dotfiles-offline-<version>.sh
```

```powershell
.\install.ps1 -Action Package
.\install.ps1 -Action OfflineDeploy
```

## 关键实现分层

### Unix 侧

- `install.sh`：面向用户的统一入口
- `scripts/lib/actions.sh`：生命周期动作定义
- `scripts/lib/xdg.sh`：XDG 默认值与路径工具
- `scripts/offline-export.sh`：离线打包总控脚本
- `scripts/offline-collect.sh`：收集本地依赖
- `scripts/offline-package.sh`：生成自解压离线安装包

### Windows 侧

- `install.ps1`：面向用户的统一入口
- `.config/powershell/modules/Common.psm1`：共享工具函数
- `.config/powershell/modules/Config.psm1`：XDG 路径和配置
- `.config/powershell/modules/ConfigDeployer.psm1`：配置部署逻辑
- `.config/powershell/modules/DotfileInstaller.psm1`：dot 仓库初始化和更新逻辑

## 当前推荐路径

- 日常联网安装：直接使用 `install.sh` / `install.ps1`
- 日常更新：直接使用 `update`
- 离线场景：通过 `package` 生成离线包，再执行 `offline-deploy`
- 验证问题：先用 `status` 和 `verify`
- 清理恢复：用 `uninstall` 和 `reinstall`

## 历史脚本说明

- `scripts/export.sh` 仍存在，但只作为 legacy 在线导出能力保留。
- Unix 主入口的 `package` 动作现在明确绑定到 `scripts/offline-export.sh`。
- Windows 文档不再把旧的分散包装脚本视为主路径，应统一回到 `install.ps1`。
