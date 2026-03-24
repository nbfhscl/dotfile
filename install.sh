#!/bin/bash
# dotfile-manager.sh - Unified dotfile installation and removal management
#
# REMOTE INSTALL (one-click):
#   curl -fsSL https://raw.githubusercontent.com/nbfhscl/dotfile/refs/heads/master/install.sh | bash
#   curl -fsSL https://raw.githubusercontent.com/nbfhscl/dotfile/refs/heads/master/install.sh | bash -s -- deploy
#
# LOCAL INSTALL:
#   bash install.sh [install|deploy|update|status|verify|package|offline-deploy|uninstall|reinstall]
#
# Environment variables for install:
#   DRY_RUN=1           - Preview operations without executing
#   SKIP_INSTALL=1      - Deploy dotfiles only, skip tool installation
#   AUTO_SWITCH_SHELL=1 - Automatically switch default shell to zsh
#
# Environment variables for uninstall:
#   NO_BACKUP=1         - Skip creating backup before removal

# ============================================================================
# REMOTE EXECUTION HANDLER
# ============================================================================
# NOTE: This check must happen BEFORE 'set -euo pipefail' because
# BASH_SOURCE[0] is unset in pipe mode, which would cause an error.

# Detect if script is being executed via pipe (curl | bash)
# In pipe mode: BASH_SOURCE[0] is empty, $0 is "bash"
# In direct mode: BASH_SOURCE[0] is the script path
if [[ -z "${BASH_SOURCE[0]:-}" ]]; then
    # Remote execution mode
    readonly _REMOTE_REPO_URL="https://github.com/nbfhscl/dotfile.git"
    readonly _REMOTE_DOT_DIR="${DOT_DIR:-$HOME/.dotfile}"
    readonly _REMOTE_TEMP_DIR="$(mktemp -d)"

    # Get requested action (default to 'install' if not specified)
    _REMOTE_ACTION="${1:-install}"

    _remote_log() { echo -e "\033[0;32m[INFO]\033[0m $1"; }
    _remote_err() { echo -e "\033[0;31m[ERROR]\033[0m $1" >&2; }

    _remote_log "🚀 Remote install mode"
    _remote_log "Repository: $_REMOTE_REPO_URL"

    # Check for required tools
    if ! command -v git &> /dev/null; then
        _remote_err "git is required but not installed. Please install git first."
        rm -rf "$_REMOTE_TEMP_DIR"
        exit 1
    fi

    # Clone repository to temp directory
    _remote_log "Cloning repository to temporary directory..."
    if ! git clone --depth 1 "$_REMOTE_REPO_URL" "$_REMOTE_TEMP_DIR/dotfile" 2>/dev/null; then
        _remote_err "Failed to clone repository"
        rm -rf "$_REMOTE_TEMP_DIR"
        exit 1
    fi

    # Execute the install script from temp directory
    _remote_log "Executing installation from: $_REMOTE_TEMP_DIR/dotfile/install.sh"
    cd "$_REMOTE_TEMP_DIR/dotfile"

    # Execute with original arguments
    exec bash "$_REMOTE_TEMP_DIR/dotfile/install.sh" "$_REMOTE_ACTION"
fi

# Enable strict mode after remote execution check
set -euo pipefail

# ============================================================================
# CONFIGURATION
# ============================================================================

readonly REPO_URL="https://github.com/nbfhscl/dotfile.git"
readonly DOT_DIR="$HOME/.dotfile"
readonly ALIAS_NAME="dot"
readonly SCRIPT_NAME="$(basename "$0")"
readonly ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$ROOT_DIR/scripts/lib/actions.sh"
source "$ROOT_DIR/scripts/lib/xdg.sh"

# ============================================================================
# DOT COMMAND WRAPPER
# ============================================================================
# Define 'dot' as a function instead of alias (aliases don't work in scripts)
# This function wraps git commands to work with the bare dotfile repository
dot() {
    git --git-dir="$DOT_DIR" --work-tree="$HOME" "$@"
}

# Runtime configuration
BACKUP_DIR=""
DRY_RUN="${DRY_RUN:-}"
SKIP_INSTALL="${SKIP_INSTALL:-}"
NO_BACKUP="${NO_BACKUP:-}"
AUTO_SWITCH_SHELL="${AUTO_SWITCH_SHELL:-}"
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

# Cross-platform sed in-place edit
sed_inplace() {
  if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS BSD sed requires empty string for backup suffix
    sed -i "" "$@"
  else
    # GNU sed (Linux)
    sed -i "$@"
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

ensure_xdg_paths() {
  init_xdg_paths
}

# ============================================================================
# XDG MIGRATION FUNCTIONS
# ============================================================================

# Migrate legacy configurations to XDG-compliant paths
migrate_to_xdg() {
  local auto_migrate="${XDG_MIGRATE:-${AUTO_MIGRATE:-0}}"

  if [[ "$auto_migrate" != "1" ]]; then
    log "XDG migration skipped (set XDG_MIGRATE=1 to enable)"
    return 0
  fi

  info "Migrating legacy configurations to XDG paths..."

  # Migrate Vim configuration
  if [[ -f "$HOME/.vimrc" && ! -L "$HOME/.vimrc" ]]; then
    local vim_xdg_dir="$XDG_CONFIG_HOME/vim"
    mkdir -p "$vim_xdg_dir"
    mv "$HOME/.vimrc" "$vim_xdg_dir/vimrc"
    ln -s "$vim_xdg_dir/vimrc" "$HOME/.vimrc"
    log "Migrated ~/.vimrc to $vim_xdg_dir/vimrc"
  fi

  # Migrate .vim directory
  if [[ -d "$HOME/.vim" && ! -L "$HOME/.vim" ]]; then
    mv "$HOME/.vim" "$XDG_CONFIG_HOME/vim"
    ln -s "$XDG_CONFIG_HOME/vim" "$HOME/.vim"
    log "Migrated ~/.vim to $XDG_CONFIG_HOME/vim"
  fi

  # Migrate Zsh configuration
  if [[ -f "$HOME/.zshrc" && ! -L "$HOME/.zshrc" ]]; then
    local zsh_xdg_dir="$XDG_CONFIG_HOME/zsh"
    mkdir -p "$zsh_xdg_dir"
    mv "$HOME/.zshrc" "$zsh_xdg_dir/.zshrc"
    # Create new .zshrc that sources XDG config
    echo "# Dotfile XDG configuration" > "$HOME/.zshrc"
    echo "source \"$zsh_xdg_dir/.zshrc\"" >> "$HOME/.zshrc"
    log "Migrated ~/.zshrc to $zsh_xdg_dir/.zshrc"
  fi

  # Migrate Bash configuration
  if [[ -f "$HOME/.bashrc" && ! -L "$HOME/.bashrc" ]]; then
    local bash_xdg_dir="$XDG_CONFIG_HOME/bash"
    mkdir -p "$bash_xdg_dir"
    mv "$HOME/.bashrc" "$bash_xdg_dir/.bashrc"
    # Create new .bashrc that sources XDG config
    echo "# Dotfile XDG configuration" > "$HOME/.bashrc"
    echo "source \"$bash_xdg_dir/.bashrc\"" >> "$HOME/.bashrc"
    log "Migrated ~/.bashrc to $bash_xdg_dir/.bashrc"
  fi

  # Migrate Tmux configuration
  if [[ -f "$HOME/.tmux.conf" && ! -L "$HOME/.tmux.conf" ]]; then
    local tmux_xdg_dir="$XDG_CONFIG_HOME/tmux"
    mkdir -p "$tmux_xdg_dir"
    mv "$HOME/.tmux.conf" "$tmux_xdg_dir/tmux.conf"
    ln -s "$tmux_xdg_dir/tmux.conf" "$HOME/.tmux.conf"
    log "Migrated ~/.tmux.conf to $tmux_xdg_dir/tmux.conf"
  fi

  log "XDG migration completed"
}

# Create XDG-compliant symlinks for backward compatibility
create_xdg_symlinks() {
  info "Creating XDG-compliant symlinks and shell configs..."

  # Vim - use symlinks for vim
  if [[ -d "$XDG_CONFIG_HOME/vim" && ! -e "$HOME/.vim" ]]; then
    ln -s "$XDG_CONFIG_HOME/vim" "$HOME/.vim"
    log "Created symlink: ~/.vim -> $XDG_CONFIG_HOME/vim"
  elif [[ -f "$XDG_CONFIG_HOME/vim/vimrc" && ! -e "$HOME/.vimrc" ]]; then
    ln -s "$XDG_CONFIG_HOME/vim/vimrc" "$HOME/.vimrc"
    log "Created symlink: ~/.vimrc -> $XDG_CONFIG_HOME/vim/vimrc"
  fi

  # Zsh - source XDG config
  if [[ -f "$XDG_CONFIG_HOME/zsh/.zshrc" ]]; then
    local zsh_rc="$HOME/.zshrc"
    local xdg_source="source \"$XDG_CONFIG_HOME/zsh/.zshrc\""

    if [[ ! -f "$zsh_rc" ]]; then
      # Create new .zshrc with XDG config sourced and shell detection
      cat > "$zsh_rc" << 'ZSH_RC_EOF'
# Dotfile XDG configuration
# Shell detection to prevent loading in incompatible shells
if [ -z "$ZSH_VERSION" ]; then
  echo "Warning: ~/.zshrc should be sourced in zsh, not ${0##*/}" >&2
  echo "If you want to use bash configuration, run: source ~/.bashrc" >&2
  return 1
fi

ZSH_RC_EOF
      echo "$xdg_source" >> "$zsh_rc"
      log "Created ~/.zshrc with XDG config sourced"
    elif ! grep -q "zsh/.zshrc" "$zsh_rc" 2>/dev/null; then
      # Append XDG source to existing .zshrc
      echo "" >> "$zsh_rc"
      echo "# Dotfile XDG configuration" >> "$zsh_rc"
      echo "# Shell detection to prevent loading in incompatible shells" >> "$zsh_rc"
      echo "if [ -z \"\$ZSH_VERSION\" ]; then" >> "$zsh_rc"
      echo "  echo \"Warning: ~/.zshrc should be sourced in zsh, not \${0##*/}\" >&2" >> "$zsh_rc"
      echo "  return 1" >> "$zsh_rc"
      echo "fi" >> "$zsh_rc"
      echo "" >> "$zsh_rc"
      echo "$xdg_source" >> "$zsh_rc"
      log "Appended XDG config source to ~/.zshrc"
    else
      log "XDG config already sourced in ~/.zshrc"
    fi
  fi

  # Bash - source XDG config
  if [[ -f "$XDG_CONFIG_HOME/bash/.bashrc" ]]; then
    local bash_rc="$HOME/.bashrc"
    local xdg_source="source \"$XDG_CONFIG_HOME/bash/.bashrc\""

    if [[ ! -f "$bash_rc" ]]; then
      # Create new .bashrc with XDG config sourced and shell detection
      cat > "$bash_rc" << 'BASH_RC_EOF'
# Dotfile XDG configuration
# Shell detection to prevent loading in incompatible shells
if [ -z "$BASH_VERSION" ]; then
  echo "Warning: ~/.bashrc should be sourced in bash, not ${0##*/}" >&2
  echo "If you want to use zsh configuration, run: source ~/.zshrc" >&2
  return 1
fi

BASH_RC_EOF
      echo "$xdg_source" >> "$bash_rc"
      log "Created ~/.bashrc with XDG config sourced"
    elif ! grep -q "bash/.bashrc" "$bash_rc" 2>/dev/null; then
      # Append XDG source to existing .bashrc
      echo "" >> "$bash_rc"
      echo "# Dotfile XDG configuration" >> "$bash_rc"
      echo "# Shell detection to prevent loading in incompatible shells" >> "$bash_rc"
      echo "if [ -z \"\$BASH_VERSION\" ]; then" >> "$bash_rc"
      echo "  echo \"Warning: ~/.bashrc should be sourced in bash, not \${0##*/}\" >&2" >> "$bash_rc"
      echo "  return 1" >> "$bash_rc"
      echo "fi" >> "$bash_rc"
      echo "" >> "$bash_rc"
      echo "$xdg_source" >> "$bash_rc"
      log "Appended XDG config source to ~/.bashrc"
    else
      log "XDG config already sourced in ~/.bashrc"
    fi
  fi

  # Tmux - use symlink
  if [[ -f "$XDG_CONFIG_HOME/tmux/tmux.conf" && ! -e "$HOME/.tmux.conf" ]]; then
    ln -s "$XDG_CONFIG_HOME/tmux/tmux.conf" "$HOME/.tmux.conf"
    log "Created symlink: ~/.tmux.conf -> $XDG_CONFIG_HOME/tmux/tmux.conf"
  fi
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
    sed_inplace "\|alias $ALIAS_NAME='git --git-dir=\$HOME/.dotfile/ --work-tree=\$HOME'|d" "$rc_file"
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
# POST-INSTALLATION TESTS
# ============================================================================

run_post_install_tests() {
  echo ""
  echo "=========================================="
  echo "  Post-Installation Tests"
  echo "=========================================="
  echo ""

  # In SKIP_INSTALL mode, only test config deployment, not tools
  if [ -n "$SKIP_INSTALL" ]; then
    log "SKIP_INSTALL=1: Testing configuration deployment only..."

    local total_tests=0
    local passed_tests=0
    local failed_tests=0

    # Test helper
    test_command() {
      local name="$1"
      local command="$2"
      ((total_tests++))

      if eval "$command" >/dev/null 2>&1; then
        log "  ✓ $name"
        ((passed_tests++))
        return 0
      else
        warn "  ✗ $name"
        ((failed_tests++))
        return 1
      fi
    }

    # Test only config deployment
    test_command "Dotfile repository exists" "[ -d '$DOT_DIR' ]"
    test_command "Dotfile is bare repository" "git --git-dir='$DOT_DIR' rev-parse --is-bare-repository"
    test_command "Zsh config deployed" "[ -f '$XDG_CONFIG_HOME/zsh/.zshrc' ] || [ -f '$HOME/.zshrc' ]"
    test_command "Bash config deployed" "[ -f '$XDG_CONFIG_HOME/bash/.bashrc' ] || [ -f '$HOME/.bashrc' ]"
    test_command "Neovim config directory exists" "[ -d '$XDG_CONFIG_HOME/nvim' ]"

    echo ""
    log "  Total: $total_tests, Passed: $passed_tests, Failed: $failed_tests"
    echo "=========================================="
    echo ""

    return $failed_tests
  fi

  local total_tests=0
  local passed_tests=0
  local failed_tests=0

  # Test helper
  test_command() {
    local name="$1"
    local command="$2"
    ((total_tests++))

    if eval "$command" >/dev/null 2>&1; then
      log "  ✓ $name"
      ((passed_tests++))
      return 0
    else
      warn "  ✗ $name"
      ((failed_tests++))
      return 1
    fi
  }

  # Test 1: Core commands availability
  log "Testing core commands..."
  test_command "git command" "command -v git"
  test_command "zsh command" "command -v zsh"
  test_command "vim command" "command -v vim"
  test_command "nvim command" "command -v nvim"
  test_command "tmux command" "command -v tmux"
  test_command "node command" "command -v node"
  test_command "npm command" "command -v npm"
  echo ""

  # Test 2: Dotfile repository
  log "Testing dotfile repository..."
  test_command "Dotfile directory exists" "[ -d '$DOT_DIR' ]"
  test_command "Dotfile is bare repository" "git --git-dir='$DOT_DIR' rev-parse --is-bare-repository"
  test_command "Dot alias works" "alias dot >/dev/null 2>&1 || command -v dot"
  echo ""

  # Test 3: XDG paths
  log "Testing XDG paths..."
  ensure_xdg_paths
  test_command "XDG_CONFIG_HOME exists" "[ -d '$XDG_CONFIG_HOME' ]"
  test_command "XDG_DATA_HOME exists" "[ -d '$XDG_DATA_HOME' ]"
  test_command "XDG_STATE_HOME exists" "[ -d '$XDG_STATE_HOME' ]"
  test_command "XDG_CACHE_HOME exists" "[ -d '$XDG_CACHE_HOME' ]"
  echo ""

  # Test 4: ZSH plugins
  log "Testing ZSH ecosystem..."
  test_command "oh-my-zsh installed" "[ -d '$HOME/.oh-my-zsh' ]"
  test_command "zsh-autosuggestions installed" "[ -d '$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions' ]"
  test_command "zsh-syntax-highlighting installed" "[ -d '$HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting' ]"
  echo ""

  # Test 5: CLI tools
  log "Testing CLI tools..."
  test_command "zoxide installed" "command -v zoxide"
  test_command "fzf installed" "command -v fzf"
  test_command "tmux plugin manager (TPM) installed" "[ -d '$HOME/.tmux/plugins/tpm' ]"
  echo ""

  # Test 6: Config files deployment
  log "Testing config files..."
  test_command "Zsh config deployed" "[ -f '$XDG_CONFIG_HOME/zsh/.zshrc' ] || [ -f '$HOME/.zshrc' ]"
  test_command "Vim config deployed" "[ -f '$XDG_CONFIG_HOME/vim/vimrc' ] || [ -f '$HOME/.vimrc' ] || [ -d '$XDG_CONFIG_HOME/vim' ]"
  test_command "Neovim config deployed" "[ -d '$XDG_CONFIG_HOME/nvim' ]"
  test_command "Tmux config deployed" "[ -f '$XDG_CONFIG_HOME/tmux/tmux.conf' ] || [ -f '$HOME/.tmux.conf' ]"
  echo ""

  # Test 6.5: XDG compliance verification
  log "Testing XDG compliance..."
  test_command "XDG_CONFIG_HOME is set" "[ -n '$XDG_CONFIG_HOME' ]"
  test_command "XDG_DATA_HOME is set" "[ -n '$XDG_DATA_HOME' ]"
  test_command "XDG_STATE_HOME is set" "[ -n '$XDG_STATE_HOME' ]"
  test_command "XDG_CACHE_HOME is set" "[ -n '$XDG_CACHE_HOME' ]"

  # Check for XDG-compliant config locations
  test_command "Vim uses XDG (preferred)" "[ -d '$XDG_CONFIG_HOME/vim' ] || [ -L '$HOME/.vim' ]"
  test_command "Zsh uses XDG (preferred)" "[ -d '$XDG_CONFIG_HOME/zsh' ] || [ -L '$HOME/.zshrc' ]"
  test_command "Tmux uses XDG (preferred)" "[ -d '$XDG_CONFIG_HOME/tmux' ] || [ -L '$HOME/.tmux.conf' ]"
  echo ""

  # Test 7: Neovim version check
  log "Testing Neovim..."
  if command -v nvim >/dev/null 2>&1; then
    local nvim_version
    nvim_version="$(nvim --version | head -1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)"
    if [ -n "$nvim_version" ]; then
      log "  ✓ Neovim version: $nvim_version"
      ((total_tests++))
      ((passed_tests++))
    fi
  fi
  echo ""

  # Test 8: Git operations (if dot alias works)
  log "Testing git operations..."
  if alias dot >/dev/null 2>&1 || command -v dot >/dev/null 2>&1; then
    test_command "Dot status command" "git --git-dir='$DOT_DIR' status >/dev/null 2>&1"
    test_command "Dot remote configured" "git --git-dir='$DOT_DIR' remote -v | grep -q origin"
  else
    warn "  ⚠ Dot alias not available, skipping git tests"
  fi
  echo ""

  # Summary
  echo "=========================================="
  log "Test Summary:"
  log "  Total: $total_tests"
  log "  Passed: $passed_tests"
  if [ $failed_tests -gt 0 ]; then
    warn "  Failed: $failed_tests"
  else
    log "  Failed: 0"
  fi
  echo "=========================================="
  echo ""

  return $failed_tests
}

print_runtime_status() {
  ensure_xdg_paths

  echo ""
  echo "=========================================="
  echo "  Dotfile Status"
  echo "=========================================="
  echo ""

  log "Lifecycle actions: ${DOTFILE_ACTIONS[*]}"
  echo ""
  log "XDG path configuration:"
  print_xdg_status
  echo ""

  if [ -d "$DOT_DIR" ]; then
    if dot rev-parse --is-bare-repository >/dev/null 2>&1; then
      log "Dotfile repository: $DOT_DIR"
      if [ -n "$DRY_RUN" ]; then
        info "[DRY-RUN] Would run: dot status -sb"
      else
        dot status -sb || warn "Unable to read dotfile repository status"
      fi
    else
      warn "Dotfile directory exists but is not a valid bare repository: $DOT_DIR"
    fi
  else
    warn "Dotfile repository not installed yet"
  fi
}

run_verification() {
  ensure_xdg_paths

  echo ""
  echo "=========================================="
  echo "  Dotfile Verification"
  echo "=========================================="
  echo ""

  log "Verifying XDG path contract..."
  print_xdg_status
  echo ""

  local missing=0
  local path

  for path in "$XDG_CONFIG_HOME" "$XDG_DATA_HOME" "$XDG_STATE_HOME" "$XDG_CACHE_HOME"; do
    if [ -d "$path" ]; then
      log "  ✓ $path"
    else
      warn "  ✗ $path"
      ((missing++))
    fi
  done

  if [ -d "$DOT_DIR" ]; then
    log "  ✓ Dotfile repository path exists"
  else
    warn "  ✗ Dotfile repository path missing ($DOT_DIR)"
    ((missing++))
  fi

  if [ "$missing" -eq 0 ]; then
    log "Verification completed successfully"
  else
    warn "Verification completed with $missing missing item(s)"
  fi

  return 0
}

run_update() {
  ensure_xdg_paths

  echo ""
  echo "=========================================="
  echo "  Dotfile Update"
  echo "=========================================="
  echo ""

  if [ -n "$DRY_RUN" ]; then
    info "[DRY-RUN] Would update dotfile repository from $REPO_URL"
    info "[DRY-RUN] Would redeploy tracked files into $HOME"
    return 0
  fi

  if [ ! -d "$DOT_DIR" ]; then
    warn "Dotfile repository not found, falling back to install"
    run_installation
    return 0
  fi

  log "Updating dotfile repository..."

  # Check if remote origin exists
  if ! dot remote | grep -q "origin"; then
    error "No remote 'origin' found in dotfile repository"
  fi

  # Fetch from origin
  dot fetch origin || error "Failed to fetch latest dotfile changes"

  # Determine the target branch to update to
  local target_ref
  local target_branch

  # Method 1: Try to get origin/HEAD symbolic ref (works in non-bare repos)
  target_ref="$(dot symbolic-ref --quiet refs/remotes/origin/HEAD 2>/dev/null || true)"

  if [ -n "$target_ref" ]; then
    # Remove refs/remotes/ prefix (e.g., refs/remotes/origin/master -> origin/master)
    target_ref="${target_ref#refs/remotes/}"
  else
    # Method 2: Try to detect default branch from remote
    # This works in bare repos after fetch
    local default_branch
    default_branch="$(dot ls-remote --symref origin HEAD 2>/dev/null | awk '/^ref:/ {print $2}')"

    if [ -n "$default_branch" ]; then
      # Remove refs/heads/ prefix (e.g., refs/heads/master -> master)
      target_branch="${default_branch#refs/heads/}"
      # In bare repos, we need to fetch the branch explicitly and use FETCH_HEAD
      # or get the SHA directly
      target_ref="$target_branch"
    else
      # Method 3: Fallback to common branch names
      # Try to detect from FETCH_HEAD or use common defaults
      for branch in "master" "main"; do
        # Check if this branch exists on remote
        if dot ls-remote --exit-code --heads "origin" "$branch" >/dev/null 2>&1; then
          target_ref="$branch"
          target_branch="$branch"
          break
        fi
      done
    fi
  fi

  if [ -z "$target_ref" ]; then
    # Method 4: Last resort - try to use FETCH_HEAD directly
    # This will reset to whatever was just fetched
    if dot rev-parse FETCH_HEAD >/dev/null 2>&1; then
      log "Unable to determine specific branch, using FETCH_HEAD"
      target_ref="FETCH_HEAD"
    else
      error "Unable to determine remote branch. Please check your repository configuration."
    fi
  elif [ "$target_ref" != "FETCH_HEAD" ]; then
    # For bare repos, fetch the specific branch and use FETCH_HEAD
    if [ -z "$target_branch" ]; then
      target_branch="$target_ref"
    fi

    log "Fetching branch $target_branch from origin..."
    if dot fetch origin "refs/heads/$target_branch:FETCH_HEAD" >/dev/null 2>&1; then
      target_ref="FETCH_HEAD"
    else
      error "Failed to fetch branch $target_branch from origin"
    fi
  fi

  log "Resetting to $target_ref..."
  dot reset --hard "$target_ref" || error "Failed to reset dotfile repository to $target_ref"

  backup_conflicting_files
  deploy_dotfiles
  install_shell_alias
  create_xdg_symlinks
  log "Dotfile update completed"
}

run_package() {
  local package_script="$ROOT_DIR/scripts/offline-export.sh"

  [ -f "$package_script" ] || error "Package script not found: $package_script"

  if [ -n "$DRY_RUN" ]; then
    info "[DRY-RUN] Would run: bash $package_script"
    return 0
  fi

  AUTO_YES="${AUTO_YES:-1}" bash "$package_script"
}

run_offline_deploy() {
  local bundle_path="${2:-}"

  [ -n "$bundle_path" ] || error "offline-deploy requires a bundle path"

  if [ -n "$DRY_RUN" ]; then
    info "[DRY-RUN] Would run offline bundle: bash $bundle_path install"
    return 0
  fi

  [ -f "$bundle_path" ] || error "Offline bundle not found: $bundle_path"
  bash "$bundle_path" install
}

run_reinstallation() {
  echo ""
  echo "=========================================="
  echo "  Dotfile Reinstallation"
  echo "=========================================="
  echo ""

  if [ -n "$DRY_RUN" ]; then
    info "[DRY-RUN] Would uninstall tracked dotfiles and repository"
    info "[DRY-RUN] Would install required tools and redeploy dotfiles"
    return 0
  fi

  if [ -d "$DOT_DIR" ]; then
    run_uninstallation
  else
    warn "Dotfile repository not found, skipping uninstall step"
  fi

  run_installation
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
  ensure_xdg_paths

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

  # Create XDG-compliant symlinks
  echo ""
  create_xdg_symlinks

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

  # Run post-installation tests
  echo ""
  run_post_install_tests
  local test_result=$?

  if [ $test_result -eq 0 ]; then
    log "All post-installation tests passed!"
  else
    warn "Some post-installation tests failed. Please review the output above."
  fi

  # Auto-switch to zsh if requested
  echo ""
  if [ -n "$AUTO_SWITCH_SHELL" ]; then
    log "Auto-switching to zsh (AUTO_SWITCH_SHELL=1)..."
    switch_to_zsh
  else
    log "To switch to zsh automatically, set AUTO_SWITCH_SHELL=1"
  fi

  echo ""
  log "Next steps:"
  echo "  1. Run 'source ~/.zshrc' or restart shell"
  echo "  2. Change default shell: chsh -s \$(which zsh)"
  echo "     Or set AUTO_SWITCH_SHELL=1 bash install.sh install"
  echo "  3. Install tmux plugins: Press 'Ctrl+a I' in tmux"
  echo "  4. Open nvim to install plugins automatically"
  echo ""

  if [ -n "$BACKUP_DIR" ]; then
    log "Backup saved to: $BACKUP_DIR"
  fi

  # Return the test result (0 = all tests passed, non-zero = some tests failed)
  return $test_result
}

# ============================================================================
# SHELL SWITCHING
# ============================================================================

switch_to_zsh() {
  # Check if we're already in zsh
  if [ -n "$ZSH_VERSION" ]; then
    log "Already using zsh, no need to switch"
    return 0
  fi

  # Check if zsh is installed
  if ! command -v zsh >/dev/null 2>&1; then
    warn "Zsh is not installed, skipping shell switch"
    return 1
  fi

  # Get zsh path
  local zsh_path
  zsh_path="$(which zsh)"

  # Check if zsh is in /etc/shells
  if ! grep -qx "$zsh_path" /etc/shells 2>/dev/null; then
    log "Adding zsh to /etc/shells..."
    if [ -w /etc/shells ]; then
      echo "$zsh_path" | sudo tee -a /etc/shells >/dev/null
      log "Added $zsh_path to /etc/shells"
    else
      warn "Cannot write to /etc/shells, please run: echo '$zsh_path' | sudo tee -a /etc/shells"
      warn "Then run: chsh -s $zsh_path"
      return 1
    fi
  fi

  # Check current shell
  local current_shell
  current_shell="$(basename "$SHELL")"

  if [ "$current_shell" = "zsh" ]; then
    log "Default shell is already zsh"
    return 0
  fi

  # Switch shell
  log "Switching default shell to zsh..."
  if [ -n "$DRY_RUN" ]; then
    info "[DRY-RUN] Would change default shell to zsh: chsh -s $zsh_path"
  else
    # Attempt to switch shell
    if chsh -s "$zsh_path" 2>/dev/null; then
      log "✓ Default shell changed to zsh"
      log ""
      log "Please log out and log back in for the change to take effect"
      log "Or run 'zsh' to start a zsh session immediately"
    else
      warn "Failed to change default shell"
      warn "Please run manually: chsh -s $zsh_path"
    fi
  fi

  return 0
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
  cat << 'EOF'
╔═══════════════════════════════════════════════════════════════════════════════╗
║                     DOTFILE MANAGER - 帮助文档                                ║
╚═══════════════════════════════════════════════════════════════════════════════╝

📥 快速开始
═══════════════════════════════════════════════════════════════════════════════

1. 一键远程安装（推荐）:
   curl -fsSL https://raw.githubusercontent.com/nbfhscl/dotfile/refs/heads/master/install.sh | bash

2. 远程安装（仅部署配置，跳过工具）:
   curl -fsSL https://raw.githubusercontent.com/nbfhscl/dotfile/refs/heads/master/install.sh | bash -s -- deploy

3. 本地安装:
   bash install.sh <action>

┌───────────────────────────────────────────────────────────────────────────────┐
│ 操作模式 (Actions)                                                            │
└───────────────────────────────────────────────────────────────────────────────┘

  install         安装 dotfiles 和必需工具
  deploy          仅部署配置，跳过工具安装
  update          更新现有 dotfile 配置
  status          显示生命周期状态和仓库信息
  verify          验证 XDG 路径和安装状态
  package         创建离线部署包
  offline-deploy  从离线包安装
  uninstall       卸载 dotfiles（默认创建备份）
  reinstall       重新安装（带备份保护）

┌───────────────────────────────────────────────────────────────────────────────┐
│ 环境变量 (Environment Variables)                                              │
└───────────────────────────────────────────────────────────────────────────────┘

  DRY_RUN=1        预览模式，显示将要执行的操作
  SKIP_INSTALL=1   跳过工具安装，仅部署配置
  NO_BACKUP=1      卸载时不创建备份
  DOT_DIR          自定义 dotfile 目录（默认: $HOME/.dotfile）

┌───────────────────────────────────────────────────────────────────────────────┐
│ 使用示例 (Examples)                                                           │
└───────────────────────────────────────────────────────────────────────────────┘

  # 完整安装（工具 + 配置）
  bash install.sh install

  # 预览安装（不实际执行）
  DRY_RUN=1 bash install.sh install

  # 仅部署配置（跳过工具安装）
  bash install.sh deploy

  # 更新现有安装
  bash install.sh update

  # 显示运行状态和 XDG 路径
  bash install.sh status

  # 验证安装状态
  bash install.sh verify

  # 创建离线部署包
  bash install.sh package

  # 从离线包安装
  bash install.sh offline-deploy ./scripts/dist/dotfiles-offline.sh

  # 卸载（保留备份）
  bash install.sh uninstall

  # 卸载（不创建备份）
  NO_BACKUP=1 bash install.sh uninstall

  # 重新安装
  bash install.sh reinstall

╔═══════════════════════════════════════════════════════════════════════════════╗
║  项目仓库: https://github.com/nbfhscl/dotfile                                 ║
╚═══════════════════════════════════════════════════════════════════════════════╝
EOF
}

# ============================================================================
# MAIN ENTRY POINT
# ============================================================================

main() {
  local requested_action="${1:-}"

  case "$requested_action" in
    install|deploy|update|status|verify|package|offline-deploy|uninstall|reinstall)
      ACTION="$requested_action"
      ;;
    -h|--help|help|"")
      show_help
      exit 0
      ;;
    *)
      error "Unknown action: ${1:-}
Use one of: ${DOTFILE_ACTIONS[*]}
Run '$SCRIPT_NAME --help' for usage information"
      ;;
  esac

  case "$ACTION" in
    install)
      run_installation
      ;;
    deploy)
      SKIP_INSTALL=1
      run_installation
      ;;
    update)
      run_update
      ;;
    status)
      print_runtime_status
      ;;
    verify)
      run_verification
      ;;
    package)
      run_package
      ;;
    offline-deploy)
      run_offline_deploy "$@"
      ;;
    uninstall)
      run_uninstallation
      ;;
    reinstall)
      run_reinstallation
      ;;
  esac
}

main "$@"
