#!/bin/bash
# export.sh - 一键导出当前系统的完整dotfile环境

set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
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
# 主流程
# ============================================================================

main() {
  echo ""
  echo "=========================================="
  echo "  Dotfile Export Tool"
  echo "  One-Click Package Generator"
  echo "=========================================="
  echo ""
  echo "Version: $VERSION"
  echo ""

  # Step 1: Collect
  info "Step 1/3: Collecting dotfiles and dependencies..."
  bash "$SCRIPT_DIR/collect.sh"
  echo ""

  # Step 2: Package
  info "Step 2/3: Creating portable package..."
  bash "$SCRIPT_DIR/package.sh" "$VERSION"
  echo ""

  # Step 3: Summary
  info "Step 3/3: Generating summary..."
  echo ""
  echo "=========================================="
  log "✅ Export complete!"
  echo "=========================================="
  echo ""

  local dist_dir="$SCRIPT_DIR/dist"
  local package_file=$(ls -t "$dist_dir"/dotfiles-portable-*.sh 2>/dev/null | head -1)

  if [ -n "$package_file" ]; then
    log "Package: $package_file"

    if [ -f "${package_file}.sha256" ]; then
      log "SHA256: $(cat ${package_file}.sha256 | cut -d' ' -f1)"
    fi

    echo ""
    log "Transfer to target machine and run:"
    echo "  bash $(basename "$package_file") install"
    echo ""

    # 生成传输命令提示
    log "Transfer commands:"
    echo "  # SCP"
    echo "  scp $package_file user@host:~/"
    echo ""
    echo "  # USB"
    echo "  cp $package_file /media/usb/"
    echo ""
    echo "  # HTTP (if you have a server)"
    echo "  cp $package_file /var/www/html/"
    echo "  # On target: wget http://your-server/$(basename "$package_file")"
    echo ""
  fi

  # 清理收集目录
  warn "Cleaning up temporary files..."
  rm -rf "$SCRIPT_DIR/.collect"
  log "Cleanup complete"
}

main "$@"
