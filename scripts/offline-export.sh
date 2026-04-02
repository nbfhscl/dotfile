#!/bin/bash
# offline-export.sh - 一键导出完全离线安装包

set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly VERSION="${1:-$(date +%Y%m%d_%H%M%S)}"
AUTO_YES="${AUTO_YES:-}"
DRY_RUN="${DRY_RUN:-}"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

log() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1" >&2; exit 1; }
info() { echo -e "${BLUE}[STEP]${NC} $1"; }
progress() { echo -e "${CYAN}[PROGRESS]${NC} $1"; }

# ============================================================================
# 显示横幅
# ============================================================================

show_banner() {
  if [ -z "$DRY_RUN" ] && [ -t 1 ] && command -v clear >/dev/null 2>&1; then
    clear
  fi
  cat << 'BANNER'

╔═══════════════════════════════════════════════════════════════╗
║                                                               ║
║   ███╗   ██╗███████╗██╗  ██╗██╗   ██╗███████╗                ║
║   ████╗  ██║██╔════╝╚██╗██╔╝██║   ██║██╔════╝                ║
║   ██╔██╗ ██║█████╗   ╚███╔╝ ██║   ██║███████╗                ║
║   ██║╚██╗██║██╔══╝   ██╔██╗ ██║   ██║╚════██║                ║
║   ██║ ╚████║███████╗██╔╝ ██╗╚██████╔╝███████║                ║
║   ╚═╝  ╚═══╝╚══════╝╚═╝  ╚═╝ ╚═════╝ ╚══════╝                ║
║                                                               ║
║         📦 完全离线 Dotfile 打包系统 📦                      ║
║                                                               ║
╚═══════════════════════════════════════════════════════════════╝

BANNER

  echo -e "${BOLD}功能特性:${NC}"
  echo "  ✓ 收集所有dotfile配置文件"
  echo "  ✓ 打包二进制文件（git, zsh, vim, nvim等）"
  echo "  ✓ 下载系统包离线安装文件（.deb/.rpm）"
  echo "  ✓ 收集语言包（npm, pip, cargo）"
  echo "  ✓ 包含插件仓库（zsh, vim, tmux）"
  echo "  ✓ 生成自解压安装脚本"
  echo ""

  echo -e "${BOLD}适用场景:${NC}"
  echo "  • 完全离线的生产环境"
  echo "  • 空气gap服务器"
  echo "  • 内网隔离环境"
  echo "  • 无法访问互联网的机器"
  echo ""
}

# ============================================================================
# 确认开始
# ============================================================================

confirm_start() {
  if [ -n "$AUTO_YES" ]; then
    log "AUTO_YES enabled, skipping confirmation prompt"
    return 0
  fi

  if [ -n "$DRY_RUN" ]; then
    log "DRY_RUN enabled, skipping confirmation prompt"
    return 0
  fi

  echo -e "${YELLOW}⚠️  注意事项:${NC}"
  echo "  • 离线包可能很大（100MB - 1GB）"
  echo "  • 收集过程可能需要几分钟"
  echo "  • 需要足够的磁盘空间"
  echo ""

  local prompt
  prompt="$(printf "%b" "${CYAN}是否继续? [y/N]${NC} ")"
  read -r -p "$prompt" -n 1
  echo ""

  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "已取消"
    exit 0
  fi
}

# ============================================================================
# 执行收集
# ============================================================================

run_collect() {
  echo ""
  info "════════════════════════════════════════"
  info "第 1 步: 收集离线安装文件"
  info "════════════════════════════════════════"
  echo ""

  local start=$(date +%s)

  if [ -n "$DRY_RUN" ]; then
    info "[DRY-RUN] Would run: bash $SCRIPT_DIR/offline-collect.sh"
  else
    bash "$SCRIPT_DIR/offline-collect.sh"
  fi

  local end=$(date +%s)
  local duration=$((end - start))

  echo ""
  log "收集完成！耗时: ${duration}秒"
  echo ""

  sleep 2
}

# ============================================================================
# 执行打包
# ============================================================================

run_package() {
  echo ""
  info "════════════════════════════════════════"
  info "第 2 步: 打包成自解压脚本"
  info "════════════════════════════════════════"
  echo ""

  local start=$(date +%s)

  if [ -n "$DRY_RUN" ]; then
    info "[DRY-RUN] Would run: bash $SCRIPT_DIR/offline-package.sh $VERSION"
  else
    bash "$SCRIPT_DIR/offline-package.sh" "$VERSION"
  fi

  local end=$(date +%s)
  local duration=$((end - start))

  echo ""
  log "打包完成！耗时: ${duration}秒"
  echo ""

  sleep 2
}

# ============================================================================
# 显示结果
# ============================================================================

show_result() {
  echo ""
  info "════════════════════════════════════════"
  info "导出结果"
  info "════════════════════════════════════════"
  echo ""

  local dist_dir="$SCRIPT_DIR/dist"
  local package_file=$(ls -t "$dist_dir"/dotfiles-offline-*.sh 2>/dev/null | head -1)

  if [ -n "$package_file" ]; then
    local size=$(du -h "$package_file" | cut -f1)
    local name=$(basename "$package_file")

    echo -e "${BOLD}生成的文件:${NC}"
    echo "  📦 $package_file"
    echo "  📏 大小: $size"
    echo ""

    if [ -f "${package_file}.sha256" ]; then
      echo -e "${BOLD}SHA256:${NC}"
      cat "${package_file}.sha256"
      echo ""
    fi

    # 显示收集统计
    if [ -d "$SCRIPT_DIR/.offline_collect" ]; then
      echo -e "${BOLD}收集统计:${NC}"
      echo "  二进制文件: $(ls -1 "$SCRIPT_DIR/.offline_collect/cache/binaries" 2>/dev/null | wc -l)"
      echo "  系统包: $(ls -1 "$SCRIPT_DIR/.offline_collect/cache/packages/system"/*.* 2>/dev/null | wc -l)"
      echo "  npm包: $(ls -1 "$SCRIPT_DIR/.offline_collect/cache/packages/npm"/*.tgz 2>/dev/null | wc -l)"
      echo "  Python包: $(ls -1 "$SCRIPT_DIR/.offline_collect/cache/packages/pip"/*.whl 2>/dev/null | wc -l)"
      echo ""
    fi

    echo -e "${BOLD}在目标机器上安装:${NC}"
    echo ""
    echo -e "${CYAN}# 1. 传输脚本${NC}"
    echo "scp $package_file user@offline-machine:~/"
    echo ""
    echo -e "${CYAN}# 2. 安装${NC}"
    echo "bash $name install"
    echo ""
    echo -e "${CYAN}# 3. 或仅提取${NC}"
    echo "bash $name extract ~/dotfiles-extracted"
    echo ""
  fi

  # 清理提示
  echo -e "${YELLOW}提示:${NC}"
  echo "  • 临时文件已保存在: $SCRIPT_DIR/.offline_collect"
  echo "  • 可通过以下命令清理:"
  echo "    rm -rf $SCRIPT_DIR/.offline_collect"
  echo ""
}

# ============================================================================
# 传输选项
# ============================================================================

show_transfer_options() {
  echo ""
  info "════════════════════════════════════════"
  info "传输方式"
  info "════════════════════════════════════════"
  echo ""

  local dist_dir="$SCRIPT_DIR/dist"
  local package_file=$(ls -t "$dist_dir"/dotfiles-offline-*.sh 2>/dev/null | head -1)

  if [ -n "$package_file" ]; then
    echo -e "${BOLD}1. SCP传输${NC}"
    echo "   scp $package_file user@target:~/"
    echo ""

    echo -e "${BOLD}2. USB传输${NC}"
    echo "   cp $package_file /media/usb/"
    echo ""

    echo -e "${BOLD}3. HTTP服务器${NC}"
    echo "   python3 -m http.server 8000 -d $dist_dir"
    echo "   # 目标机器: wget http://your-ip:8000/$(basename "$package_file")"
    echo ""

    echo -e "${BOLD}4. 分卷压缩（大文件）${NC}"
    echo "   split -b 100M $package_file $(basename "$package_file").part"
    echo "   # 目标机器: cat $(basename "$package_file").part* > $(basename "$package_file")"
    echo ""
  fi
}

# ============================================================================
# 主流程
# ============================================================================

main() {
  local total_start=$(date +%s)

  show_banner
  confirm_start

  run_collect
  run_package
  show_result
  show_transfer_options

  local total_end=$(date +%s)
  local total_duration=$((total_end - total_start))

  echo ""
  echo -e "${GREEN}${BOLD}════════════════════════════════════════${NC}"
  echo -e "${GREEN}${BOLD}✅ 离线包导出完成！${NC}"
  echo -e "${GREEN}${BOLD}════════════════════════════════════════${NC}"
  echo ""
  echo "总耗时: ${total_duration}秒"
  echo ""

  if [ -n "$DRY_RUN" ]; then
    warn "[DRY-RUN] Would remove $SCRIPT_DIR/.offline_collect"
  else
    if [ -z "$AUTO_YES" ]; then
      read -p "按 Enter 清理临时文件并退出..."
      echo ""
    fi

    warn "清理临时文件..."
    rm -rf "$SCRIPT_DIR/.offline_collect"
    log "清理完成！"
  fi
  echo ""
}

main "$@"
