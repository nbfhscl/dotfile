# install.sh 安装的工具列表

## 概述

install.sh 会根据不同的操作系统自动安装以下工具。当运行 `bash install.sh install` 时，会按类别依次安装这些工具。

---

## 工具分类

### 1. 核心开发工具

| 工具 | 包名 | 说明 | 必需 |
|------|------|------|------|
| **Git** | git | 版本控制系统 | ✅ |
| **Zsh** | zsh | 现代化 shell | ✅ |
| **Vim** | vim | 文本编辑器 | ✅ |
| **Neovim** | neovim/nvim-appimage | 现代化 Vim | ✅ |
| **Node.js** | nodejs/node | JavaScript 运行时 | ✅ |
| **NPM** | nodejs (自带) | Node.js 包管理器 | ✅ |

### 2. Zsh 生态系统

| 工具 | 说明 | 安装方式 |
|------|------|----------|
| **Oh-My-Zsh** | Zsh 配置管理框架 | 官方安装脚本 |
| **zsh-autosuggestions** | 自动建议插件 | Git clone |
| **zsh-syntax-highlighting** | 语法高亮插件 | Git clone |

### 3. 现代 CLI 工具

| 工具 | 说明 | Arch Linux | Ubuntu/Debian | macOS |
|------|------|-----------|--------------|-------|
| **zoxide** | 智能目录跳转 | pacman | 脚本安装 | brew |
| **fzf** | 模糊查找器 | pacman | pacman | brew |
| **ripgrep** | 快速文本搜索 | (可选安装) | (可选安装) | (可选安装) |
| **bat** | 增强的 cat | (可选安装) | (可选安装) | (可选安装) |
| **fd** | 快速文件查找 | (可选安装) | (可选安装) | (可选安装) |
| **eza** | 现代化 ls | (可选安装) | (可选安装) | (可选安装) |

> **注意**: ripgrep, bat, fd, eza 等工具在 install.sh 中不是强制安装的，但建议手动安装以获得最佳体验。

### 4. Tmux 生态系统

| 工具 | 说明 | 安装方式 |
|------|------|----------|
| **tmux** | 终端复用器 | 系统包管理器 |
| **TPM** | Tmux 插件管理器 | Git clone |

---

## 各平台的实际安装命令

### Arch Linux

```bash
# 核心工具
sudo pacman -S --noconfirm git zsh vim nodejs

# Neovim
# 通过 AppImage 或官方源安装

# Zsh 生态
sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
git clone https://github.com/zsh-users/zsh-autosuggestions ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting ~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting

# 现代 CLI 工具
sudo pacman -S --noconfirm zoxide fzf

# 可选增强工具
sudo pacman -S --noconfirm ripgrep bat fd eza

# Tmux 生态
sudo pacman -S --noconfirm tmux
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
```

### Ubuntu/Debian

```bash
# 核心工具
sudo apt-get update
sudo apt-get install -y git zsh vim

# Node.js
curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
sudo apt-get install -y nodejs

# Neovim
# 通过 AppImage 安装

# Zsh 生态
sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
# ... 同 Arch Linux

# 现代 CLI 工具
sudo apt-get install -y zoxide fzf
# ... 其他工具同上

# Tmux 生态
sudo apt-get install -y tmux
# ... TPM 同上
```

### macOS (Homebrew)

```bash
# 核心工具
brew install git zsh vim node

# Neovim
brew install neovim

# Zsh 生态
sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
# ... 同上

# 现代 CLI 工具
brew install zoxide fzf
# ... 其他工具同上

# Tmux 生态
brew install tmux
# ... TPM 同上
```

---

## 安装顺序

install.sh 按以下顺序安装工具：

1. **核心工具** (必需)
   - git
   - zsh
   - vim
   - nodejs/nvm

2. **Zsh 框架** (如果使用 zsh)
   - oh-my-zsh
   - zsh-autosuggestions
   - zsh-syntax-highlighting

3. **现代 CLI 工具** (强烈推荐)
   - zoxide
   - fzf

4. **Tmux 生态** (如果使用 tmux)
   - tmux
   - tpm

5. **编辑器** (必需)
   - neovim

---

## 特殊安装方式

### Neovim 安装

**优先级顺序：**
1. **Homebrew** (macOS) - `brew install neovim`
2. **AppImage** (Linux) - 从 GitHub 下载最新版本
3. **系统包管理器** - `apt/yum/pacman install neovim`

### FZF 安装

**优先级顺序：**
1. **系统包管理器** - `pacman/apt/brew install fzf`
2. **Git clone** - 克隆官方仓库并运行安装脚本

### Zoxide 安装

**优先级顺序：**
1. **Homebrew** (macOS) - `brew install zoxide`
2. **官方脚本** (Linux) - curl 脚本安装
3. **Cargo** (备选) - `cargo install zoxide`

---

## 跳过工具安装

如果只想部署配置文件而不安装工具：

```bash
# 设置环境变量跳过工具安装
SKIP_INSTALL=1 bash install.sh deploy

# 或者
export SKIP_INSTALL=1
bash install.sh install
```

---

## 验证安装

安装完成后，install.sh 会自动验证以下工具：

```bash
# 验证的核心工具
git, zsh, vim, nvim, tmux, node, npm
```

**验证命令：**
```bash
bash install.sh verify
```

---

## 工具配置文件

工具的配置文件通过 XDG Base Directory Specification 组织：

```
~/.config/
├── nvim/
│   └── init.vim          # Neovim 配置
├── tmux/
│   └── tmux.conf         # Tmux 配置
├── bash/
│   ├── .bashrc            # Bash 配置
│   └── fzf.bash            # Fzf 集成
└── zsh/
    └── .zshrc             # Zsh 配置
```

---

## 推荐的额外工具

虽然 install.sh 不会强制安装以下工具，但强烈推荐手动安装：

### 文本搜索与浏览
- **ripgrep (rg)** - 超快的文本搜索
- **bat** - 语法高亮的 cat
- **fd** - 快速的文件查找
- **eza/exa** - 现代化的 ls

### 开发增强
- **lazygit** - Git 交互式 TUI
- **gh** - GitHub 官方 CLI
- **jq** - JSON 处理器

### 安装命令

```bash
# Arch Linux
sudo pacman -S ripgrep bat fd eza lazygit gh jq

# Ubuntu/Debian
sudo apt install ripgrep bat fd-find exa lazygit gh jq

# macOS
brew install ripgrep bat fd eza lazygit gh jq
```

---

## 故障排查

### 工具安装失败

如果某个工具安装失败：

1. **检查网络连接**
   ```bash
   ping -c 3 github.com
   ```

2. **检查包管理器**
   ```bash
   # Arch
   sudo pacman -Sy
   # Ubuntu
   sudo apt update
   # macOS
   brew update
   ```

3. **手动安装失败的工具**
   查看上面"各平台的实际安装命令"部分

### Neovim AppImage 权限问题

```bash
# 下载后需要添加执行权限
chmod +x nvim-linux-x86_64.appimage
sudo mv nvim-linux-x86_64.appimage /usr/local/bin/nvim
```

### Zsh 插件安装失败

```bash
# 检查网络
curl -I https://github.com

# 手动安装
git clone https://github.com/zsh-users/zsh-autosuggestions ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions
```

---

## 相关文档

- `TOOLS-TESTING.md` - 工具测试详细说明
- `TEST-CLARIFICATION.md` - Shell 配置测试澄清
- `../README.md` - 项目主文档

