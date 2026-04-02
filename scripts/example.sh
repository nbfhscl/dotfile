#!/bin/bash
# example.sh - 演示dotfile打包工具的完整使用流程

set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly COLORS=true

# 颜色输出
if [ "$COLORS" = true ]; then
  RED='\033[0;31m'
  GREEN='\033[0;32m'
  YELLOW='\033[1;33m'
  BLUE='\033[0;34m'
  CYAN='\033[0;36m'
  BOLD='\033[1m'
  NC='\033[0m'
fi

# ============================================================================
# 演示辅助函数
# ============================================================================

print_section() {
  echo ""
  echo -e "${CYAN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BOLD}$1${NC}"
  echo -e "${CYAN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
}

print_step() {
  echo -e "${GREEN}▶${NC} ${BOLD}$1${NC}"
}

print_info() {
  echo -e "${BLUE}ℹ${NC} $1"
}

print_warning() {
  echo -e "${YELLOW}⚠${NC} $1"
}

print_success() {
  echo -e "${GREEN}✓${NC} ${BOLD}$1${NC}"
}

print_error() {
  echo -e "${RED}✗${NC} $1"
}

wait_user() {
  echo ""
  read -p "$(echo -e ${YELLOW}"按 Enter 继续...${NC})"
}

# ============================================================================
# 演示场景
# ============================================================================

demo_intro() {
  clear
  cat << 'EOF'

╔═══════════════════════════════════════════════════════════════╗
║                                                               ║
║   ███╗   ██╗███████╗██╗  ██╗██╗   ██╗███████╗                ║
║   ████╗  ██║██╔════╝╚██╗██╔╝██║   ██║██╔════╝                ║
║   ██╔██╗ ██║█████╗   ╚███╔╝ ██║   ██║███████╗                ║
║   ██║╚██╗██║██╔══╝   ██╔██╗ ██║   ██║╚════██║                ║
║   ██║ ╚████║███████╗██╔╝ ██╗╚██████╔╝███████║                ║
║   ╚═╝  ╚═══╝╚══════╝╚═╝  ╚═╝ ╚═════╝ ╚══════╝                ║
║                                                               ║
║         便携式 Dotfile 打包工具 - 使用演示                    ║
║                                                               ║
╚═══════════════════════════════════════════════════════════════╝

EOF

  echo -e "${BOLD}本演示将展示:${NC}"
  echo "  1. 收集当前系统的dotfile配置"
  echo "  2. 打包成自解压脚本"
  echo "  3. 在目标机器上安装"
  echo ""

  wait_user
}

demo_collect() {
  print_section "步骤 1/3: 收集配置"

  print_step "收集当前系统的dotfile和依赖信息"

  echo ""
  print_info "这将收集:"
  echo "  • 所有git仓库跟踪的dotfile文件"
  echo "  • 系统包列表（apt/pacman等）"
  echo "  • 语言包（npm/pip/gem/cargo）"
  echo "  • 工具版本信息"
  echo "  • 插件仓库信息"
  echo ""

  wait_user

  if [ -f "$SCRIPT_DIR/collect.sh" ]; then
    bash "$SCRIPT_DIR/collect.sh"
    print_success "收集完成！"
  else
    print_error "collect.sh 不存在"
    return 1
  fi

  wait_user
}

demo_package() {
  print_section "步骤 2/3: 打包"

  print_step "将收集的内容打包成自解压脚本"

  echo ""
  print_info "这将创建:"
  echo "  • 便携式shell脚本（包含所有数据）"
  echo "  • SHA256校验和文件"
  echo ""

  wait_user

  if [ -f "$SCRIPT_DIR/package.sh" ]; then
    bash "$SCRIPT_DIR/package.sh" "demo_$(date +%Y%m%d_%H%M%S)"
    print_success "打包完成！"
  else
    print_error "package.sh 不存在"
    return 1
  fi

  wait_user
}

demo_show_result() {
  print_section "打包结果"

  local dist_dir="$SCRIPT_DIR/dist"
  local package_file=$(ls -t "$dist_dir"/dotfiles-portable-*.sh 2>/dev/null | head -1)

  if [ -n "$package_file" ]; then
    echo ""
    print_success "生成的文件:"
    echo ""
    echo -e "  ${BOLD}脚本:${NC} $package_file"
    echo -e "  ${BOLD}大小:${NC} $(du -h "$package_file" | cut -f1)"
    echo ""

    if [ -f "${package_file}.sha256" ]; then
      echo -e "  ${BOLD}校验和:${NC}"
      echo "  $(cat ${package_file}.sha256)"
      echo ""
    fi

    # 显示使用说明
    echo ""
    print_info "在目标机器上使用:"
    echo ""
    echo -e "  ${CYAN}# 1. 传输脚本${NC}"
    echo "  scp $package_file user@target:~/"
    echo ""
    echo -e "  ${CYAN}# 2. 安装${NC}"
    echo "  bash $(basename "$package_file") install"
    echo ""
    echo -e "  ${CYAN}# 3. 或只查看信息${NC}"
    echo "  bash $(basename "$package_file") info"
    echo ""
  fi

  wait_user
}

demo_inspect() {
  print_section "检查收集的内容"

  local collect_dir="$SCRIPT_DIR/.collect"

  if [ ! -d "$collect_dir" ]; then
    print_warning "收集目录不存在，请先运行收集"
    return
  fi

  echo ""
  print_step "查看收集的文件"

  echo ""
  echo -e "${BOLD}目录结构:${NC}"
  tree -L 2 "$collect_dir" 2>/dev/null || ls -R "$collect_dir"
  echo ""

  print_step "查看dotfile列表"
  if [ -f "$collect_dir/dotfiles.txt" ]; then
    echo ""
    head -20 "$collect_dir/dotfiles.txt"
    echo "..."
    echo ""
    echo "总共: $(wc -l < "$collect_dir/dotfiles.txt") 个文件"
  fi

  echo ""
  wait_user

  print_step "查看包列表"
  if [ -d "$collect_dir/packages" ]; then
    echo ""
    for pkg_file in "$collect_dir/packages"/*.txt; do
      if [ -f "$pkg_file" ]; then
        local name=$(basename "$pkg_file")
        local count=$(wc -l < "$pkg_file" 2>/dev/null || echo 0)
        echo "  $name: $count 个包"
      fi
    done
  fi

  echo ""
  wait_user
}

demo_cleanup() {
  print_section "清理临时文件"

  print_warning "这将删除收集和打包的临时文件"
  echo ""
  echo "  • $SCRIPT_DIR/.collect"
  echo "  • $SCRIPT_DIR/dist"
  echo ""

  read -p "$(echo -e ${YELLOW}"确认清理? [y/N]${NC} )" -n 1 -r
  echo ""

  if [[ $REPLY =~ ^[Yy]$ ]]; then
    rm -rf "$SCRIPT_DIR/.collect"
    rm -rf "$SCRIPT_DIR/dist"
    print_success "清理完成"
  else
    print_info "已取消"
  fi

  echo ""
  wait_user
}

demo_advanced() {
  print_section "高级用法"

  echo ""
  print_step "自定义收集内容"
  echo ""
  echo "1. 编辑 .collect/dotfiles.txt 只包含需要的文件"
  echo "2. 重新运行 package.sh"
  echo ""

  print_step "分步执行（而非export.sh一键）"
  echo ""
  echo "  bash collect.sh   # 收集"
  echo "  # 编辑 .collect/ 目录中的文件"
  echo "  bash package.sh   # 打包"
  echo ""

  print_step "只导出配置（不包含依赖）"
  echo ""
  echo "编辑 collect.sh，注释掉:"
  echo "  collect_system_packages"
  echo "  collect_language_packages"
  echo ""

  print_step "定期备份"
  echo ""
  echo "  # 添加到crontab"
  echo "  0 2 * * 0 cd ~/dotfile/scripts && bash export.sh"
  echo ""

  wait_user
}

# ============================================================================
# 主菜单
# ============================================================================

show_menu() {
  clear
  print_section "Dotfile 打包工具 - 演示菜单"

  echo -e "${BOLD}基础操作:${NC}"
  echo "  1) 完整演示（收集→打包→查看）"
  echo "  2) 仅收集配置"
  echo "  3) 仅打包"
  echo "  4) 查看打包结果"
  echo "  5) 检查收集内容"
  echo ""

  echo -e "${BOLD}高级操作:${NC}"
  echo "  6) 查看高级用法"
  echo "  7) 清理临时文件"
  echo ""

  echo "  q) 退出"
  echo ""

  read -p "选择操作 [1-7/q]: " choice
  echo ""

  case $choice in
    1)
      demo_collect
      demo_package
      demo_show_result
      demo_inspect
      ;;
    2) demo_collect ;;
    3) demo_package ;;
    4) demo_show_result ;;
    5) demo_inspect ;;
    6) demo_advanced ;;
    7) demo_cleanup ;;
    q|Q)
      echo ""
      print_success "感谢使用！"
      echo ""
      exit 0
      ;;
    *)
      print_error "无效选择"
      sleep 1
      ;;
  esac
}

# ============================================================================
# 主流程
# ============================================================================

main() {
  demo_intro

  while true; do
    show_menu
    wait_user
  done
}

main "$@"
