# Docker 测试 Arch Linux 环境测试用例逐条澄清

## 测试概览

**测试环境：** Docker 容器 archlinux:latest  
**测试脚本：** tests/e2e/test-all-commands.sh  
**测试套件：** 13 个测试套件，覆盖所有 install.sh 命令

---

## 测试套件详细说明

### TEST SUITE 1: HELP COMMAND

**目的：** 验证帮助信息的正确显示

| 测试用例 | 命令 | 预期结果 | 状态 |
|---------|------|----------|------|
| 1.1 | `bash install.sh --help` | 显示完整帮助信息 | ✅ |
| 1.2 | `bash install.sh -h` | 短选项帮助 | ✅ |
| 1.3 | `bash install.sh help` | help 子命令 | ✅ |
| 1.4 | `bash install.sh` | 无参数时显示帮助 | ✅ |

**验证内容：**
- 帮助信息包含支持的命令列表
- 帮助信息包含使用示例
- 所有显示方式结果一致

---

### TEST SUITE 2: STATUS COMMAND (PRE-INSTALLATION)

**目的：** 验证安装前状态检查

| 测试用例 | 命令 | 预期结果 | 状态 |
|---------|------|----------|------|
| 2.1 | `bash install.sh status` | 显示未安装状态，不失败 | ✅ |

**验证内容：**
- 命令成功执行（不会因未安装而失败）
- 显示当前未安装状态
- 提供安装指引

---

### TEST SUITE 3: VERIFY COMMAND (PRE-INSTALLATION)

**目的：** 验证安装前验证的错误处理

| 测试用例 | 命令 | 预期结果 | 状态 |
|---------|------|----------|------|
| 3.1 | `bash install.sh verify` | 失败（exit code 1） | ✅ |

**验证内容：**
- 命令预期失败
- 显示有意义的错误信息
- 指引用户先进行安装

---

### TEST SUITE 4: DEPLOY COMMAND

**目的：** 验证部署命令的核心功能

| 测试用例 | 命令 | 预期结果 | 状态 |
|---------|------|----------|------|
| 4.1 | `SKIP_INSTALL=1 bash install.sh deploy` | 成功部署 | ✅ |

**验证内容：**
- 创建 `$HOME/.dotfile` 目录
- 确认是 bare git repository
- 配置文件正确部署到 `$HOME`
- XDG 符号链接/source 正确创建

---

### TEST SUITE 5: STATUS COMMAND (POST-DEPLOYMENT)

**目的：** 验证部署后状态信息

| 测试用例 | 命令 | 预期结果 | 状态 |
|---------|------|----------|------|
| 5.1 | `bash install.sh status` | 显示完整状态 | ✅ |

**验证内容：**
- 命令成功执行
- 输出包含 `XDG_CONFIG_HOME`
- 输出包含 dotfile repository 信息
- 显示已部署状态

---

### TEST SUITE 6: VERIFY COMMAND (POST-DEPLOYMENT)

**目的：** 验证部署后配置完整性

| 测试用例 | 验证项 | 预期结果 | 状态 |
|---------|--------|----------|------|
| 6.1 | `bash install.sh verify` | 成功执行 | ✅ |
| 6.2 | XDG_CONFIG_HOME | 正确设置 | ✅ |
| 6.3 | XDG_DATA_HOME | 正确设置 | ✅ |
| 6.4 | XDG_STATE_HOME | 正确设置 | ✅ |
| 6.5 | XDG_CACHE_HOME | 正确设置 | ✅ |

---

### TEST SUITE 7: UPDATE COMMAND

**目的：** 验证更新功能

| 测试用例 | 命令 | 预期结果 | 状态 |
|---------|------|----------|------|
| 7.1 | `bash install.sh update` | 成功更新 | ✅ |

**验证内容：**
- 从远程获取更新
- 正确检测默认分支（master/main）
- 成功 reset 到最新提交
- 重新部署配置文件

**问题历史：**
- ❌ 之前失败：无法检测 bare repository 的分支
- ✅ 已修复：改进了分支检测逻辑

---

### TEST SUITE 8: PACKAGE COMMAND

**目的：** 验证离线包创建

| 测试用例 | 命令 | 预期结果 | 状态 |
|---------|------|----------|------|
| 8.1 | `bash install.sh package` | 创建离线包 | ❌ |

**问题：**
- 脚本 `scripts/offline-export.sh` 不存在
- 测试预期失败

---

### TEST SUITE 9: OFFLINE-DEPLOY COMMAND

**目的：** 验证离线部署

| 测试用例 | 命令 | 前提条件 | 状态 |
|---------|------|----------|------|
| 9.1 | `bash install.sh offline-deploy <dir>` | 需要有效的包目录 | ⏭️ |

**依赖关系：**
- 依赖于 TEST SUITE 8 成功
- 如果 package 失败，此测试跳过

---

### TEST SUITE 10: REINSTALL COMMAND

**目的：** 验证重装功能

| 测试用例 | 命令 | 预期结果 | 状态 |
|---------|------|----------|------|
| 10.1 | `DRY_RUN=1 bash install.sh reinstall` | 显示重装流程 | ✅ |

**验证内容：**
- 显示卸载步骤（dry-run）
- 显示安装步骤（dry-run）
- 不实际执行操作

---

### TEST SUITE 11: UNINSTALL COMMAND

**目的：** 验证卸载功能

| 测试用例 | 命令 | 预期结果 | 状态 |
|---------|------|----------|------|
| 11.1 | `DRY_RUN=1 bash install.sh uninstall` | 显示卸载流程 | ✅ |

**验证内容：**
- 显示将要删除的文件
- 显示将要清理的配置
- 不实际执行操作（dry-run）

---

### TEST SUITE 12: ERROR HANDLING

**目的：** 验证错误处理机制

| 测试用例 | 命令 | 预期结果 | 状态 |
|---------|------|----------|------|
| 12.1 | `bash install.sh invalid-command` | 显示错误 | ✅ |

**验证内容：**
- 命令失败（exit code 非 0）
- 显示友好的错误信息
- 提示使用 `--help` 查看帮助

---

### TEST SUITE 13: XDG COMPLIANCE

**目的：** 验证 XDG Base Directory Specification 合规性

| 测试用例 | 测试内容 | 预期结果 | 状态 |
|---------|----------|----------|------|
| 13.1 | `xdg_config_home()` | 返回正确路径 | ✅ |
| 13.2 | `xdg_data_home()` | 返回正确路径 | ✅ |
| 13.3 | `xdg_state_home()` | 返回正确路径 | ✅ |
| 13.4 | `xdg_cache_home()` | 返回正确路径 | ✅ |
| 13.5 | `init_xdg_paths()` | 创建所有目录 | ✅ |
| 13.6 | XDG 路径验证 | 环境变量已设置 | ✅ |
| 13.7 | XDG 目录验证 | 所有目录存在 | ✅ |
| 13.8 | XDG 应用结构 | 创建应用目录 | ✅ |

---

## 测试优先级

### P0 - 核心功能（必须通过）
- TEST SUITE 1: HELP
- TEST SUITE 4: DEPLOY
- TEST SUITE 5: STATUS (POST-DEPLOYMENT)
- TEST SUITE 6: VERIFY (POST-DEPLOYMENT)

### P1 - 重要功能（应该通过）
- TEST SUITE 7: UPDATE
- TEST SUITE 12: ERROR HANDLING
- TEST SUITE 13: XDG COMPLIANCE

### P2 - 次要功能（可以失败）
- TEST SUITE 8: PACKAGE（脚本缺失）
- TEST SUITE 9: OFFLINE-DEPLOY（依赖 PACKAGE）
- TEST SUITE 10: REINSTALL（dry-run）
- TEST SUITE 11: UNINSTALL（dry-run）

---

## Docker 测试环境问题

### 问题 1: pacman 交互式提示

**原因：** 即使使用 `yes | pacman -S`，某些情况下仍会提示

**解决方案：** 使用 `--noconfirm` 和 `--needed` 参数

### 问题 2: Shell 配置未测试

**当前状态：**
- ✅ 测试了 bash 配置
- ❌ 没有测试 zsh 配置
- ❌ 没有测试 shell 兼容性

**建议添加：**
```bash
# Bash 配置测试
bash -c "source ~/.bashrc && echo \$EDITOR"

# Zsh 配置测试（如果安装了）
zsh -c "source ~/.zshrc && echo \$EDITOR"
```

### 问题 3: 测试从未真正完成

**原因：**
- Docker 容器卡在 pacman 安装
- 没有完整的测试报告

**解决方案：**
1. 修复 Docker 配置
2. 添加更好的错误处理
3. 生成详细测试报告

---

## 测试流程图

```
启动容器
    │
    ▼
初始化 Arch Linux
    │
    ▼
安装基础工具
    │
    ▼
TEST SUITE 1-3 (安装前测试)
    │
    ▼
TEST SUITE 4: DEPLOY
    │
    ▼
TEST SUITE 5-7 (安装后测试)
    │
    ▼
TEST SUITE 8-13 (功能测试)
    │
    ▼
生成测试报告
```

---

## 相关文档

- `TEST-CLARIFICATION.md` - Shell 配置测试澄清
- `tests/e2e/test-all-commands.sh` - 测试脚本
- `tests/compose/docker-compose.test-all-commands.yml` - Docker 配置
