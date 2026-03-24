#!/bin/bash
# Tool functionality testing script
# Tests installed tools and deployed configs after install.sh install

set -u

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

PASSED=0
FAILED=0
SKIPPED=0

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_pass() { echo -e "${GREEN}[PASS]${NC} $1"; ((PASSED+=1)); }
log_fail() { echo -e "${RED}[FAIL]${NC} $1"; ((FAILED+=1)); }
log_skip() { echo -e "${YELLOW}[SKIP]${NC} $1"; ((SKIPPED+=1)); }

run_check() {
    local name="$1"
    local command="$2"

    echo -ne "Testing ${name}... "
    if eval "$command" > /tmp/tool-test.log 2>&1; then
        log_pass "$name"
        return 0
    fi

    log_fail "$name"
    head -20 /tmp/tool-test.log
    return 1
}

echo "╔══════════════════════════════════════════════════════════════════════════════╗"
echo "║                      TOOL FUNCTIONALITY TEST SUITE                         ║"
echo "╚══════════════════════════════════════════════════════════════════════════════╝"
echo ""

log_info "Test Environment:"
echo "  OS: $(grep '^PRETTY_NAME=' /etc/os-release | cut -d= -f2- | tr -d '\"')"
echo "  User: $(whoami)"
echo "  Home: $HOME"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_info "Core Tool Tests"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

run_check "git version" "git --version"
run_check "zsh version" "zsh --version"
run_check "vim version" "vim --version"
run_check "nvim version" "nvim --version"
run_check "node version" "node --version"
run_check "npm version" "npm --version"
run_check "zoxide version" "zoxide --version"
run_check "fzf version" "fzf --version"
run_check "tmux version" "tmux -V"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_info "Basic Execution Tests"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

run_check "vim basic operation" "printf ':q\n' | vim -es"
run_check "nvim headless startup" "nvim --headless '+qa'"
run_check "node basic operation" "node -e 'console.log(1+1)' | grep -qx '2'"
run_check "git bare repo exists" "[ -d '$HOME/.dotfile' ] && git --git-dir='$HOME/.dotfile' rev-parse --is-bare-repository | grep -qx 'true'"
run_check "dotfile work-tree status" "git --git-dir='$HOME/.dotfile' --work-tree='$HOME' status >/dev/null 2>&1"
run_check "dotfile remote configured" "git --git-dir='$HOME/.dotfile' remote -v | grep -q origin"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_info "Shell And Config Tests"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

run_check "bash wrapper exists" "[ -f '$HOME/.bashrc' ]"
run_check "zsh wrapper exists" "[ -f '$HOME/.zshrc' ]"
run_check "bash XDG config exists" "[ -f '$HOME/.config/bash/.bashrc' ]"
run_check "zsh XDG config exists" "[ -f '$HOME/.config/zsh/.zshrc' ]"
run_check "nvim config exists" "[ -f '$HOME/.config/nvim/init.lua' ] || [ -f '$HOME/.config/nvim/init.vim' ]"
run_check "tmux config exists" "[ -f '$HOME/.config/tmux/tmux.conf' ]"
run_check "tmux compat symlink exists" "[ -L '$HOME/.tmux.conf' ] || [ -f '$HOME/.tmux.conf' ]"
run_check "bash wrapper sources XDG config" "grep -q 'bash/.bashrc' '$HOME/.bashrc'"
run_check "zsh wrapper sources XDG config" "grep -q 'zsh/.zshrc' '$HOME/.zshrc'"
run_check "bash login can resolve dot alias" "bash -ic 'alias dot >/dev/null 2>&1'"
run_check "zsh login can resolve dot alias" "zsh -ic 'alias dot >/dev/null 2>&1'"
run_check "zsh login can resolve z command" "zsh -lic 'type z >/dev/null 2>&1'"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_info "Zsh Ecosystem Tests"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

run_check "oh-my-zsh directory exists" "[ -d '$HOME/.oh-my-zsh' ]"
run_check "oh-my-zsh bootstrap exists" "[ -f '$HOME/.oh-my-zsh/oh-my-zsh.sh' ]"
run_check "zsh-autosuggestions plugin exists" "[ -f '$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh' ]"
run_check "zsh-syntax-highlighting plugin exists" "[ -f '$HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh' ]"
run_check "zoxide hook present in zsh config" "grep -q 'zoxide init zsh' '$HOME/.config/zsh/.zshrc'"
run_check "fzf hook present in zsh config" "grep -q 'fzf --zsh' '$HOME/.config/zsh/.zshrc'"

mkdir -p /tmp/zoxide-functional-target
run_check "zoxide works in fresh login zsh" "zsh -lic 'zoxide add /tmp/zoxide-functional-target && z zoxide-functional-target && [[ \$PWD == /tmp/zoxide-functional-target ]]'"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_info "Bash/Fzf Tests"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

run_check "fzf bash config exists" "[ -f '$HOME/.config/bash/fzf.bash' ]"
run_check "bash config references fzf" "grep -q 'fzf.bash' '$HOME/.config/bash/.bashrc'"
run_check "bash login can execute fzf" "bash -ic 'command -v fzf >/dev/null 2>&1'"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_info "Tmux/TPM Tests"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

run_check "TPM directory exists" "[ -d '$HOME/.tmux/plugins/tpm' ]"
run_check "TPM script exists" "[ -f '$HOME/.tmux/plugins/tpm/tpm' ]"
run_check "tmux config sets prefix to C-a" "tmux -f '$HOME/.config/tmux/tmux.conf' start-server \\; show -gv prefix | grep -qx 'C-a'"
run_check "tmux config includes TPM plugin" "grep -q \"@plugin 'tmux-plugins/tpm'\" '$HOME/.config/tmux/tmux.conf'"

echo ""
echo "╔══════════════════════════════════════════════════════════════════════════════╗"
echo "║                           TEST SUMMARY                                      ║"
echo "╚══════════════════════════════════════════════════════════════════════════════╝"
echo ""
echo -e "${GREEN}✓ PASSED: $PASSED${NC}"
echo -e "${RED}✗ FAILED: $FAILED${NC}"
echo -e "${YELLOW}○ SKIPPED: $SKIPPED${NC}"
echo ""

total=$((PASSED + FAILED + SKIPPED))
echo "Total tests: $total"

if [ "$FAILED" -gt 0 ]; then
    echo -e "${RED}Some tests failed!${NC}"
    exit 1
fi

echo -e "${GREEN}All tests passed!${NC}"
exit 0
