# Scripts 目录说明

`scripts/` 下的文件现在主要承担“Unix 侧辅助能力”，而不是直接替代根目录的主入口。

当前推荐的使用顺序是：

1. 优先使用根目录 `install.sh`
2. 只有在需要拆分调试、维护打包流程或兼容旧操作时，才直接执行 `scripts/` 下的脚本

## 脚本角色

| 脚本 | 角色 | 当前定位 |
|------|------|----------|
| `collect.sh` | 在线导出收集 | legacy |
| `package.sh` | 在线导出打包 | legacy |
| `export.sh` | 在线一键导出 | legacy |
| `offline-collect.sh` | 收集离线部署所需本地依赖 | active |
| `offline-package.sh` | 把离线收集结果组装为自解压包 | active |
| `offline-export.sh` | 一键执行离线收集和离线打包 | active |
| `example.sh` | 历史演示脚本 | 辅助 |
| `lib/actions.sh` | 生命周期动作定义 | active |
| `lib/xdg.sh` | XDG 路径工具 | active |

## 推荐入口

### 正常使用

```bash
# 安装
bash ../install.sh install

# 更新
bash ../install.sh update

# 生成离线包
bash ../install.sh package

# 使用离线包部署
bash ../install.sh offline-deploy ./dist/dotfiles-offline-<version>.sh
```

### 直接调用底层脚本

只有在你明确知道自己在做什么时，才建议直接调用：

```bash
# 手动分步执行离线打包
bash offline-collect.sh
bash offline-package.sh

# 一键离线打包
bash offline-export.sh
```

## Unix 离线打包流程

`bash ../install.sh package` 等价于：

```bash
AUTO_YES=1 bash offline-export.sh
```

底层流程如下：

1. `offline-collect.sh` 收集配置和依赖
2. `offline-package.sh` 生成 `dist/dotfiles-offline-<version>.sh`
3. 目标机器执行该自解压包的 `install` 动作

## 非交互与预览

```bash
AUTO_YES=1 bash offline-export.sh
DRY_RUN=1 bash offline-export.sh
DRY_RUN=1 bash ../install.sh package
```

## Legacy 脚本说明

`export.sh`、`collect.sh`、`package.sh` 仍然保留，是因为它们代表一条历史上的“在线导出快照”路径。它们不再是当前仓库的主文档入口，也不应与 `install.sh package` 的离线语义混淆。

如果你维护旧流程，可以继续使用：

```bash
bash export.sh
```

但如果你要写新文档、做新部署或和 Windows 行为保持一致，应该回到：

```bash
bash ../install.sh install
bash ../install.sh update
bash ../install.sh package
```
