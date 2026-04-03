# Scripts 目录说明

`scripts/` 只保留当前 Unix 主流程真正依赖的辅助脚本：

- `offline-collect.sh`：收集离线部署所需配置、二进制和依赖缓存
- `offline-package.sh`：将 `.offline_collect/` 组装成自解压离线包
- `offline-export.sh`：串联收集与打包，供 `install.sh package` 调用
- `lib/actions.sh`：生命周期动作定义
- `lib/xdg.sh`：XDG 路径初始化与状态输出

历史在线导出链路和演示脚本已经移除，避免与当前离线打包语义混淆。

## 推荐入口

优先使用根目录统一入口：

```bash
bash ../install.sh install
bash ../install.sh update
bash ../install.sh package
bash ../install.sh offline-deploy ./dist/dotfiles-offline-<version>.sh
```

## 直接调用底层脚本

只在拆分调试离线打包流程时直接执行：

```bash
bash offline-collect.sh
bash offline-package.sh
bash offline-export.sh
```

## Unix 离线打包流程

`bash ../install.sh package` 等价于：

```bash
AUTO_YES=1 bash offline-export.sh
```

底层流程：

1. `offline-collect.sh` 收集配置和依赖
2. `offline-package.sh` 生成 `dist/dotfiles-offline-<version>.sh`
3. 目标机器执行该自解压包的 `install` 动作

## 非交互与预览

```bash
AUTO_YES=1 bash offline-export.sh
DRY_RUN=1 bash offline-export.sh
DRY_RUN=1 bash ../install.sh package
```
