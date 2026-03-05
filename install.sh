#!/bin/bash
# dotfile-manager.sh - Unified dotfile installation and removal management
# Usage: bash dotfile-manager.sh [install|uninstall] [options]
#
# Environment variables for install:
#   DRY_RUN=1       - Preview operations without executing
#   SKIP_INSTALL=1  - Deploy dotfiles only, skip tool installation
#
# Environment variables for uninstall:
#   NO_BACKUP=1     - Skip creating backup before removal

set -euo pipefail

# ============================================================================
# CONFIGURATION
# ============================================================================

readonly REPO_URL="https://github.com/nbfhscl/dotfile.git"
readonly DOT_DIR="$HOME/.dotfile"
readonly ALIAS_NAME="dot"
readonly SCRIPT_NAME="$(basename "$0")"

# Runtime configuration
BACKUP_DIR=""
DRY_RUN="${DRY_RUN:-}"
SKIP_INSTALL="${SKIP_INSTALL:-}"
NO_BACKUP="${NO_BACKUP:-}"
ACTION=""

# Colors
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

# ============================================================================
# LOGGING FUNCTIONS
# ============================================================================

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

info() {
  echo -e "${BLUE}[STEP]${NC} $1"
}

warn_error() {
  echo -e "${RED}[ERROR]${NC} $1" >&2
}

# ============================================================================
# PLATFORM DETECTION
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

check_sudo() {
  if ! sudo -v &>/dev/null; then
    return 1
  fi
  return 0
}

detect_architecture() {
  local arch=$(uname -m)
  case "$arch" in
    x86_64|amd64) echo "x86_64" ;;
    aarch64|arm64) echo "arm64" ;;
    *) echo "unknown" ;;
  esac
}

# ============================================================================
# DOTFILE REPOSITORY OPERATIONS
# ============================================================================

dot() {
  git --git-dir="$DOT_DIR" --work-tree="$HOME" "$@"
}

init_dotfile_repo() {
  if [ -d "$DOT_DIR" ]; then
    warn ".dotfile directory exists, updating instead of cloning"
    log "Updating dotfile repository..."
    dot fetch origin >/dev/null 2>&1 || warn "Update failed, using existing version"
  else
    if ! git clone --bare "$REPO_URL" "$DOT_DIR" >/dev/null 2>&1; then
      error "Failed to clone dotfile repository"
    fi
  fi
}

backup_conflicting_files() {
  local conflicts=()
  local tracked_files

  log "Checking for conflicting files..."
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
    BACKUP_DIR="$HOME/.dotfile_backup_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$BACKUP_DIR"
    warn "Backing up existing files to: $BACKUP_DIR"
    for file in "${conflicts[@]}"; do
      if [ -e "$HOME/$file" ] || [ -L "$HOME/$file" ]; then
        local backup_path="$BACKUP_DIR/$file"
        mkdir -p "$(dirname "$backup_path")"
        cp -a "$HOME/$file" "$backup_path"
        echo "  → $file"
      fi
    done
    log "Backup completed"
  else
    log "No conflicting files found"
  fi
}

deploy_dotfiles() {
  info "Deploying dotfiles..."
  dot checkout -f >/dev/null 2>&1
  dot config --local status.showUntrackedFiles no
}

install_shell_alias() {
  local shell_rc
  local shell_name

  shell_name="$(basename "${SHELL:-}")"

  case "$shell_name" in
    zsh) shell_rc="$HOME/.zshrc" ;;
    bash) shell_rc="$HOME/.bashrc" ;;
    *) shell_rc="$HOME/.profile" ;;
  esac

  if ! grep -q "alias $ALIAS_NAME=" "$shell_rc" 2>/dev/null; then
    echo "alias $ALIAS_NAME='git --git-dir=\$HOME/.dotfile/ --work-tree=\$HOME'" >> "$shell_rc"
    log "Added '$ALIAS_NAME' alias to $shell_rc"
  fi
}

remove_shell_alias() {
  local rc_file="$1"
  [ -f "$rc_file" ] || return 0

  if grep -q "alias $ALIAS_NAME='git --git-dir=\$HOME/.dotfile/ --work-tree=\$HOME'" "$rc_file"; then
    sed -i "\|alias $ALIAS_NAME='git --git-dir=\$HOME/.dotfile/ --work-tree=\$HOME'|d" "$rc_file"
    log "Removed '$ALIAS_NAME' alias from $rc_file"
  fi
}

# ============================================================================
# PACKAGE INSTALLATION
# ============================================================================

install_package() {
  local pkg=$1
  local pm=$(detect_package_manager)

  if [ -n "$DRY_RUN" ]; then
    info "[DRY-RUN] Would install $pkg (using $pm)"
    return 0
  fi

  if [[ "$pm" != "brew" ]] && ! check_sudo; then
    warn_error "Sudo required for $pkg, skipping..."
    return 1
  fi

  case "$pm" in
    apt)
      sudo apt-get update -qq && sudo apt-get install -y "$pkg"
      ;;
    yum|dnf)
      sudo "$pm" install -y "$pkg"
      ;;
    pacman)
      sudo pacman -S --noconfirm "$pkg"
      ;;
    brew)
      brew install "$pkg"
      ;;
    zypper)
      sudo zypper install -y "$pkg"
      ;;
    *)
      warn_error "Unrecognized package manager for $pkg"
      return 1
      ;;
  esac
}

# ============================================================================
# TOOL INSTALLATION FUNCTIONS
# ============================================================================

install_tool() {
  local tool_name=$1
  local package_name=${2:-$1}
  local install_function=${3:-}

  if command -v "$tool_name" &> /dev/null; then
    log "✓ $tool_name already installed"
    return 0
  fi

  info "Installing $tool_name..."
  if [ -n "$install_function" ]; then
    if $install_function; then
      log "✓ $tool_name installation completed"
      return 0
    else
      warn_error "✗ $tool_name installation failed"
      return 1
    fi
  else
    if install_package "$package_name"; then
      log "✓ $tool_name installation completed"
      return 0
    else
      warn_error "✗ $tool_name installation failed"
      return 1
    fi
  fi
}

install_oh_my_zsh_custom() {
  [ ! -d "$HOME/.oh-my-zsh" ] || return 0

  if sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended 2>/dev/null; then
    return 0
  fi
  return 1
}

install_zsh_plugin() {
  local plugin_name=$1
  local plugin_url=$2
  local plugins_dir="$HOME/.oh-my-zsh/custom/plugins"

  mkdir -p "$plugins_dir"

  if [ -d "$plugins_dir/$plugin_name" ]; then
    log "✓ $plugin_name already installed"
    return 0
  fi

  info "Installing $plugin_name..."
  if git clone "$plugin_url" "$plugins_dir/$plugin_name" 2>/dev/null; then
    log "✓ $plugin_name installation completed"
    return 0
  else
    warn_error "✗ $plugin_name installation failed"
    return 1
  fi
}

install_zsh_plugins() {
  install_zsh_plugin "zsh-autosuggestions" "https://github.com/zsh-users/zsh-autosuggestions"
  install_zsh_plugin "zsh-syntax-highlighting" "https://github.com/zsh-users/zsh-syntax-highlighting"
}

install_zoxide_custom() {
  local pm=$(detect_package_manager)

  case "$pm" in
    apt)
      curl -fsSL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash 2>/dev/null
      ;;
    brew)
      brew install zoxide 2>/dev/null
      ;;
    *)
      if command -v cargo &> /dev/null; then
        cargo install zoxide 2>/dev/null
      else
        return 1
      fi
      ;;
  esac
}

install_fzf_custom() {
  local pm=$(detect_package_manager)

  case "$pm" in
    apt)
      install_package "fzf" 2>/dev/null
      ;;
    brew)
      brew install fzf 2>/dev/null
      ;;
    *)
      if [ ! -d "$HOME/.fzf" ]; then
        if git clone --depth 1 https://github.com/junegunn/fzf.git "$HOME/.fzf" 2>/dev/null; then
          "$HOME/.fzf/install" --all 2>/dev/null
        fi
      fi
      ;;
  esac
}

install_tpm_custom() {
  local tpm_dir="$HOME/.tmux/plugins/tpm"

  [ -d "$tpm_dir" ] && return 0

  mkdir -p "$HOME/.tmux/plugins"
  if git clone https://github.com/tmux-plugins/tpm "$tpm_dir" 2>/dev/null; then
    return 0
  fi
  return 1
}

# ============================================================================
# NEOVIM INSTALLATION
# ============================================================================

get_nvim_version() {
  if command -v nvim &> /dev/null; then
    local version_output=$(nvim --version 2>/dev/null | head -1)
    local version=$(echo "$version_output" | sed -n 's/.*NVIM v\([0-9]*\.[0-9]*\.[0-9]*\).*/\1/p' 2>/dev/null)
    echo "${version:-0.0.0}"
  else
    echo "0.0.0"
  fi
}

version_ge() {
  local v1=$1
  local v2=$2

  if ! [[ "$v1" =~ ^[0-9]+(\.[0-9]+)*$ ]] || ! [[ "$v2" =~ ^[0-9]+(\.[0-9]+)*$ ]]; then
    return 1
  fi

  IFS='.' read -ra v1_parts <<< "$v1"
  IFS='.' read -ra v2_parts <<< "$v2"

  local max_len=${#v1_parts[@]}
  [ ${#v2_parts[@]} -gt $max_len ] && max_len=${#v2_parts[@]}

  for ((i=0; i<max_len; i++)); do
    local n1=$((10#${v1_parts[$i]:-0}))
    local n2=$((10#${v2_parts[$i]:-0}))
    if (( n1 > n2 )); then
      return 0
    elif (( n1 < n2 )); then
      return 1
    fi
  done
  return 0
}

get_latest_nvim_version() {
  local api_url="https://api.github.com/repos/neovim/neovim/releases/latest"
  local timeout=10
  local response

  if command -v curl &> /dev/null; then
    response=$(curl -fsSL --max-time "$timeout" "$api_url" 2>/dev/null)
  elif command -v wget &> /dev/null; then
    response=$(wget -qO- --timeout="$timeout" "$api_url" 2>/dev/null)
  else
    echo "unknown"
    return 1
  fi

  [ -z "$response" ] && echo "unknown" && return 1

  local version=$(echo "$response" | grep -oE '"tag_name":\s*"v?[0-9]+\.[0-9]+\.[0-9]+"' | sed 's/.*"v\?\([0-9.]*\)".*/\1/' | head -1)

  echo "${version:-unknown}"
}

install_nvim_appimage() {
  local arch=$(detect_architecture)
  [ "$arch" = "unknown" ] && return 1

  local latest_version=$(get_latest_nvim_version)
  [ "$latest_version" = "unknown" ] && return 1

  info "Downloading Neovim $latest_version (AppImage, $arch)..."

  local appimage_url="https://github.com/neovim/neovim/releases/download/v${latest_version}/nvim-linux-${arch}.appimage"
  local temp_file="/tmp/nvim.appimage"

  if command -v curl &> /dev/null; then
    curl -fL --progress-bar "$appimage_url" -o "$temp_file" 2>/dev/null || return 1
  elif command -v wget &> /dev/null; then
    wget --progress=bar:force "$appimage_url" -O "$temp_file" 2>/dev/null || return 1
  else
    return 1
  fi

  [ ! -s "$temp_file" ] && return 1

  local file_size=$(stat -c%s "$temp_file" 2>/dev/null || stat -f%z "$temp_file" 2>/dev/null)
  [ "$file_size" -lt 50000000 ] && return 1

  chmod +x "$temp_file"

  if ! check_sudo; then
    return 1
  fi

  if sudo mv "$temp_file" /usr/local/bin/nvim 2>/dev/null; then
    if /usr/local/bin/nvim --version &>/dev/null; then
      return 0
    fi
  fi
  return 1
}

install_nvim_brew() {
  brew install neovim 2>/dev/null
}

verify_nvim_version() {
  if ! command -v nvim &> /dev/null; then
    error "Neovim installation verification failed"
  fi

  local version=$(get_nvim_version)
  info "Installed Neovim version: $version"

  if ! version_ge "$version" "0.9.0"; then
    error "Neovim version too old ($version < 0.9.0)"
  fi

  log "✓ Neovim version verified ($version ≥ 0.9.0)"
}

install_nvim() {
  local os=$(detect_os)
  local current_version=$(get_nvim_version)

  if version_ge "$current_version" "0.9.0"; then
    log "✓ Neovim already installed (version $current_version ≥ 0.9.0)"
    return 0
  fi

  [ "$current_version" != "0.0.0" ] && warn "Detected Neovim $current_version < 0.9.0, upgrading..."

  info "Installing Neovim (requires ≥ 0.9.0)..."

  if [ "$os" = "macos" ]; then
    install_nvim_brew || return 1
  else
    if [ -z "$DRY_RUN" ]; then
      install_nvim_appimage || return 1
    fi
  fi

  [ -z "$DRY_RUN" ] && verify_nvim_version
}

install_nodejs_npm_custom() {
  local pm=$(detect_package_manager)

  case "$pm" in
    apt)
      if check_sudo; then
        curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash - 2>/dev/null
        install_package "nodejs"
      fi
      ;;
    brew)
      brew install node 2>/dev/null
      ;;
    *)
      install_package "nodejs"
      ;;
  esac
}

# ============================================================================
# INSTALLATION VERIFICATION
# ============================================================================

verify_installation() {
  log ""
  log "Verifying installation..."

  local failed=0
  local tools=("git" "zsh" "vim" "nvim" "tmux" "node" "npm")

  for tool in "${tools[@]}"; do
    if command -v "$tool" &> /dev/null; then
      log "  ✓ $tool installed"
    else
      warn "  ✗ $tool not installed"
      ((failed++))
    fi
  done

  [ -d "$HOME/.oh-my-zsh" ] && log "  ✓ oh-my-zsh installed" || ((failed++))
  [ -d "$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions" ] && log "  ✓ zsh-autosuggestions installed" || ((failed++))
  [ -d "$HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting" ] && log "  ✓ zsh-syntax-highlighting installed" || ((failed++))
  [ -d "$HOME/.tmux/plugins/tpm" ] && log "  ✓ TPM installed" || ((failed++))
  command -v zoxide &> /dev/null && log "  ✓ zoxide installed" || ((failed++))
  command -v fzf &> /dev/null && log "  ✓ fzf installed" || ((failed++))

  return $failed
}

# ============================================================================
# INSTALLATION WORKFLOW
# ============================================================================

run_installation() {
  echo ""
  echo "=========================================="
  echo "  Dotfile Installation"
  echo "=========================================="
  echo ""

  [ -n "$DRY_RUN" ] && warn "DRY-RUN mode: Previewing operations only" && echo ""

  local os=$(detect_os)
  local pm=$(detect_package_manager)
  log "Detected OS: $os"
  log "Detected package manager: $pm"
  echo ""

  [ "$pm" = "unknown" ] || [ "$pm" = "none" ] && error "Unrecognized package manager"

  # Install tools if not skipped
  if [ -z "$SKIP_INSTALL" ]; then
    info "Installing required tools..."
    echo ""

    local -a failed_installs=()

    # Core tools
    install_tool "git" || failed_installs+=("git")
    install_tool "zsh" || failed_installs+=("zsh")
    install_tool "vim" || failed_installs+=("vim")
    install_tool "node" "nodejs" "install_nodejs_npm_custom" || failed_installs+=("nodejs/npm")

    # Zsh ecosystem
    install_tool "oh-my-zsh" "oh-my-zsh" "install_oh_my_zsh_custom" || failed_installs+=("oh-my-zsh")
    install_zsh_plugins || failed_installs+=("zsh-plugins")
    install_tool "zoxide" "zoxide" "install_zoxide_custom" || failed_installs+=("zoxide")
    install_tool "fzf" "fzf" "install_fzf_custom" || failed_installs+=("fzf")

    # Tmux ecosystem
    install_tool "tmux" || failed_installs+=("tmux")
    install_tool "tpm" "tpm" "install_tpm_custom" || failed_installs+=("tpm")

    # Neovim
    install_nvim || failed_installs+=("nvim")

    if [ ${#failed_installs[@]} -gt 0 ]; then
      echo ""
      warn "Failed to install:"
      for tool in "${failed_installs[@]}"; do
        echo "  - $tool"
      done
      echo ""
    fi
  else
    log "Skipping tool installation (SKIP_INSTALL=1)"
    echo ""
  fi

  # Deploy dotfiles
  echo ""
  info "Deploying dotfile repository..."
  init_dotfile_repo
  backup_conflicting_files
  deploy_dotfiles
  install_shell_alias

  echo ""
  echo "=========================================="
  log "✅ Dotfile deployment complete!"
  echo "=========================================="
  echo ""

  # Verify installation
  if verify_installation; then
    log "All tools installed successfully!"
  else
    local failed_count=$?
    warn "$failed_count tools failed to install"
  fi

  echo ""
  log "Next steps:"
  echo "  1. Run 'source ~/.zshrc' or restart shell"
  echo "  2. Change default shell: chsh -s \$(which zsh)"
  echo "  3. Install tmux plugins: Press 'Ctrl+a I' in tmux"
  echo "  4. Open nvim to install plugins automatically"
  echo ""

  if [ -n "$BACKUP_DIR" ]; then
    log "Backup saved to: $BACKUP_DIR"
  fi
}

# ============================================================================
# UNINSTALLATION WORKFLOW
# ============================================================================

run_uninstallation() {
  echo ""
  echo "=========================================="
  echo "  Dotfile Uninstallation"
  echo "=========================================="
  echo ""

  command -v git >/dev/null 2>&1 || error "Git is not installed"
  [ -d "$DOT_DIR" ] || error "No .dotfile repository found at $DOT_DIR"
  dot rev-parse --is-bare-repository >/dev/null 2>&1 || error "Invalid bare repository at $DOT_DIR"

  log "Collecting tracked files..."
  local tracked_files
  tracked_files="$(dot ls-tree -r --name-only HEAD || true)"

  if [ -n "$tracked_files" ]; then
    if [ -z "$NO_BACKUP" ]; then
      BACKUP_DIR="$HOME/.dotfile_uninstall_backup_$(date +%Y%m%d_%H%M%S)"
      mkdir -p "$BACKUP_DIR"
      log "Backing up to: $BACKUP_DIR"
    fi

    while IFS= read -r file; do
      [ -n "$file" ] || continue
      local src="$HOME/$file"
      if [ -e "$src" ] || [ -L "$src" ]; then
        if [ -z "$NO_BACKUP" ]; then
          local dst="$BACKUP_DIR/$file"
          mkdir -p "$(dirname "$dst")"
          cp -a "$src" "$dst"
        fi
        rm -rf "$src"
        echo "  → removed $file"
      fi
    done <<< "$tracked_files"
  else
    warn "No tracked files found"
  fi

  log "Removing bare repository..."
  rm -rf "$DOT_DIR"

  remove_shell_alias "$HOME/.zshrc"
  remove_shell_alias "$HOME/.bashrc"
  remove_shell_alias "$HOME/.profile"

  echo ""
  log "Dotfile uninstalled successfully"
  if [ -n "$BACKUP_DIR" ]; then
    log "Backup saved to: $BACKUP_DIR"
  fi
  echo ""
}

# ============================================================================
# HELP AND USAGE
# ============================================================================

show_help() {
  cat << EOF
Usage: bash $SCRIPT_NAME <action> [options]

Actions:
  install     Install dotfiles and required tools
  uninstall   Remove dotfiles (creates backup by default)

Install Options:
  DRY_RUN=1        Preview operations without executing
  SKIP_INSTALL=1   Deploy dotfiles only, skip tool installation

Uninstall Options:
  NO_BACKUP=1      Skip creating backup before removal

Environment Variables:
  REPO_URL         Dotfile repository URL
  DOT_DIR          Dotfile storage directory (default: \$HOME/.dotfile)

Examples:
  # Install everything
  bash $SCRIPT_NAME install

  # Preview installation
  DRY_RUN=1 bash $SCRIPT_NAME install

  # Deploy dotfiles only
  SKIP_INSTALL=1 bash $SCRIPT_NAME install

  # Uninstall with backup
  bash $SCRIPT_NAME uninstall

  # Uninstall without backup
  NO_BACKUP=1 bash $SCRIPT_NAME uninstall

EOF
}

# ============================================================================
# MAIN ENTRY POINT
# ============================================================================

main() {
  case "${1:-}" in
    install)
      ACTION="install"
      ;;
    uninstall)
      ACTION="uninstall"
      ;;
    -h|--help|help|"")
      show_help
      exit 0
      ;;
    *)
      error "Unknown action: ${1:-}
Use 'install' or 'uninstall'
Run '$SCRIPT_NAME --help' for usage information"
      ;;
  esac

  if [ "$ACTION" = "install" ]; then
    run_installation
  elif [ "$ACTION" = "uninstall" ]; then
    run_uninstallation
  fi
}

main "$@"
