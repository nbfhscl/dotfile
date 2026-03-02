#!/bin/bash
# install.sh - 安全部署 dotfile 到新环境
# 使用方式: curl -fsSL https://raw.githubusercontent.com/nbfhscl/dotfile/refs/heads/master/install.sh | bash
#
# 环境变量:
#   DRY_RUN=1    - 只显示将要执行的操作，不实际安装
#   SKIP_INSTALL=1 - 跳过工具安装，只部署 dotfile

set -euo pipefail

# 配置
REPO_URL="https://github.com/nbfhscl/dotfile.git"  # ← 替换为你的仓库地址
DOT_DIR="$HOME/.dotfile"
BACKUP_DIR="$HOME/.dotfile_backup_$(date +%Y%m%d_%H%M%S)"
ALIAS_NAME="dot"

# 检查是否为 dry-run 模式
DRY_RUN="${DRY_RUN:-}"
SKIP_INSTALL="${SKIP_INSTALL:-}"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

# 警告但不退出
warn_error() {
  echo -e "${RED}[ERROR]${NC} $1" >&2
}

info() {
  echo -e "${BLUE}[STEP]${NC} $1"
}

# ============================================================================
# 平台检测
# ============================================================================

detect_os() {
  if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    echo "linux"
  elif [[ "$OSTYPE" == "darwin"* ]]; then
    echo "macos"
  else
    echo "unknown"
  fi
}

detect_package_manager() {
  local os=$(detect_os)

  if [ "$os" = "macos" ]; then
    if command -v brew &> /dev/null; then
      echo "brew"
    else
      echo "none"
    fi
  elif [ "$os" = "linux" ]; then
    if command -v apt-get &> /dev/null; then
      echo "apt"
    elif command -v yum &> /dev/null; then
      echo "yum"
    elif command -v dnf &> /dev/null; then
      echo "dnf"
    elif command -v pacman &> /dev/null; then
      echo "pacman"
    elif command -v zypper &> /dev/null; then
      echo "zypper"
    else
      echo "unknown"
    fi
  else
    echo "unknown"
  fi
}

# 检查是否有 sudo 权限
check_sudo() {
  if ! sudo -v &>/dev/null; then
    return 1
  fi
  return 0
}

install_package() {
  local pkg=$1
  local pm=$(detect_package_manager)

  if [ -n "$DRY_RUN" ]; then
    info "[DRY-RUN] 将安装 $pkg (使用 $pm)"
    return 0
  fi

  # 检查 sudo 权限
  if [[ "$pm" != "brew" ]] && ! check_sudo; then
    warn_error "需要 sudo 权限来安装 $pkg，跳过..."
    return 1
  fi

  case "$pm" in
    apt)
      sudo apt-get update -qq || return 1
      sudo apt-get install -y "$pkg" || return 1
      ;;
    yum|dnf)
      sudo "$pm" install -y "$pkg" || return 1
      ;;
    pacman)
      sudo pacman -S --noconfirm "$pkg" || return 1
      ;;
    brew)
      brew install "$pkg" || return 1
      ;;
    zypper)
      sudo zypper install -y "$pkg" || return 1
      ;;
    *)
      warn_error "无法识别包管理器，请手动安装 $pkg"
      return 1
      ;;
  esac
  return 0
}

# ============================================================================
# 工具安装函数
# ============================================================================

install_git() {
  if ! command -v git &> /dev/null; then
    info "正在安装 git..."
    if install_package "git"; then
      log "✓ git 安装完成"
    else
      warn_error "✗ git 安装失败"
      return 1
    fi
  else
    log "✓ git 已安装"
  fi
  return 0
}

install_zsh() {
  if ! command -v zsh &> /dev/null; then
    info "正在安装 zsh..."
    if install_package "zsh"; then
      log "✓ zsh 安装完成"
    else
      warn_error "✗ zsh 安装失败"
      return 1
    fi
  else
    log "✓ zsh 已安装"
  fi
  return 0
}

install_oh_my_zsh() {
  if [ ! -d "$HOME/.oh-my-zsh" ]; then
    info "正在安装 oh-my-zsh..."
    if sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended 2>/dev/null; then
      log "✓ oh-my-zsh 安装完成"
    else
      warn_error "✗ oh-my-zsh 安装失败"
      return 1
    fi
  else
    log "✓ oh-my-zsh 已安装"
  fi
  return 0
}

install_zsh_plugins() {
  local plugins_dir="$HOME/.oh-my-zsh/custom/plugins"
  mkdir -p "$plugins_dir"

  # zsh-autosuggestions
  if [ ! -d "$plugins_dir/zsh-autosuggestions" ]; then
    info "正在安装 zsh-autosuggestions..."
    if git clone https://github.com/zsh-users/zsh-autosuggestions "$plugins_dir/zsh-autosuggestions" 2>/dev/null; then
      log "✓ zsh-autosuggestions 安装完成"
    else
      warn_error "✗ zsh-autosuggestions 安装失败"
    fi
  else
    log "✓ zsh-autosuggestions 已安装"
  fi

  # zsh-syntax-highlighting
  if [ ! -d "$plugins_dir/zsh-syntax-highlighting" ]; then
    info "正在安装 zsh-syntax-highlighting..."
    if git clone https://github.com/zsh-users/zsh-syntax-highlighting "$plugins_dir/zsh-syntax-highlighting" 2>/dev/null; then
      log "✓ zsh-syntax-highlighting 安装完成"
    else
      warn_error "✗ zsh-syntax-highlighting 安装失败"
    fi
  else
    log "✓ zsh-syntax-highlighting 已安装"
  fi
  return 0
}

install_zoxide() {
  if ! command -v zoxide &> /dev/null; then
    info "正在安装 zoxide..."
    local pm=$(detect_package_manager)
    local installed=false

    case "$pm" in
      apt)
        if curl -fsSL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash 2>/dev/null; then
          installed=true
        fi
        ;;
      brew)
        if brew install zoxide 2>/dev/null; then
          installed=true
        fi
        ;;
      *)
        # 尝试使用 cargo 安装
        if command -v cargo &> /dev/null; then
          if cargo install zoxide 2>/dev/null; then
            installed=true
          fi
        fi
        ;;
    esac

    if [ "$installed" = true ]; then
      log "✓ zoxide 安装完成"
    else
      warn_error "✗ zoxide 安装失败，请手动安装"
      return 1
    fi
  else
    log "✓ zoxide 已安装"
  fi
  return 0
}

install_fzf() {
  if ! command -v fzf &> /dev/null; then
    info "正在安装 fzf..."
    local pm=$(detect_package_manager)
    local installed=false

    case "$pm" in
      apt)
        if install_package "fzf" 2>/dev/null; then
          installed=true
        fi
        ;;
      brew)
        if brew install fzf 2>/dev/null; then
          installed=true
        fi
        ;;
      *)
        # 使用 git 安装
        if [ ! -d "$HOME/.fzf" ]; then
          if git clone --depth 1 https://github.com/junegunn/fzf.git "$HOME/.fzf" 2>/dev/null; then
            if "$HOME/.fzf/install" --all 2>/dev/null; then
              installed=true
            fi
          fi
        fi
        ;;
    esac

    if [ "$installed" = true ]; then
      log "✓ fzf 安装完成"
    else
      warn_error "✗ fzf 安装失败"
      return 1
    fi
  else
    log "✓ fzf 已安装"
  fi
  return 0
}

install_tmux() {
  if ! command -v tmux &> /dev/null; then
    info "正在安装 tmux..."
    if install_package "tmux"; then
      log "✓ tmux 安装完成"
    else
      warn_error "✗ tmux 安装失败"
      return 1
    fi
  else
    log "✓ tmux 已安装"
  fi
  return 0
}

install_tpm() {
  local tpm_dir="$HOME/.tmux/plugins/tpm"
  if [ ! -d "$tpm_dir" ]; then
    info "正在安装 TPM (Tmux Plugin Manager)..."
    mkdir -p "$HOME/.tmux/plugins"
    if git clone https://github.com/tmux-plugins/tpm "$tpm_dir" 2>/dev/null; then
      log "✓ TPM 安装完成"
    else
      warn_error "✗ TPM 安装失败"
      return 1
    fi
  else
    log "✓ TPM 已安装"
  fi
  return 0
}

install_vim() {
  if ! command -v vim &> /dev/null; then
    info "正在安装 vim..."
    if install_package "vim"; then
      log "✓ vim 安装完成"
    else
      warn_error "✗ vim 安装失败"
      return 1
    fi
  else
    log "✓ vim 已安装"
  fi
  return 0
}

# 检测是否为 Ubuntu（而不是 Debian）
is_ubuntu() {
  if [ -f /etc/os-release ]; then
    grep -qi "ubuntu" /etc/os-release 2>/dev/null
    return $?
  fi
  return 1
}

# ============================================================================
# Neovim 安装辅助函数
# ============================================================================

# 获取当前 nvim 版本号
get_nvim_version() {
  if command -v nvim &> /dev/null; then
    nvim --version | head -1 | grep -oP 'NVIM v\K[0-9.]+' 2>/dev/null || echo "0.0.0"
  else
    echo "0.0.0"
  fi
}

# 比较两个版本号（返回 0 如果 v1 >= v2）
version_ge() {
  local v1=$1
  local v2=$2

  # 将版本号拆分为数组
  IFS='.' read -ra v1_parts <<< "$v1"
  IFS='.' read -ra v2_parts <<< "$v2"

  # 逐个比较
  for i in 0 1 2; do
    local n1=${v1_parts[$i]:-0}
    local n2=${v2_parts[$i]:-0}
    if (( n1 > n2 )); then
      return 0
    elif (( n1 < n2 )); then
      return 1
    fi
  done
  return 0
}

# 检测系统架构
detect_architecture() {
  local arch=$(uname -m)
  case "$arch" in
    x86_64|amd64)
      echo "x86_64"
      ;;
    aarch64|arm64)
      echo "arm64"
      ;;
    *)
      echo "unknown"
      ;;
  esac
}

# 获取 Neovim 最新版本号
get_latest_nvim_version() {
  if command -v curl &> /dev/null; then
    curl -s https://api.github.com/repos/neovim/neovim/releases/latest | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/' | sed 's/v//'
  elif command -v wget &> /dev/null; then
    wget -qO- https://api.github.com/repos/neovim/neovim/releases/latest | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/' | sed 's/v//'
  else
    echo "unknown"
  fi
}

# 使用 AppImage 安装 Neovim
install_nvim_appimage() {
  local arch=$(detect_architecture)

  if [ "$arch" = "unknown" ]; then
    warn_error "无法检测系统架构"
    return 1
  fi

  local latest_version=$(get_latest_nvim_version)
  if [ "$latest_version" = "unknown" ]; then
    warn_error "无法获取最新版本信息"
    return 1
  fi

  info "正在从 GitHub 下载 Neovim $latest_version (AppImage, $arch)..."

  local appimage_url="https://github.com/neovim/neovim/releases/download/v${latest_version}/nvim-linux-${arch}.appimage"
  local temp_file="/tmp/nvim.appimage"

  # 下载 AppImage
  if command -v curl &> /dev/null; then
    if ! curl -Ls "$appimage_url" -o "$temp_file" 2>/dev/null; then
      warn_error "下载 Neovim AppImage 失败"
      return 1
    fi
  elif command -v wget &> /dev/null; then
    if ! wget -q "$appimage_url" -O "$temp_file" 2>/dev/null; then
      warn_error "下载 Neovim AppImage 失败"
      return 1
    fi
  else
    warn_error "需要 curl 或 wget 来下载 Neovim"
    return 1
  fi

  # 赋予执行权限
  chmod +x "$temp_file"

  # 安装到 /usr/local/bin（需要 sudo）
  if ! check_sudo; then
    warn_error "需要 sudo 权限来安装 Neovim"
    rm -f "$temp_file"
    return 1
  fi

  if sudo mv "$temp_file" /usr/local/bin/nvim 2>/dev/null; then
    log "✓ Neovim AppImage 安装完成"
    return 0
  else
    warn_error "安装 Neovim 失败"
    rm -f "$temp_file"
    return 1
  fi
}

# 使用 brew 安装 Neovim（macOS）
install_nvim_brew() {
  info "正在使用 brew 安装 Neovim..."
  if brew install neovim 2>/dev/null; then
    log "✓ Neovim 安装完成"
    return 0
  else
    warn_error "✗ Neovim 安装失败"
    return 1
  fi
}

# 验证 Neovim 版本
verify_nvim_version() {
  if ! command -v nvim &> /dev/null; then
    error "Neovim 安装验证失败：nvim 命令不存在"
  fi

  local version=$(get_nvim_version)
  info "已安装 Neovim 版本: $version"

  if ! version_ge "$version" "0.9.0"; then
    error "Neovim 版本过低 ($version < 0.9.0)，LazyVim 需要至少 0.9.0"
  fi

  log "✓ Neovim 版本验证通过 ($version ≥ 0.9.0)"
}

install_nvim() {
  local os=$(detect_os)
  local installed=false

  # 检查现有版本
  if command -v nvim &> /dev/null; then
    local current_version=$(get_nvim_version)
    if version_ge "$current_version" "0.9.0"; then
      log "✓ Neovim 已安装 (版本 $current_version ≥ 0.9.0)"
      return 0
    else
      warn "检测到 Neovim 版本 $current_version < 0.9.0，将自动升级"
    fi
  fi

  info "正在安装 Neovim (需要 ≥ 0.9.0)..."
  echo ""

  # 根据操作系统选择安装方式
  if [ "$os" = "macos" ]; then
    # macOS 使用 brew
    if install_nvim_brew; then
      installed=true
    fi
  else
    # Linux 使用 AppImage
    if [ -n "$DRY_RUN" ]; then
      info "[DRY-RUN] 将从 GitHub 下载 Neovim AppImage"
      installed=true
    else
      if install_nvim_appimage; then
        installed=true
      fi
    fi
  fi

  if [ "$installed" = true ]; then
    echo ""
    # 验证安装的版本
    if [ -z "$DRY_RUN" ]; then
      verify_nvim_version
    fi
    return 0
  else
    warn_error "✗ Neovim 安装失败"
    return 1
  fi
}

install_nodejs_npm() {
  if ! command -v node &> /dev/null || ! command -v npm &> /dev/null; then
    info "正在安装 Node.js 和 npm..."
    local pm=$(detect_package_manager)
    local installed=false

    case "$pm" in
      apt)
        # 使用 NodeSource 仓库安装最新 LTS
        if check_sudo; then
          if curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash - 2>/dev/null; then
            if install_package "nodejs" 2>/dev/null; then
              installed=true
            fi
          fi
        fi
        ;;
      brew)
        if brew install node 2>/dev/null; then
          installed=true
        fi
        ;;
      *)
        if install_package "nodejs" 2>/dev/null; then
          installed=true
        fi
        ;;
    esac

    if [ "$installed" = true ]; then
      log "✓ Node.js 和 npm 安装完成"
    else
      warn_error "✗ Node.js 和 npm 安装失败"
      return 1
    fi
  else
    log "✓ Node.js 和 npm 已安装"
  fi
  return 0
}

# ============================================================================
# 安装验证
# ============================================================================

verify_installation() {
  log ""
  log "正在验证安装..."

  local failed=0

  # 检查必需工具
  local tools=("git" "zsh" "vim" "nvim" "tmux" "node" "npm")
  for tool in "${tools[@]}"; do
    if command -v "$tool" &> /dev/null; then
      log "  ✓ $tool 已安装"
    else
      warn "  ✗ $tool 未安装"
      ((failed++))
    fi
  done

  # 检查目录
  [ -d "$HOME/.oh-my-zsh" ] && log "  ✓ oh-my-zsh 已安装" || ((failed++))
  [ -d "$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions" ] && log "  ✓ zsh-autosuggestions 已安装" || ((failed++))
  [ -d "$HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting" ] && log "  ✓ zsh-syntax-highlighting 已安装" || ((failed++))
  [ -d "$HOME/.tmux/plugins/tpm" ] && log "  ✓ TPM 已安装" || ((failed++))

  command -v zoxide &> /dev/null && log "  ✓ zoxide 已安装" || ((failed++))
  command -v fzf &> /dev/null && log "  ✓ fzf 已安装" || ((failed++))

  return $failed
}

# ============================================================================
# 主安装流程
# ============================================================================

show_help() {
  cat << EOF
用法: bash install.sh [选项]

选项:
  DRY_RUN=1          只显示将要执行的操作，不实际安装
  SKIP_INSTALL=1     跳过工具安装，只部署 dotfile

环境变量:
  REPO_URL           dotfile 仓库地址 (默认: https://github.com/nbfhscl/dotfile.git)
  DOT_DIR            dotfile 存储目录 (默认: \$HOME/.dotfile)

示例:
  bash install.sh                           # 正常安装
  DRY_RUN=1 bash install.sh                 # 预览模式
  SKIP_INSTALL=1 bash install.sh            # 只部署 dotfile
  curl -fsSL https://raw.githubusercontent.com/.../install.sh | bash

EOF
}

main() {
  # 显示帮助
  if [[ "${1:-}" == "-h" ]] || [[ "${1:-}" == "--help" ]]; then
    show_help
    exit 0
  fi

  echo ""
  echo "=========================================="
  echo "  Dotfile 自动安装脚本"
  echo "=========================================="
  echo ""

  if [ -n "$DRY_RUN" ]; then
    warn "DRY-RUN 模式：只显示将要执行的操作"
    echo ""
  fi

  # 检测平台
  local os=$(detect_os)
  local pm=$(detect_package_manager)
  log "检测到操作系统: $os"
  log "检测到包管理器: $pm"
  echo ""

  if [ "$pm" = "unknown" ] || [ "$pm" = "none" ]; then
    error "无法识别包管理器，安装无法继续"
  fi

  # 按依赖顺序安装工具
  if [ -z "$SKIP_INSTALL" ]; then
    info "开始安装必需工具..."
    echo ""

    # 跟踪失败的安装
    declare -a failed_installs=()

    # 1. 基础工具
    install_git || failed_installs+=("git")
    install_zsh || failed_installs+=("zsh")
    install_vim || failed_installs+=("vim")

    # 2. Node.js/npm（某些工具可能需要）
    install_nodejs_npm || failed_installs+=("nodejs/npm")

    # 3. zsh 生态
    install_oh_my_zsh || failed_installs+=("oh-my-zsh")
    install_zsh_plugins || failed_installs+=("zsh-plugins")
    install_zoxide || failed_installs+=("zoxide")
    install_fzf || failed_installs+=("fzf")

    # 4. tmux 生态
    install_tmux || failed_installs+=("tmux")
    install_tpm || failed_installs+=("tpm")

    # 5. neovim
    install_nvim || failed_installs+=("nvim")

    # 显示失败的安装
    if [ ${#failed_installs[@]} -gt 0 ]; then
      echo ""
      warn "以下工具安装失败："
      for tool in "${failed_installs[@]}"; do
        echo "  - $tool"
      done
      echo ""
    fi
  else
    log "跳过工具安装 (SKIP_INSTALL=1)"
    echo ""
  fi

  echo ""
  info "正在部署 dotfile 仓库..."

  # 检查是否已存在 dotfile 仓库
  if [ -d "$DOT_DIR" ]; then
    warn ".dotfile 目录已存在，将更新而非重新克隆"
    # 使用现有的 dotfile
    dot() {
      git --git-dir="$DOT_DIR" --work-tree="$HOME" "$@"
    }
    # 拉取最新更新
    log "正在更新 dotfile 仓库..."
    dot fetch origin >/dev/null 2>&1 || warn "更新失败，将继续使用现有版本"
  else
    # 克隆新的仓库
    if ! git clone --bare "$REPO_URL" "$DOT_DIR" >/dev/null 2>&1; then
      error "无法克隆 dotfile 仓库，请检查网络连接或仓库地址"
    fi

    # 定义 dot 命令函数（避免依赖 alias）
    dot() {
      git --git-dir="$DOT_DIR" --work-tree="$HOME" "$@"
    }
  fi

  # 定义 dot 命令函数（避免依赖 alias）
  dot() {
    git --git-dir="$DOT_DIR" --work-tree="$HOME" "$@"
  }

  # 检查哪些文件会冲突（不执行 checkout，避免副作用）
  log "检查文件冲突..."
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
    warn "以下文件已存在，将被备份："
    mkdir -p "$BACKUP_DIR"
    for file in "${conflicts[@]}"; do
      if [ -e "$HOME/$file" ] || [ -L "$HOME/$file" ]; then
        backup_path="$BACKUP_DIR/$file"
        mkdir -p "$(dirname "$backup_path")"
        cp -a "$HOME/$file" "$backup_path"
        echo "  → $file"
      fi
    done
    log "备份已保存至: $BACKUP_DIR"
  else
    log "没有发现冲突文件。"
  fi

  # 强制检出配置（覆盖本地同名文件）
  info "正在部署 dotfile..."
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
    log "已添加 'dot' 别名到 $SHELL_RC"
  fi

  echo ""
  echo "=========================================="
  log "✅ Dotfile 部署完成！"
  echo "=========================================="
  echo ""

  # 验证安装
  if verify_installation; then
    log "所有工具安装成功！"
  else
    local failed_count=$?
    warn "有 $failed_count 项工具安装失败或未安装"
    warn "您可以稍后手动安装这些工具"
  fi

  echo ""
  log "后续步骤："
  echo "  1. 执行 'source $SHELL_RC' 或重启 shell 以使用 'dot' 命令"
  echo "  2. 将默认 shell 切换为 zsh: chsh -s \$(which zsh)"
  echo "  3. 启动 tmux 后按 'Ctrl+a I' (大写 I) 安装 tmux 插件"
  echo "  4. 首次启动 nvim 会自动安装插件，请耐心等待"
  echo ""

  # 提供手动安装命令
  if [ ${#failed_installs[@]} -gt 0 ]; then
    warn "手动安装失败工具的命令："
    echo ""
    for tool in "${failed_installs[@]}"; do
      case "$tool" in
        nvim)
          echo "  # 方法 1: 使用 AppImage（推荐，快速且简单）"
          echo "  ARCH=\$(uname -m)"
          echo "  if [ \"\$ARCH\" = \"x86_64\" ]; then"
          echo "    wget https://github.com/neovim/neovim/releases/latest/download/nvim-linux64.appimage"
          echo "  elif [ \"\$ARCH\" = \"aarch64\" ]; then"
          echo "    wget https://github.com/neovim/neovim/releases/latest/download/nvim-linux-arm64.appimage"
          echo "  fi"
          echo "  chmod +x nvim-*.appimage"
          echo "  sudo mv nvim-*.appimage /usr/local/bin/nvim"
          echo ""
          echo "  # 方法 2: 使用包管理器（可能版本较旧）"
          echo "  sudo apt-get update && sudo apt-get install -y neovim"
          echo ""
          echo "  # 方法 3: 从源码构建（最灵活，但耗时较长）"
          echo "  sudo apt-get install -y cmake gettext libtool libtool-bin \\"
          echo "    autoconf automake g++ pkg-config unzip curl python3-pip"
          echo "  git clone https://github.com/neovim/neovim.git"
          echo "  cd neovim && make CMAKE_BUILD_TYPE=RelWithDebInfo"
          echo "  sudo make install"
          echo ""
          ;;
        nodejs/npm)
          echo "  # 安装 Node.js 和 npm:"
          echo "  curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -"
          echo "  sudo apt-get install -y nodejs"
          echo ""
          ;;
        *)
          echo "  sudo apt-get install -y $tool"
          echo ""
          ;;
      esac
    done
  fi
}

# 运行主程序
main "$@"
