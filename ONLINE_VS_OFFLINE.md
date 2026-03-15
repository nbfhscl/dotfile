# 在线安装 vs 离线部署

这份文档比较的是当前仓库支持的两种主路径：

- 在线一键安装 / 自动更新
- 离线打包 / 离线部署

注意：

- Unix 侧的正式离线入口是 `bash install.sh package`
- `scripts/export.sh` 只保留为 legacy 在线导出脚本，不再代表主流程

## 选择结论

### 选在线路径

适用于：

- 开发机或个人电脑有稳定网络
- 需要后续频繁执行更新
- 希望直接通过仓库获取最新配置
- 不想维护大体积离线包

### 选离线路径

适用于：

- 空气隔离环境
- 生产内网环境
- 无法访问软件源或外网
- 需要把本地依赖和配置一起打包

## 功能对比

| 维度 | 在线路径 | 离线路径 |
|------|----------|----------|
| 主入口 | `install.sh install` / `install.ps1 -Action Install` | `install.sh package` / `install.ps1 -Action Package` |
| 更新方式 | 直接执行 `update` | 重新打包，再把新包分发到目标机 |
| 网络要求 | 安装和更新阶段需要网络 | 目标机无需网络 |
| 打包内容 | 仓库配置 + 在线安装逻辑 | 配置快照 + 本地依赖 + 离线安装器 |
| 包体积 | 小 | 通常明显更大 |
| 恢复速度 | 取决于网络和软件源 | 取决于包传输和本地解压 |
| 适合场景 | 日常开发 | 隔离部署、灾备、内网 |

## 推荐命令

### Linux / macOS

在线安装与更新：

```bash
bash install.sh install
bash install.sh update
```

离线打包与部署：

```bash
bash install.sh package
bash install.sh offline-deploy ./scripts/dist/dotfiles-offline-<version>.sh
```

### Windows

在线安装与更新：

```powershell
.\install.ps1 -Action Install
.\install.ps1 -Action Update
```

离线打包与部署：

```powershell
.\install.ps1 -Action Package
.\install.ps1 -Action OfflineDeploy
```

## 自动更新差异

在线路径天然支持自动更新，因为入口脚本会直接把本地 dotfile 仓库更新到远端最新状态，然后重新部署。

离线路径不做“在线更新”，而是采用另一套发布节奏：

1. 在联网机器重新执行 `package`
2. 生成新的离线包
3. 把新包传到目标机器
4. 在目标机器重新执行离线部署

这意味着离线路径更像“发布制品”，在线路径更像“持续同步”。

## 卸载与重装

两条路径都支持人工清理和重装：

```bash
bash install.sh uninstall
bash install.sh reinstall
```

```powershell
.\install.ps1 -Action Uninstall
.\install.ps1 -Action Reinstall
```

如果你需要在离线机器上做恢复，优先顺序通常是：

1. 先执行 `status` 或 `verify`
2. 需要回收时执行 `uninstall`
3. 需要回到已知状态时执行 `reinstall` 或重新跑离线部署

## 决策建议

### 用在线路径

- 你更在意“最新版本”
- 你需要经常更新
- 你部署的是个人开发机

### 用离线路径

- 你更在意“可复制、可审计、可带走”
- 你部署的是隔离机房或生产内网
- 你必须保证目标机器完全不访问互联网

## 历史脚本说明

- `scripts/export.sh`：legacy 在线导出，只适合保留旧流程时使用
- `scripts/offline-export.sh`：Unix 离线打包底层脚本
- 对外文档和日常操作应优先使用 `install.sh` / `install.ps1`
