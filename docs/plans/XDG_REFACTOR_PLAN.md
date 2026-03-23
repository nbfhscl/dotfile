# XDG Base Directory Specification 重构计划

## 概述

本计划旨在将 dotfile 项目全面改造为符合 [XDG Base Directory Specification](https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html) 的标准配置管理系统。

## 当前状态分析

### 已实现的部分 ✅
- `scripts/lib/xdg.sh` 提供了 XDG 路径辅助函数
- `install.sh` 已经初始化 XDG 路径
- 部分配置已使用 XDG 路径（nvim, tmux, zsh）

### 需要改进的部分 ❌
1. **硬编码的传统路径**：多处仍使用 `$HOME/.vimrc`、`$HOME/.zshrc` 等传统路径
2. **Vim 配置位置**：`.vim/` 目录应迁移到 `$XDG_CONFIG_HOME/vim/`
3. **向后兼容性**：需要提供迁移机制，不破坏现有用户配置
4. **Windows 平台**：需要映射到 Windows 标准路径（APPDATA, LOCALAPPDATA）
5. **测试覆盖**：E2E 测试需要验证 XDG 合规性

## XDG Base Directory Specification

### 标准路径定义

| XDG 变量 | 默认值 | 用途 | Windows 等效 |
|---------|--------|------|-------------|
| `XDG_CONFIG_HOME` | `$HOME/.config` | 用户配置文件 | `%APPDATA%` |
| `XDG_DATA_HOME` | `$HOME/.local/share` | 用户数据文件 | `%LOCALAPPDATA%` |
| `XDG_CACHE_HOME` | `$HOME/.cache` | 用户缓存数据 | `%LOCALAPPDATA%\cache` |
| `XDG_STATE_HOME` | `$HOME/.local/state` | 用户状态数据 | `%LOCALAPPDATA%\state` |

### 应用特定路径示例

```
$XDG_CONFIG_HOME/nvim/init.lua       → ~/.config/nvim/init.lua
$XDG_CONFIG_HOME/vim/vimrc           → ~/.config/vim/vimrc
$XDG_CONFIG_HOME/tmux/tmux.conf      → ~/.config/tmux/tmux.conf
$XDG_CONFIG_HOME/zsh/.zshrc          → ~/.config/zsh/.zshrc
$XDG_DATA_HOME/nvim/site/after/      → ~/.local/share/nvim/site/after/
$XDG_STATE_HOME/nvim/shada/          → ~/.local/state/nvim/shada/
$XDG_CACHE_HOME/nvim/swap/           → ~/.cache/nvim/swap/
```

## 重构策略

### 阶段 1：增强 XDG 路径库 (scripts/lib/xdg.sh)

**目标**：提供跨平台、功能完整的 XDG 路径管理

**新增功能**：
1. **Windows 平台支持**
   ```bash
   xdg_config_home_windows()  # 返回 Windows 等效路径
   xdg_data_home_windows()
   xdg_cache_home_windows()
   xdg_state_home_windows()
   ```

2. **迁移辅助函数**
   ```bash
   migrate_legacy_config()     # 从旧路径迁移到 XDG 路径
   create_xdg_compat_symlink() # 创建向后兼容的符号链接
   detect_legacy_config()      # 检测是否存在旧配置
   ```

3. **路径验证和修复**
   ```bash
   ensure_xdg_structure()      # 确保 XDG 目录结构完整
   verify_xdg_compliance()     # 验证配置是否合规
   ```

### 阶段 2：重构 Unix/Linux/macOS 配置

**迁移计划**：

| 传统路径 | XDG 路径 | 迁移策略 |
|---------|----------|---------|
| `~/.vimrc` | `~/.config/vim/vimrc` | 复制 + 符号链接 |
| `~/.vim/` | `~/.config/vim/` | 移动 + 符号链接 |
| `~/.zshrc` | `~/.config/zsh/.zshrc` | 复制 + 符号链接 |
| `~/.tmux.conf` | `~/.config/tmux/tmux.conf` | 复制 + 符号链接 |

**install.sh 改造**：
1. 添加 `migrate_to_xdg()` 函数
2. 修改 `deploy_dotfiles()` 优先使用 XDG 路径
3. 更新 `verify_xdg_paths()` 验证 XDG 合规性
4. 添加向后兼容性选项

### 阶段 3：重构 Windows PowerShell

**路径映射**：
```powershell
$XDG_CONFIG_HOME = $env:APPDATA           # C:\Users\<user>\AppData\Roaming
$XDG_DATA_HOME   = $env:LOCALAPPDATA      # C:\Users\<user>\AppData\Local
$XDG_CACHE_HOME  = "$env:LOCALAPPDATA\cache"
$XDG_STATE_HOME  = "$env:LOCALAPPDATA\state"
```

**install.ps1 改造**：
1. 添加 `Initialize-XdgPaths` 函数
2. 修改配置部署逻辑使用 XDG 路径
3. 添加 `Invoke-LegacyMigration` 函数
4. 更新测试验证 XDG 路径

### 阶段 4：测试和验证

**E2E 测试增强**：
1. XDG 路径合规性验证
2. 配置迁移测试
3. 向后兼容性测试
4. 跨平台一致性测试

## 实施步骤

### Step 1: 增强 scripts/lib/xdg.sh
- [ ] 添加 Windows 平台检测
- [ ] 实现 Windows XDG 路径函数
- [ ] 实现迁移辅助函数
- [ ] 实现路径验证函数

### Step 2: 更新 install.sh
- [ ] 添加迁移逻辑
- [ ] 修改配置部署使用 XDG 路径
- [ ] 更新测试函数
- [ ] 添加 XDG 合规性检查

### Step 3: 更新 install.ps1
- [ ] 实现 PowerShell XDG 路径函数
- [ ] 修改配置部署逻辑
- [ ] 添加迁移函数
- [ ] 更新测试

### Step 4: 更新测试
- [ ] 修改 run-e2e-test.sh
- [ ] 添加 XDG 合规性测试
- [ ] 验证所有测试通过

### Step 5: 文档更新
- [ ] 更新 README.md
- [ ] 更新 CLAUDE.md 和 AGENTS.md
- [ ] 添加迁移指南

## 向后兼容性策略

1. **检测旧配置**：在部署前检查是否存在传统路径的配置
2. **自动迁移**：提供自动迁移选项，将旧配置移动到 XDG 路径
3. **符号链接**：在传统路径创建符号链接指向 XDG 路径
4. **环境变量控制**：提供 `XDG_MIGRATE=1` 等选项控制迁移行为
5. **回滚机制**：保留备份，允许用户回滚

## 风险评估

| 风险 | 影响 | 缓解措施 |
|-----|------|---------|
| 破坏现有用户配置 | 高 | 自动备份 + 回滚机制 |
| 不同工具不支持 XDG | 中 | 符号链接向后兼容 |
| Windows 路径差异 | 中 | 抽象层 + 测试覆盖 |
| 迁移失败 | 高 | 测试覆盖 + 用户确认 |

## 验收标准

- [ ] 所有配置文件使用 XDG 路径
- [ ] 无硬编码的传统路径
- [ ] E2E 测试全部通过
- [ ] Windows 和 Unix 行为一致
- [ ] 现有用户可平滑迁移
- [ ] 文档完整更新

## 参考资料

- [XDG Base Directory Specification](https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html)
- [Arch Linux Wiki - XDG Base Directory](https://wiki.archlinux.org/title/XDG_Base_Directory)
- [Vim XDG Support](https://vimhelp.org/quickref.txt.html#*$XDG_CONFIG_HOME*)
