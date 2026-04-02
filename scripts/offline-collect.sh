#!/bin/bash
# offline-collect.sh - 收集离线安装所需的所有文件（二进制+依赖）

set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly DOT_DIR="$HOME/.dotfile"
readonly COLLECT_DIR="$SCRIPT_DIR/.offline_collect"
readonly CACHE_DIR="$COLLECT_DIR/cache"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

log() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1" >&2; exit 1; }
info() { echo -e "${BLUE}[STEP]${NC} $1"; }
progress() { echo -e "${CYAN}[PROGRESS]${NC} $1"; }

# ============================================================================
# 初始化
# ============================================================================

init_offline_dir() {
  log "Initializing offline collection directory..."
  rm -rf "$COLLECT_DIR"
  mkdir -p "$CACHE_DIR"/{binaries,packages,language_repos}
}

# ============================================================================
# 收集二进制文件
# ============================================================================

collect_binaries() {
  info "Collecting binary files..."

  local binaries_dir="$CACHE_DIR/binaries"
  mkdir -p "$binaries_dir"

  # 要收集的二进制文件列表
  local bins=(
    "git"
    "zsh"
    "vim"
    "nvim"
    "tmux"
    "node"
    "npm"
    "python3"
    "pip3"
    "fzf"
    "zoxide"
  )

  local collected=0
  for bin in "${bins[@]}"; do
    local bin_path=$(command -v "$bin" 2>/dev/null || true)
    if [ -n "$bin_path" ] && [ -f "$bin_path" ]; then
      # 复制二进制文件
      cp -a "$bin_path" "$binaries_dir/"
      ((collected++))

      # 收集共享库依赖
      collect_shared_libs "$bin_path" "$binaries_dir"
    fi
  done

  log "Collected $collected binaries"
}

# 收集共享库依赖
collect_shared_libs() {
  local binary="$1"
  local dest="$2"
  local libs_dir="$dest/libs"

  mkdir -p "$libs_dir"

  if command -v ldd &> /dev/null; then
    # 获取动态链接库
    ldd "$binary" 2>/dev/null | grep -o '/lib.*\.[0-9]' | while read lib; do
      if [ -f "$lib" ] && [ ! -f "$libs_dir/$(basename "$lib")" ]; then
        cp -a "$lib" "$libs_dir/" 2>/dev/null || true
      fi
    done
  fi
}

# ============================================================================
# 收集系统包的.deb/.rpm文件
# ============================================================================

collect_system_package_files() {
  info "Collecting system package files..."

  local pkg_cache="$CACHE_DIR/packages/system"

  if command -v apt-cache &> /dev/null; then
    collect_apt_packages "$pkg_cache"
  elif command -v pacman &> /dev/null; then
    collect_pacman_packages "$pkg_cache"
  fi
}

collect_apt_packages() {
  local dest="$1"
  mkdir -p "$dest"

  info "Downloading .deb packages..."

  # 获取已安装的包列表
  dpkg --get-selections | grep -v deinstall | awk '{print $1}' > /tmp/installed_pkgs.txt

  # 下载每个包的.deb文件（如果可用）
  while read pkg; do
    apt-get download "$pkg" -o Dir::State::Lists=/tmp/apt -o Dir::Cache::archives="$dest" 2>/dev/null || true
  done < /tmp/installed_pkgs.txt

  # 只保留最近的包文件
  rm -f /tmp/installed_pkgs.txt

  local count=$(ls -1 "$dest"/*.deb 2>/dev/null | wc -l)
  log "Downloaded $count .deb files"
}

collect_pacman_packages() {
  local dest="$1"
  mkdir -p "$dest"

  info "Downloading .pkg.tar.zst files..."

  # 获取显式安装的包
  pacman -Qeq > /tmp/pacman_pkgs.txt

  # 缓存目录
  local cache_dir="/var/cache/pacman/pkg"

  if [ -d "$cache_dir" ]; then
    while read pkg_name; do
      # 复制匹配的包文件
      find "$cache_dir" -name "${pkg_name}-*.pkg.tar.*" -exec cp {} "$dest/" \; 2>/dev/null || true
    done < /tmp/pacman_pkgs.txt

    local count=$(ls -1 "$dest"/*.pkg.tar.* 2>/dev/null | wc -l)
    log "Copied $count package files"
  fi

  rm -f /tmp/pacman_pkgs.txt
}

# ============================================================================
# 收集语言包管理器的离线包
# ============================================================================

collect_npm_packages() {
  if ! command -v npm &> /dev/null; then
    return
  fi

  info "Collecting npm global packages..."

  local npm_cache="$CACHE_DIR/packages/npm"
  mkdir -p "$npm_cache"

  # 获取全局安装的包
  npm list -g --depth=0 --json 2>/dev/null | \
    jq -r '.dependencies | keys[]' 2>/dev/null > "$npm_cache/package_list.txt" || \
    npm list -g --depth=0 2>/dev/null | grep -v empty | tail -n +2 | awk '{print $2}' | sed 's/@.*//' > "$npm_cache/package_list.txt" || true

  # 下载每个包的tarball（不安装）
  while read pkg; do
    [ -n "$pkg" ] || continue
    progress "Downloading $pkg..."
    npm pack "$pkg" --pack-location="$npm_cache" &>/dev/null || true
  done < "$npm_cache/package_list.txt"

  local count=$(ls -1 "$npm_cache"/*.tgz 2>/dev/null | wc -l)
  log "Collected $count npm packages"
}

collect_pip_packages() {
  if ! command -v pip3 &> /dev/null; then
    return
  fi

  info "Collecting Python packages..."

  local pip_cache="$CACHE_DIR/packages/pip"
  mkdir -p "$pip_cache"

  # 下载所有已安装包的wheel文件
  pip3 list --format=freeze 2>/dev/null > "$pip_cache/requirements.txt" || true

  if [ -s "$pip_cache/requirements.txt" ]; then
    # 下载wheel文件但不安装
    pip3 download -r "$pip_cache/requirements.txt" -d "$pip_cache" &>/dev/null || true

    local count=$(ls -1 "$pip_cache"/*.whl 2>/dev/null | wc -l)
    log "Collected $count Python packages"
  fi
}

collect_cargo_crates() {
  if ! command -v cargo &> /dev/null; then
    return
  fi

  info "Collecting Cargo crates..."

  local cargo_cache="$CACHE_DIR/packages/cargo"
  mkdir -p "$cargo_cache"

  # 获取已安装的crates
  cargo install --list 2>/dev/null | awk '{print $1}' | sed 's/:$//' > "$cargo_cache/crate_list.txt" || true

  # 下载crates（离线安装需要源码）
  while read crate; do
    [ -n "$crate" ] || continue
    progress "Downloading $crate..."
    cargo download "$crate" --output-directory "$cargo_cache" &>/dev/null || true
  done < "$cargo_cache/crate_list.txt"

  local count=$(ls -1 "$cargo_cache"/*.crate 2>/dev/null | wc -l)
  log "Collected $count Cargo crates"
}

# ============================================================================
# 收集 LazyVim / Mason 工具
# ============================================================================

collect_lazyvim_mason_packages() {
  local mason_dir="$HOME/.local/share/nvim/mason"

  if [ ! -d "$mason_dir" ]; then
    warn "LazyVim Mason directory not found, skipping Mason packages"
    return
  fi

  info "Collecting LazyVim Mason packages..."

  local mason_cache="$CACHE_DIR/packages/mason"
  local packages_dir="$mason_cache/packages"
  local bin_dir="$mason_cache/bin"
  local collected=0
  local packages=(
    "taplo"
    "marksman"
  )

  mkdir -p "$packages_dir" "$bin_dir"

  for pkg in "${packages[@]}"; do
    if [ -d "$mason_dir/packages/$pkg" ]; then
      cp -a "$mason_dir/packages/$pkg" "$packages_dir/"
      ((collected++))
    else
      warn "Mason package not found: $pkg"
    fi

    if [ -e "$mason_dir/bin/$pkg" ]; then
      cp -a "$mason_dir/bin/$pkg" "$bin_dir/"
    fi
  done

  log "Collected $collected Mason packages"
}

# ============================================================================
# 收集插件仓库
# ============================================================================

collect_plugin_repos() {
  info "Collecting plugin repositories..."

  local repos_dir="$CACHE_DIR/language_repos"
  mkdir -p "$repos_dir"/{zsh,vim,tmux}

  # Clone zsh插件
  if [ -d "$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions" ]; then
    git clone --local "$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions" "$repos_dir/zsh/zsh-autosuggestions" 2>/dev/null || true
  fi

  if [ -d "$HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting" ]; then
    git clone --local "$HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting" "$repos_dir/zsh/zsh-syntax-highlighting" 2>/dev/null || true
  fi

  # Clone TPM
  if [ -d "$HOME/.tmux/plugins/tpm" ]; then
    git clone --local "$HOME/.tmux/plugins/tpm" "$repos_dir/tmux/tpm" 2>/dev/null || true
  fi

  # Clone fzf
  if [ -d "$HOME/.fzf" ]; then
    git clone --local "$HOME/.fzf" "$repos_dir/fzf" 2>/dev/null || true
  fi

  log "Plugin repositories collected"
}

# ============================================================================
# 生成离线安装脚本
# ============================================================================

generate_offline_installer() {
  info "Generating offline installer script..."

  cat > "$COLLECT_DIR/offline-install.sh" << 'INSTALLER_EOF'
#!/bin/bash
# Offline Dotfile Installer
# 完全离线环境安装

set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly CACHE_DIR="$SCRIPT_DIR/cache"
readonly BACKUP_DIR="$HOME/.dotfile_backup_$(date +%Y%m%d_%H%M%S)"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1" >&2; }
info() { echo -e "${BLUE}[STEP]${NC} $1"; }

# ============================================================================
# 安装二进制文件
# ============================================================================

install_binaries() {
  info "Installing binaries..."

  local bin_dir="$CACHE_DIR/binaries"
  local local_bin="$HOME/.local/bin"

  mkdir -p "$local_bin"

  # 复制二进制文件
  for bin in "$bin_dir"/*; do
    [ -f "$bin" ] || continue
    local name=$(basename "$bin")

    if [ ! -f "$local_bin/$name" ]; then
      cp -a "$bin" "$local_bin/"
      chmod +x "$local_bin/$name"
      log "  → $name"
    fi
  done

  # 设置PATH
  if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
    warn "Adding $HOME/.local/bin to PATH"
    export PATH="$HOME/.local/bin:$PATH"
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.zshrc"
  fi

  log "Binaries installed"
}

# ============================================================================
# 安装系统包
# ============================================================================

install_system_packages() {
  info "Installing system packages..."

  local pkg_dir="$CACHE_DIR/packages/system"

  if [ -d "$pkg_dir" ] && [ "$(ls -A "$pkg_dir")" ]; then
    if command -v dpkg &> /dev/null; then
      # Debian/Ubuntu
      for deb in "$pkg_dir"/*.deb; do
        [ -f "$deb" ] || continue
        info "Installing $(basename "$deb")..."
        sudo dpkg -i "$deb" || sudo apt-get install -f -y
      done
    elif command -v pacman &> /dev/null; then
      # Arch Linux
      for pkg in "$pkg_dir"/*.pkg.tar.*; do
        [ -f "$pkg" ] || continue
        info "Installing $(basename "$pkg")..."
        sudo pacman -U --noconfirm "$pkg" || true
      done
    fi
  else
    warn "No system packages found"
  fi
}

# ============================================================================
# 安装npm包
# ============================================================================

install_npm_packages() {
  if ! command -v npm &> /dev/null; then
    warn "npm not available, skipping npm packages"
    return
  fi

  info "Installing npm packages..."

  local npm_dir="$CACHE_DIR/packages/npm"

  if [ -d "$npm_dir" ]; then
    for tgz in "$npm_dir"/*.tgz; do
      [ -f "$tgz" ] || continue
      info "Installing $(basename "$tgz")..."
      npm install -g "$tgz" --force || true
    done
  fi
}

# ============================================================================
# 安装Python包
# ============================================================================

install_pip_packages() {
  if ! command -v pip3 &> /dev/null; then
    warn "pip3 not available, skipping Python packages"
    return
  fi

  info "Installing Python packages..."

  local pip_dir="$CACHE_DIR/packages/pip"

  if [ -d "$pip_dir" ]; then
    for whl in "$pip_dir"/*.whl; do
      [ -f "$whl" ] || continue
      info "Installing $(basename "$whl")..."
      pip3 install --no-deps "$whl" || true
    done
  fi
}

# ============================================================================
# 安装 LazyVim / Mason 工具
# ============================================================================

install_mason_packages() {
  info "Installing LazyVim Mason packages..."

  local mason_cache="$CACHE_DIR/packages/mason"
  local mason_home="$HOME/.local/share/nvim/mason"
  local mason_packages="$mason_cache/packages"
  local mason_bin="$mason_cache/bin"
  local installed=0

  if [ ! -d "$mason_cache" ]; then
    warn "No Mason packages found"
    return
  fi

  mkdir -p "$mason_home/packages" "$mason_home/bin"

  if [ -d "$mason_packages" ]; then
    for pkg in "$mason_packages"/*; do
      [ -d "$pkg" ] || continue
      local name=$(basename "$pkg")
      local target="$mason_home/packages/$name"

      rm -rf "$target"
      cp -a "$pkg" "$target"
      ((installed++))
      log "  → mason package: $name"
    done
  fi

  if [ -d "$mason_bin" ]; then
    for bin in "$mason_bin"/*; do
      [ -e "$bin" ] || continue
      local name=$(basename "$bin")
      local target="$mason_home/bin/$name"

      rm -f "$target"
      cp -a "$bin" "$target"
      chmod +x "$target" 2>/dev/null || true
    done
  fi

  log "Installed $installed Mason packages"
}

# ============================================================================
# 安装插件仓库
# ============================================================================

install_plugins() {
  info "Installing plugin repositories..."

  local repos_dir="$CACHE_DIR/language_repos"

  # Zsh插件
  if [ -d "$repos_dir/zsh" ]; then
    mkdir -p "$HOME/.oh-my-zsh/custom/plugins"

    for plugin in "$repos_dir/zsh"/*; do
      [ -d "$plugin" ] || continue
      local name=$(basename "$plugin")
      local target="$HOME/.oh-my-zsh/custom/plugins/$name"

      if [ ! -d "$target" ]; then
        cp -a "$plugin" "$target"
        log "  → zsh plugin: $name"
      fi
    done
  fi

  # Tmux插件
  if [ -d "$repos_dir/tmux/tpm" ]; then
    mkdir -p "$HOME/.tmux/plugins"
    if [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
      cp -a "$repos_dir/tmux/tpm" "$HOME/.tmux/plugins/"
      log "  → tmux plugin manager"
    fi
  fi

  # fzf
  if [ -d "$repos_dir/fzf" ]; then
    if [ ! -d "$HOME/.fzf" ]; then
      cp -a "$repos_dir/fzf" "$HOME/.fzf"
      log "  → fzf"
    fi
  fi
}

# ============================================================================
# 主安装流程
# ============================================================================

main() {
  echo ""
  echo "=========================================="
  echo "  Offline Dotfile Installer"
  echo "=========================================="
  echo ""

  info "Starting offline installation..."
  echo ""

  # 1. 安装二进制
  install_binaries
  echo ""

  # 2. 安装系统包
  install_system_packages
  echo ""

  # 3. 安装语言包
  install_npm_packages
  install_pip_packages
  install_mason_packages
  echo ""

  # 4. 安装插件
  install_plugins
  echo ""

  echo ""
  log "✅ Offline installation complete!"
  echo ""
  log "Next steps:"
  echo "  1. Reload shell: exec zsh"
  echo "  2. Run: dot status"
  echo ""
}

main "$@"
INSTALLER_EOF

  chmod +x "$COLLECT_DIR/offline-install.sh"
  log "Offline installer generated"
}

# ============================================================================
# 生成清单
# ============================================================================

generate_manifest() {
  info "Generating manifest..."

  {
    echo "=== OFFLINE PACKAGE MANIFEST ==="
    echo "Generated: $(date)"
    echo ""

    echo "=== Binaries ==="
    ls -1 "$CACHE_DIR/binaries" 2>/dev/null | wc -l
    echo ""

    echo "=== System Packages ==="
    if [ -d "$CACHE_DIR/packages/system" ]; then
      echo "Debian/Ubuntu: $(ls -1 "$CACHE_DIR/packages/system"/*.deb 2>/dev/null | wc -l)"
      echo "Arch: $(ls -1 "$CACHE_DIR/packages/system"/*.pkg.tar.* 2>/dev/null | wc -l)"
    fi
    echo ""

    echo "=== Language Packages ==="
    echo "npm: $(ls -1 "$CACHE_DIR/packages/npm"/*.tgz 2>/dev/null | wc -l)"
    echo "pip: $(ls -1 "$CACHE_DIR/packages/pip"/*.whl 2>/dev/null | wc -l)"
    echo "cargo: $(ls -1 "$CACHE_DIR/packages/cargo"/*.crate 2>/dev/null | wc -l)"
    echo "mason: $(find "$CACHE_DIR/packages/mason/packages" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l)"
    echo ""

    echo "=== Total Size ==="
    du -sh "$CACHE_DIR" 2>/dev/null
  } > "$COLLECT_DIR/MANIFEST.txt"

  cat "$COLLECT_DIR/MANIFEST.txt"
}

# ============================================================================
# 主函数
# ============================================================================

main() {
  echo ""
  echo "=========================================="
  echo "  Offline Package Collection Tool"
  echo "=========================================="
  echo ""

  init_offline_dir
  collect_binaries
  collect_system_package_files
  collect_npm_packages
  collect_pip_packages
  collect_cargo_crates
  collect_lazyvim_mason_packages
  collect_plugin_repos
  generate_offline_installer
  generate_manifest

  echo ""
  log "✅ Offline collection complete!"
  echo ""
  log "Output directory: $COLLECT_DIR"
  log "Total size: $(du -sh "$COLLECT_DIR" | cut -f1)"
  echo ""

  log "Next steps:"
  echo "  1. Review collected files in $COLLECT_DIR"
  echo "  2. Run: bash $SCRIPT_DIR/offline-package.sh"
  echo ""
}

main "$@"
