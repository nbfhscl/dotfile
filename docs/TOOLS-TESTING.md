# 工具测试说明

## 概述

部署完成后，系统会自动验证常用工具是否正确安装和配置。这确保 dotfile 不仅仅是复制配置文件，还能保证工具链的完整性。

## 测试的工具

### 核心工具
- **Git** - 版本控制
- **Neovim** - 现代化 Vim 编辑器
- **Vim** - 传统 Vim 编辑器（备选）

### 现代 CLI 工具
- **ripgrep (rg)** - 快速文本搜索
- **fzf** - 模糊查找器
- **bat** - 增强的 cat（语法高亮）
- **fd** - 快速文件查找

### 增强工具
- **eza/exa** - 现代化的 ls 替代品
- **zoxide** - 智能目录跳转
- **tmux** - 终端复用器

## 测试内容

### 1. 工具可用性检查

验证工具是否已安装并可执行：

```bash
command -v nvim >/dev/null 2>&1 && echo "Neovim installed"
```

### 2. 工具版本验证

检查工具版本信息：

```bash
nvim --version
rg --version
fzf --version
```

### 3. 基本功能测试

测试工具的基本操作：

- **ripgrep**: 搜索文本文件
- **fzf**: 模糊匹配测试
- **bat**: 显示文件内容
- **eza**: 列出目录内容
- **fd**: 查找文件

### 4. 配置文件验证

验证工具配置文件存在：

- Neovim: `~/.config/nvim/init.vim`
- Tmux: `~/.config/tmux/tmux.conf` 或 `~/.tmux.conf`
- fzf: `~/.config/bash/fzf.bash`

### 5. Shell 集成验证

验证工具在 shell 配置中的集成：

- Bash 配置: `~/.bashrc` 
- Zsh 配置: `~/.zshrc`
- 检查是否正确 source XDG 配置
- 检查是否有 shell 检测

## 测试脚本

### test-all-commands.sh

**位置:** `tests/e2e/test-all-commands.sh`

**TEST SUITE 14: TOOLS VERIFICATION**

在部署后运行，验证：
- 工具是否安装
- 配置文件是否存在
- Shell 集成是否正确

### test-tools-functionality.sh

**位置:** `tests/e2e/test-tools-functionality.sh`

专门的工具功能测试脚本：

```bash
# 运行工具功能测试
bash tests/e2e/test-tools-functionality.sh
```

**测试套件：**
1. Git Tests
2. Neovim Tests
3. Ripgrep Tests
4. Fzf Tests
5. Bat Tests
6. Eza/Exa Tests
7. Fd Tests
8. Zoxide Tests
9. Tmux Tests
10. Shell Configuration Tests

### run-e2e-test.sh

**位置:** `tests/e2e/run-e2e-test.sh`

**TEST SUITE 10: TOOLS AVAILABILITY**

E2E 测试中的工具验证部分。

## Docker 测试环境

### 安装的工具

Docker 容器会自动安装以下工具：

```bash
pacman -S --noconfirm --needed \
  git curl bash sudo \
  neovim ripgrep fzf \
  bat fd eza tmux zoxide
```

### 运行测试

```bash
# 完整命令测试（包含工具测试）
docker-compose -f tests/compose/docker-compose.test-all-commands.yml \
  up --abort-on-container-exit

# 仅工具功能测试
docker run -it archlinux bash
  # 安装工具
  pacman -S --noconfirm git neovim ripgrep fzf bat fd eza tmux zoxide
  # 部署 dotfile
  bash install.sh deploy
  # 运行工具测试
  bash /usr/local/bin/test-tools-functionality.sh
```

## 测试结果

### 预期结果

**已安装工具 (SKIP_INSTALL=0):**
```
✓ PASSED: Git is installed
✓ PASSED: Neovim is installed
✓ PASSED: ripgrep is installed
✓ PASSED: fzf is installed
✓ PASSED: bat is installed
✓ PASSED: eza is installed
✓ PASSED: fd is installed
✓ PASSED: zoxide is installed
✓ PASSED: tmux is installed
✓ PASSED: Tool configurations exist
```

**未安装工具 (SKIP_INSTALL=1):**
```
✓ PASSED: Git is installed
○ SKIPPED: Neovim is not installed (SKIP_INSTALL=1)
○ SKIPPED: ripgrep is not installed (SKIP_INSTALL=1)
...
```

### 测试报告

测试完成后会显示汇总：

```
╔══════════════════════════════════════════════════════════════════════════════╗
║                           TEST SUMMARY                                        ║
╚══════════════════════════════════════════════════════════════════════════════╝

✓ PASSED: 25
✗ FAILED: 0
○ SKIPPED: 5

Total tests: 30
All tests passed!
```

## 手动验证

部署完成后，您可以手动验证工具：

### 验证编辑器

```bash
# Neovim
nvim --version
nvim +q  # 测试启动

# 配置文件
ls -la ~/.config/nvim/
```

### 验证搜索工具

```bash
# ripgrep
rg "test" ~/.config/nvim/

# fzf
fzf --version
```

### 验证增强工具

```bash
# bat (增强的 cat)
echo "test" | bat --plain --language=txt

# eza (增强的 ls)
eza --version
eza -la ~/.config/

# fd (文件查找)
fd "nvim" ~/.config/
```

### 验证目录跳转

```bash
# zoxide
z --version
z ~/.config/nvim/
```

### 验证终端复用

```bash
# tmux
tmux -V
tmux new-session -d -s test
tmux list-sessions
```

## 故障排查

### 工具未找到

如果测试显示工具未安装：

```bash
# Arch Linux
sudo pacman -S neovim ripgrep fzf bat fd eza tmux zoxide

# Ubuntu/Debian
sudo apt install neovim ripgrep fzf bat fd-find eza tmux zoxide

# macOS
brew install neovim ripgrep fzf bat eza tmux zoxide
```

### 配置文件缺失

如果配置文件缺失：

```bash
# 检查配置位置
ls -la ~/.config/nvim/
ls -la ~/.config/tmux/
ls -la ~/.config/bash/fzf.bash

# 重新部署
bash install.sh deploy
```

### Shell 集成问题

如果工具在 shell 中不可用：

```bash
# 检查 shell 配置
cat ~/.bashrc | grep -i toolname
cat ~/.zshrc | grep -i toolname

# 重新加载配置
source ~/.bashrc  # Bash
source ~/.zshrc   # Zsh
```

## 工具配置参考

### Neovim

**配置文件:** `~/.config/nvim/init.vim`

**基本设置:**
```vim
set number
set relativenumber
set tabstop=2
set shiftwidth=2
```

### Tmux

**配置文件:** `~/.config/tmux/tmux.conf`

**基本设置:**
```bash
set -g mouse on
set -g default-terminal "screen-256color"
```

### Fzf

**集成:** 已在 `~/.config/bash/fzf.bash` 中配置

**使用:**
```bash
# Ctrl+R 搜索历史
# Ctrl+T 搜索文件
# Alt+C 搜索目录
```

### Zoxide

**初始化:** 已在 shell 配置中添加 `eval "$(zoxide init zsh)"`

**使用:**
```bash
z dotfile       # 跳转到 dotfile 目录
z .             # 跳转到常用目录
```

## 最佳实践

1. **先安装工具再部署**
   ```bash
   sudo pacman -S neovim ripgrep fzf
   bash install.sh deploy
   ```

2. **使用工具测试验证**
   ```bash
   bash tests/e2e/test-tools-functionality.sh
   ```

3. **检查工具版本兼容性**
   某些工具可能需要特定版本才能正常工作

4. **自定义工具配置**
   - 修改 `~/.config/nvim/init.vim` 定制 Neovim
   - 修改 `~/.config/tmux/tmux.conf` 定制 Tmux

## 相关文档

- `DOCKER-TEST-CLARIFICATION.md` - Docker 测试用例详细说明
- `TEST-CLARIFICATION.md` - Shell 配置测试澄清
- `../README.md` - 项目主文档
