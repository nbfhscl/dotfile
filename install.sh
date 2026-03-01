#!/bin/bash
# install.sh - 安全部署 dotfile 到新环境
# 使用方式: curl -fsSL https://raw.githubusercontent.com/nbfhscl/dotfile/refs/heads/master/install.sh | bash

set -euo pipefail

# 配置
REPO_URL="https://github.com/nbfhscl/dotfile.git"  # ← 替换为你的仓库地址
DOT_DIR="$HOME/.dotfile"
BACKUP_DIR="$HOME/.dotfile_backup_$(date +%Y%m%d_%H%M%S)"
ALIAS_NAME="dot"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log() {
  echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
  echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
  echo -e "${RED}[ERROR]${NC} $1" >&2
  exit 1
}

# 检查 Git 是否安装
if ! command -v git &> /dev/null; then
  error "Git is not installed. Please install Git first."
fi

# 检查是否已存在 dotfile 仓库
if [ -d "$DOT_DIR" ]; then
  error ".dotfile directory already exists. Aborting."
fi

log "Cloning dotfile bare repository..."
git clone --bare "$REPO_URL" "$DOT_DIR" >/dev/null 2>&1

# 定义 dot 命令函数（避免依赖 alias）
dot() {
  git --git-dir="$DOT_DIR" --work-tree="$HOME" "$@"
}

# 检查哪些文件会冲突（不执行 checkout，避免副作用）
log "Checking for conflicting files..."
conflicts=()
tracked_files="$(dot ls-tree -r --name-only HEAD || true)"
if [ -n "$tracked_files" ]; then
  while IFS= read -r file; do
    [ -n "$file" ] || continue
    if [ -e "$HOME/$file" ] || [ -L "$HOME/$file" ]; then
      conflicts+=("$file")
    fi
  done <<< "$tracked_files"
fi

if [ "${#conflicts[@]}" -gt 0 ]; then
  warn "The following files already exist and will be backed up:"
  mkdir -p "$BACKUP_DIR"
  for file in "${conflicts[@]}"; do
    if [ -e "$HOME/$file" ] || [ -L "$HOME/$file" ]; then
      backup_path="$BACKUP_DIR/$file"
      mkdir -p "$(dirname "$backup_path")"
      cp -a "$HOME/$file" "$backup_path"
      echo "  → $file"
    fi
  done
  log "Backup saved to: $BACKUP_DIR"
else
  log "No conflicts found."
fi

# 强制检出配置（覆盖本地同名文件）
log "Deploying dotfile..."
dot checkout -f >/dev/null 2>&1

# 隐藏未跟踪文件（避免 status 显示整个家目录）
dot config --local status.showUntrackedFiles no

# 将 alias 写入 shell 配置（支持 zsh/bash）
SHELL_RC=""
shell_name="$(basename "${SHELL:-}")"
if [ "$shell_name" = "zsh" ]; then
  SHELL_RC="$HOME/.zshrc"
elif [ "$shell_name" = "bash" ]; then
  SHELL_RC="$HOME/.bashrc"
else
  # 默认写入 .profile
  SHELL_RC="$HOME/.profile"
fi

if ! grep -q "alias $ALIAS_NAME=" "$SHELL_RC" 2>/dev/null; then
  echo "alias $ALIAS_NAME='git --git-dir=\$HOME/.dotfile/ --work-tree=\$HOME'" >> "$SHELL_RC"
  log "Added 'dot' alias to $SHELL_RC"
fi

log "✅ Dotfiles successfully deployed!"
log "Run 'source $SHELL_RC' or restart your shell to use the 'dot' command."
