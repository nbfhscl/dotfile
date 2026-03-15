# 统一安装完整指南

这份指南按“在线安装”和“离线部署”两条主流程整理当前仓库的用法，避免继续引用历史上的分散脚本。

## 先做选择

### 日常开发机

优先使用在线路径：

```bash
bash install.sh install
bash install.sh update
```

```powershell
.\install.ps1 -Action Install
.\install.ps1 -Action Update
```

### 隔离环境或灾备

优先使用离线路径：

```bash
bash install.sh package
bash install.sh offline-deploy ./scripts/dist/dotfiles-offline-<version>.sh
```

```powershell
.\install.ps1 -Action Package
.\install.ps1 -Action OfflineDeploy
```

## 在线路径

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

## 离线路径

### Unix 离线包生成

`install.sh package` 会调用 `scripts/offline-export.sh`，完整执行：

1. 收集本机配置快照
2. 收集本机依赖与离线安装材料
3. 生成自解压离线包到 `scripts/dist/`

常用命令：

```bash
bash install.sh package
AUTO_YES=1 bash scripts/offline-export.sh
DRY_RUN=1 bash install.sh package
```

### Unix 离线包使用

```bash
bash ./scripts/dist/dotfiles-offline-<version>.sh install
bash ./scripts/dist/dotfiles-offline-<version>.sh info
bash ./scripts/dist/dotfiles-offline-<version>.sh extract ./dotfiles-offline
```

也可以通过统一入口包装执行：

```bash
bash install.sh offline-deploy ./scripts/dist/dotfiles-offline-<version>.sh
```

### Windows 离线包生成与使用

```powershell
.\install.ps1 -Action Package
.\install.ps1 -Action Package -IncludeDocumentation
.\install.ps1 -Action Package -Compress
.\install.ps1 -Action OfflineDeploy
```

Windows 离线包会生成：

- `scripts\install.ps1`
- `scripts\offline-install.ps1`
- `modules\`
- `tools\`
- `config\`

## 卸载与重装

### Linux / macOS

```bash
bash install.sh uninstall
bash install.sh reinstall
```

支持预览：

```bash
DRY_RUN=1 bash install.sh reinstall
```

### Windows

```powershell
.\install.ps1 -Action Uninstall
.\install.ps1 -Action Reinstall
```

兼容模式仍可使用：

```powershell
.\install.ps1 -Uninstall
```

## XDG 目录约定

| 语义 | Unix | Windows |
|------|------|---------|
| 配置 | `$HOME/.config` | `%USERPROFILE%\.config` |
| 数据 | `$HOME/.local/share` | `%USERPROFILE%\.local\share` |
| 状态 | `$HOME/.local/state` | `%USERPROFILE%\.local\state` |
| 缓存 | `$HOME/.cache` | `%USERPROFILE%\.cache` |

如果安装后路径看起来不对，先用 `status` 和 `verify` 检查，不要直接手改文档里旧的目标目录。

## 故障排查顺序

1. 先确认入口是否正确：`install.sh` 或 `install.ps1`
2. 运行 `status`
3. 运行 `verify`
4. 需要回收时执行 `uninstall`
5. 需要重建时执行 `reinstall`

## 历史材料

- `scripts/export.sh`：legacy 在线导出脚本，仅用于兼容旧流程
- `scripts/offline-export.sh`：Unix 离线打包底层脚本
- 当前主文档和日常操作都应围绕 `install.sh` / `install.ps1`
