# Dotfile End-to-End Testing

使用 Docker 在干净的 Arch Linux 环境中测试 dotfile 的所有功能。

## 测试类型

本项目提供两种测试方式：

1. **基础 E2E 测试**：测试核心安装功能和管道执行
2. **全面命令测试**：测试所有 install.sh 支持的命令

## 快速开始

```bash
# 运行完整测试套件（从项目根目录）
docker-compose -f tests/docker-compose.test.yml up --abort-on-container-exit

# 后台运行
docker-compose -f tests/docker-compose.test.yml up -d

# 查看日志
docker-compose -f tests/docker-compose.test.yml logs -f

# 清理
docker-compose -f tests/docker-compose.test.yml down
```

## 测试套件

测试脚本会自动运行以下测试：

### Suite 1: 远程安装
- 测试 curl | bash 管道执行检测
- 验证远程安装逻辑

### Suite 2: 本地安装
- 克隆仓库
- 验证 install.sh 存在
- 测试帮助命令

### Suite 3: 安装动作
- status 命令（dry-run 模式）
- verify 命令（dry-run 模式）
- 其他动作验证

### Suite 4: 管道执行检测
- 直接执行检测
- 管道执行检测
- 参数传递

### Suite 5: 动作验证
- 验证所有有效动作（install, deploy, update 等）

### Suite 6: 库模块
- 验证库文件存在
- 测试 source 操作

### Suite 7: 脚本语法
- Bash 语法验证

## 测试结果

测试结果保存在 `tests/results/` 目录：

```
tests/results/
└── e2e-report-YYYYMMDD-HHMMSS.txt
```

## 手动测试

进入容器进行手动测试：

```bash
# 启动容器并保持运行
docker-compose -f tests/docker-compose.test.yml run --rm arch-test /bin/bash

# 在容器内手动测试
curl -fsSL https://raw.githubusercontent.com/nbfhscl/dotfile/refs/heads/master/install.sh | bash
```

## 环境变量

- `DRY_RUN=1`: 启用预览模式，不实际执行安装
- `DOT_DIR`: 自定义 dotfile 目录（默认：/root/.dotfile）

## 清理

```bash
# 停止并删除容器
docker-compose -f tests/docker-compose.test.yml down

# 删除测试结果
rm -rf tests/results/
```

## 全面命令测试

测试所有 install.sh 支持的命令（install, deploy, update, status, verify, package, offline-deploy, uninstall, reinstall）：

```bash
# 运行全面命令测试（从项目根目录）
docker-compose -f tests/docker-compose.test-all-commands.yml up --abort-on-container-exit

# 后台运行
docker-compose -f tests/docker-compose.test-all-commands.yml up -d

# 查看日志
docker-compose -f tests/docker-compose.test-all-commands.yml logs -f

# 清理
docker-compose -f tests/docker-compose.test-all-commands.yml down
```

### 测试套件详情

全面命令测试包含 13 个测试套件：

1. **帮助命令** (--help, -h, help, 无参数)
2. **状态命令**（安装前）
3. **验证命令**（安装前）
4. **部署命令**（SKIP_INSTALL=1）
5. **状态命令**（部署后）
6. **验证命令**（部署后）
7. **更新命令**
8. **打包命令**
9. **离线部署命令**
10. **重装命令**（DRY_RUN=1）
11. **卸载命令**（DRY_RUN=1）
12. **错误处理**（无效命令）
13. **XDG 合规性验证**

测试结果会显示通过、失败和跳过的测试数量，并提供详细的错误信息。
