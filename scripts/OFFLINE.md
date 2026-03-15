# Unix 离线打包指南

这份文档只描述 Unix 侧的离线流程。当前推荐入口是：

```bash
bash install.sh package
```

它会调用 `scripts/offline-export.sh` 完成真正的离线打包。

## 离线流程适用场景

适用于：

- 目标机器完全不能联网
- 需要把配置和本地依赖一起带走
- 需要在内网、实验环境或灾备环境复用同一份部署材料

不适用于：

- 你只想在联网开发机上同步最新配置
- 你更需要持续更新，而不是生成固定快照

## 入口与脚本关系

| 层级 | 脚本 | 作用 |
|------|------|------|
| 主入口 | `install.sh package` | 对外推荐入口 |
| 总控 | `scripts/offline-export.sh` | 顺序执行离线收集和离线打包 |
| 收集 | `scripts/offline-collect.sh` | 收集本地依赖、配置和元数据 |
| 打包 | `scripts/offline-package.sh` | 生成自解压离线包 |

## 最常用命令

### 一键打包

```bash
cd scripts
bash offline-export.sh
```

### 从主入口打包

```bash
cd ..
bash install.sh package
```

### 非交互和预览

```bash
AUTO_YES=1 bash scripts/offline-export.sh
DRY_RUN=1 bash scripts/offline-export.sh
DRY_RUN=1 bash install.sh package
```

`AUTO_YES=1` 会跳过交互确认，适合自动化环境。`DRY_RUN=1` 会打印计划执行的步骤，不真正写出离线包。

## 产物位置

默认输出目录是：

```text
scripts/dist/
```

生成文件形态类似：

```text
scripts/dist/dotfiles-offline-20260315_120000.sh
scripts/dist/dotfiles-offline-20260315_120000.sh.sha256
```

## 目标机器如何使用

### 直接执行离线包

```bash
bash dotfiles-offline-<version>.sh install
```

### 查看包信息

```bash
bash dotfiles-offline-<version>.sh info
```

### 只解压不安装

```bash
bash dotfiles-offline-<version>.sh extract ./dotfiles-offline
```

### 通过统一入口包装执行

```bash
bash install.sh offline-deploy ./scripts/dist/dotfiles-offline-<version>.sh
```

## 打包内容概念

离线包通常包含以下几类内容：

- dotfile 配置快照
- 本机可执行文件和依赖
- 离线系统包或语言包材料
- 元数据和清单文件
- 自解压安装脚本

最终目标是让目标机器在不访问外部网络的前提下完成部署。

## 推荐操作顺序

1. 在联网机器运行 `bash install.sh package`
2. 验证产物存在于 `scripts/dist/`
3. 可选执行 `sha256sum -c` 验证校验文件
4. 通过 U 盘、内网共享或安全分发方式传给目标机器
5. 在目标机器执行离线包的 `install` 动作

## 常见问题

### 打包前想确认会做什么

```bash
DRY_RUN=1 bash install.sh package
```

### 想跳过交互确认

```bash
AUTO_YES=1 bash scripts/offline-export.sh
```

### 想拆开调试

```bash
bash scripts/offline-collect.sh
bash scripts/offline-package.sh
```

## 限制

- 离线包不是“自动更新”机制，它是某个时间点的发布快照
- 目标机器要更新到新版本，通常需要重新生成新的离线包
- 包体积通常明显大于在线安装路径

## 历史说明

`scripts/export.sh` 仍然存在，但它属于 legacy 在线导出，不应与当前的离线打包流程混用。
