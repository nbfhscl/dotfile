#!/bin/bash
# offline-package.sh - 将离线包打包成自解压脚本

set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly COLLECT_DIR="$SCRIPT_DIR/.offline_collect"
readonly OUTPUT_DIR="$SCRIPT_DIR/dist"
readonly PACKAGE_NAME="dotfiles-offline"
readonly VERSION="${1:-$(date +%Y%m%d_%H%M%S)}"

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
# 验证
# ============================================================================

validate_collect_dir() {
  if [ ! -d "$COLLECT_DIR" ]; then
    error "Collection directory not found. Run 'offline-collect.sh' first"
  fi
}

# ============================================================================
# 创建输出目录
# ============================================================================

create_output_dir() {
  info "Creating output directory..."
  rm -rf "$OUTPUT_DIR"
  mkdir -p "$OUTPUT_DIR"
}

# ============================================================================
# 生成自解压安装脚本
# ============================================================================

generate_self_extracting_installer() {
  info "Generating self-extracting offline installer..."

  local output_file="$OUTPUT_DIR/${PACKAGE_NAME}-${VERSION}.sh"
  local temp_dir="/tmp/offline_pkg_$$"

  mkdir -p "$temp_dir"

  # 生成安装脚本头部
  cat > "$temp_dir/header.sh" << 'HEADER_EOF'
#!/bin/bash
# Dotfile Offline Installer
# 完全离线环境的dotfile和依赖安装

set -euo pipefail

readonly SCRIPT_NAME="$(basename "$0")"
readonly VERSION="__VERSION__"
readonly EXTRACT_DIR="/tmp/dotfiles_offline_$$"
readonly BACKUP_DIR="$HOME/.dotfile_backup_$(date +%Y%m%d_%H%M%S)"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1" >&2; exit 1; }
info() { echo -e "${BLUE}[STEP]${NC} $1"; }

# 清理
trap "rm -rf $EXTRACT_DIR" EXIT

# ============================================================================
# 解压数据
# ============================================================================

extract_data() {
  info "Extracting offline packages..."

  local archive_line=$(awk '/^__ARCHIVE_BELOW__/ {print NR + 1; exit 0;}' "$SCRIPT_NAME")

  if [ -z "$archive_line" ]; then
    error "Package data not found"
  fi

  mkdir -p "$EXTRACT_DIR"
  tail -n +$archive_line "$SCRIPT_NAME" | tar xz -C "$EXTRACT_DIR"

  log "Extraction complete"
}

# ============================================================================
# 显示包信息
# ============================================================================

show_package_info() {
  echo ""
  echo "=========================================="
  echo "  Offline Dotfile Package"
  echo "  Version: $VERSION"
  echo "=========================================="
  echo ""

  if [ -f "$EXTRACT_DIR/MANIFEST.txt" ]; then
    cat "$EXTRACT_DIR/MANIFEST.txt"
  fi
}

# ============================================================================
# 备份现有配置
# ============================================================================

backup_existing() {
  info "Checking for existing dotfiles..."

  local backup_count=0

  if [ -f "$EXTRACT_DIR/metadata/dotfiles.txt" ]; then
    while IFS= read -r file; do
      [ -n "$file" ] || continue
      local target="$HOME/$file"

      if [ -e "$target" ] || [ -L "$target" ]; then
        if [ ! -d "$BACKUP_DIR" ]; then
          mkdir -p "$BACKUP_DIR"
        fi

        local backup_path="$BACKUP_DIR/$file"
        mkdir -p "$(dirname "$backup_path")"
        cp -a "$target" "$backup_path"
        ((backup_count++))
      fi
    done < "$EXTRACT_DIR/metadata/dotfiles.txt"
  fi

  if [ $backup_count -gt 0 ]; then
    log "Backed up $backup_count files"
  else
    log "No existing files to backup"
  fi
}

# ============================================================================
# 安装dotfiles
# ============================================================================

install_dotfiles() {
  info "Installing dotfiles..."

  local count=0

  if [ -f "$EXTRACT_DIR/metadata/dotfiles.txt" ]; then
    while IFS= read -r file; do
      [ -n "$file" ] || continue
      local src="$EXTRACT_DIR/dotfiles/$file"
      local dst="$HOME/$file"

      if [ -e "$src" ] || [ -L "$src" ]; then
        mkdir -p "$(dirname "$dst")"
        cp -a "$src" "$dst"
        ((count++))
      fi
    done < "$EXTRACT_DIR/metadata/dotfiles.txt"
  fi

  log "Installed $count dotfiles"
}

# ============================================================================
# 运行离线安装器
# ============================================================================

run_offline_installer() {
  if [ -f "$EXTRACT_DIR/offline-install.sh" ]; then
    info "Running offline dependency installer..."
    bash "$EXTRACT_DIR/offline-install.sh"
  else
    warn "Offline installer not found"
  fi
}

# ============================================================================
# 主流程
# ============================================================================

main() {
  local mode="${1:-install}"

  echo ""
  echo "=========================================="
  echo "  Offline Dotfile Installer"
  echo "  Version: $VERSION"
  echo "=========================================="
  echo ""

  case "$mode" in
    install)
      extract_data
      show_package_info
      echo ""
      backup_existing
      install_dotfiles
      echo ""
      run_offline_installer

      echo ""
      log "✅ Installation complete!"
      echo ""
      log "Backup location: $BACKUP_DIR"
      echo ""

      log "Next steps:"
      echo "  1. Reload shell: exec zsh"
      echo "  2. Verify: dot status"
      echo ""

      if [ -d "$BACKUP_DIR" ]; then
        log "To restore backup:"
        echo "  cp -a $BACKUP_DIR/* ~/"
      fi
      ;;

    extract)
      local extract_to="${2:-./dotfiles-offline}"
      mkdir -p "$extract_to"

      extract_data
      cp -a "$EXTRACT_DIR"/* "$extract_to/"

      log "Extracted to: $extract_to"
      ;;

    info)
      extract_data
      show_package_info
      ;;

    *)
      error "Unknown mode: $mode
Usage: bash $SCRIPT_NAME [install|extract|info] [target_dir]"
      ;;
  esac
}

main "$@"
__ARCHIVE_BELOW__
HEADER_EOF

  # 替换版本号
  sed -i "s/__VERSION__/$VERSION/g" "$temp_dir/header.sh"

  # 创建数据包
  info "Creating data package..."
  tar czf "$temp_dir/data.tar.gz" -C "$COLLECT_DIR" .

  # 合并脚本和数据
  cat "$temp_dir/header.sh" "$temp_dir/data.tar.gz" > "$output_file"
  chmod +x "$output_file"

  rm -rf "$temp_dir"

  local size=$(du -h "$output_file" | cut -f1)
  log "Package created: $output_file ($size)"
}

# ============================================================================
# 生成校验和
# ============================================================================

generate_checksums() {
  local output_file="$1"

  info "Generating checksums..."

  if command -v sha256sum &> /dev/null; then
    sha256sum "$output_file" > "$output_file.sha256"
    log "SHA256: $(cat $output_file.sha256 | cut -d' ' -f1)"
  elif command -v shasum &> /dev/null; then
    shasum -a 256 "$output_file" > "$output_file.sha256"
    log "SHA256: $(cat $output_file.sha256 | cut -d' ' -f1)"
  fi
}

# ============================================================================
# 主函数
# ============================================================================

main() {
  echo ""
  echo "=========================================="
  echo "  Offline Package Builder"
  echo "=========================================="
  echo ""

  validate_collect_dir
  create_output_dir
  generate_self_extracting_installer

  local output_file="$OUTPUT_DIR/${PACKAGE_NAME}-${VERSION}.sh"
  generate_checksums "$output_file"

  echo ""
  log "✅ Offline package created successfully!"
  echo ""
  log "Package file: $output_file"
  log "Checksum file: $output_file.sha256"
  echo ""

  log "Usage on offline machine:"
  echo "  1. Transfer $output_file to target machine"
  echo "  2. Run: bash $(basename "$output_file") install"
  echo ""
  log "Or extract without installing:"
  echo "  bash $(basename "$output_file") extract /path/to/extract"
  echo ""
}

main "$@"
