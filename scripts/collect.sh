#!/bin/bash
# collect.sh - 收集当前系统的所有dotfile和依赖信息

set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly DOT_DIR="$HOME/.dotfile"
readonly COLLECT_DIR="$SCRIPT_DIR/.collect"
readonly MANIFEST_FILE="$COLLECT_DIR/manifest.txt"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1" >&2; exit 1; }
info() { echo -e "${BLUE}[STEP]${NC} $1"; }

# ============================================================================
# 初始化收集目录
# ============================================================================

init_collect_dir() {
  log "Initializing collection directory..."
  rm -rf "$COLLECT_DIR"
  mkdir -p "$COLLECT_DIR"/{files,packages,metadata}
}

# ============================================================================
# 收集dotfile文件列表
# ============================================================================

collect_dotfiles() {
  info "Collecting dotfile list..."

  if [ ! -d "$DOT_DIR" ]; then
    error "Dotfile repository not found at $DOT_DIR"
  fi

  # 获取仓库跟踪的所有文件
  git --git-dir="$DOT_DIR" --work-tree="$HOME" ls-tree -r --name-only HEAD > "$COLLECT_DIR/dotfiles.txt"

  local file_count=$(wc -l < "$COLLECT_DIR/dotfiles.txt")
  log "Found $file_count tracked dotfiles"
}

# ============================================================================
# 收集系统包列表
# ============================================================================

collect_system_packages() {
  info "Collecting system package information..."

  local pm
  if command -v apt-get &> /dev/null; then
    pm="apt"
  elif command -v pacman &> /dev/null; then
    pm="pacman"
  elif command -v yum &> /dev/null; then
    pm="yum"
  elif command -v dnf &> /dev/null; then
    pm="dnf"
  elif command -v brew &> /dev/null; then
    pm="brew"
  else
    warn "Unable to detect package manager"
    return
  fi

  log "Detected package manager: $pm"

  case "$pm" in
    apt)
      # 获取手动安装的包
      comm -23 <(apt-mark showmanual | sort) <(gzip -dc /var/log/installer/initial-manifest.gz 2>/dev/null || echo "") \
        > "$COLLECT_DIR/packages/apt.txt" 2>/dev/null || true

      # 获取所有已安装的包
      dpkg --get-selections | grep -v deinstall | awk '{print $1}' > "$COLLECT_DIR/packages/apt-all.txt"
      ;;
    pacman)
      # 获取显式安装的包
      pacman -Qeq > "$COLLECT_DIR/packages/pacman.txt"
      ;;
    yum|dnf)
      # 获取用户安装的包
      history_cmd=$(rpm -qf /bin/yum 2>/dev/null | grep -q yum && echo "yum" || echo "dnf")
      $history_cmd history user > "$COLLECT_DIR/packages/rpm.txt" 2>/dev/null || true
      ;;
    brew)
      # 获取通过brew安装的包
      brew list --formula > "$COLLECT_DIR/packages/brew.txt"
      brew list --cask > "$COLLECT_DIR/packages/brew-cask.txt" 2>/dev/null || true
      ;;
  esac

  log "Package list saved to $COLLECT_DIR/packages/"
}

# ============================================================================
# 收集语言包管理器
# ============================================================================

collect_language_packages() {
  info "Collecting language package manager info..."

  # npm global packages
  if command -v npm &> /dev/null; then
    npm list -g --depth=0 --json 2>/dev/null | \
      jq -r '.dependencies | keys[]' 2>/dev/null > "$COLLECT_DIR/packages/npm.txt" || \
      npm list -g --depth=0 2>/dev/null | grep -v empty | tail -n +2 | awk '{print $2}' | sed 's/@.*//' > "$COLLECT_DIR/packages/npm.txt" || true
    log "Found $(wc -l < "$COLLECT_DIR/packages/npm.txt" 2>/dev/null || echo 0) npm packages"
  fi

  # Python packages
  if command -v pip &> /dev/null; then
    pip list --format=freeze 2>/dev/null > "$COLLECT_DIR/packages/pip.txt" || true
    log "Found $(wc -l < "$COLLECT_DIR/packages/pip.txt" 2>/dev/null || echo 0) Python packages"
  fi

  # Ruby gems
  if command -v gem &> /dev/null; then
    gem list 2>/dev/null | grep -v true | awk '{print $1}' > "$COLLECT_DIR/packages/gem.txt" || true
    log "Found $(wc -l < "$COLLECT_DIR/packages/gem.txt" 2>/dev/null || echo 0) Ruby gems"
  fi

  # Cargo packages
  if command -v cargo &> /dev/null; then
    cargo install --list 2>/dev/null | awk '{print $1}' | sed 's/:$//' > "$COLLECT_DIR/packages/cargo.txt" || true
    log "Found $(wc -l < "$COLLECT_DIR/packages/cargo.txt" 2>/dev/null || echo 0) Cargo packages"
  fi
}

# ============================================================================
# 收集版本信息
# ============================================================================

collect_versions() {
  info "Collecting tool versions..."

  {
    echo "=== Collection Date ==="
    date
    echo ""

    echo "=== System Information ==="
    uname -a
    echo ""

    echo "=== OS Release ==="
    [ -f /etc/os-release ] && cat /etc/os-release
    echo ""

    echo "=== Shell ==="
    echo "$SHELL"
    echo ""

    echo "=== Tool Versions ==="
    for tool in git zsh vim nvim tmux node npm python3 python ruby go cargo; do
      if command -v "$tool" &> /dev/null; then
        echo "$tool: $($tool --version 2>&1 | head -1 || echo "unknown")"
      fi
    done
  } > "$COLLECT_DIR/metadata/versions.txt"

  log "Version information saved"
}

# ============================================================================
# 收集插件和配置仓库
# ============================================================================

collect_plugins() {
  info "Collecting plugin repositories..."

  {
    echo "=== Oh My ZSH ==="
    [ -d "$HOME/.oh-my-zsh" ] && echo "Installed: $HOME/.oh-my-zsh"

    echo ""
    echo "=== ZSH Plugins ==="
    [ -d "$HOME/.oh-my-zsh/custom/plugins" ] && find "$HOME/.oh-my-zsh/custom/plugins" -maxdepth 2 -name ".git" -printf "%P\n" | sed 's/\/.git//' | sed "s/^/$HOME\/.oh-my-zsh\/custom\//"

    echo ""
    echo "=== Tmux Plugin Manager ==="
    [ -d "$HOME/.tmux/plugins/tpm" ] && echo "Installed: $HOME/.tmux/plugins/tpm"

    echo ""
    echo "=== Vim Plugins ==="
    if command -v nvim &> /dev/null; then
      echo "Neovim: $(nvim --version | head -1)"
    fi

    echo ""
    echo "=== fzf ==="
    [ -d "$HOME/.fzf" ] && echo "Installed: $HOME/.fzf"

  } > "$COLLECT_DIR/metadata/plugins.txt"

  log "Plugin information saved"
}

# ============================================================================
# 生成清单文件
# ============================================================================

generate_manifest() {
  info "Generating manifest..."

  {
    echo "=== DOTFILE MANIFEST ==="
    echo "Generated: $(date)"
    echo "Hostname: $(hostname)"
    echo "User: $USER"
    echo "Home: $HOME"
    echo ""

    echo "=== DOTFILES ==="
    cat "$COLLECT_DIR/dotfiles.txt"
    echo ""

    echo "=== PACKAGE MANAGER ==="
    ls -1 "$COLLECT_DIR/packages/" 2>/dev/null | while read pkg_file; do
      echo "[$pkg_file]"
      head -20 "$COLLECT_DIR/packages/$pkg_file" 2>/dev/null
      echo "..."
      echo ""
    done
  } > "$MANIFEST_FILE"

  log "Manifest generated: $MANIFEST_FILE"
}

# ============================================================================
# 主函数
# ============================================================================

main() {
  echo ""
  echo "=========================================="
  echo "  Dotfile Collection Tool"
  echo "=========================================="
  echo ""

  init_collect_dir
  collect_dotfiles
  collect_system_packages
  collect_language_packages
  collect_versions
  collect_plugins
  generate_manifest

  echo ""
  log "✅ Collection complete!"
  echo ""
  log "Output directory: $COLLECT_DIR"
  log "Manifest file: $MANIFEST_FILE"
  echo ""

  log "Next steps:"
  echo "  1. Review the collected files in $COLLECT_DIR"
  echo "  2. Run: bash $SCRIPT_DIR/package.sh"
  echo ""
}

main "$@"
