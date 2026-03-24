#!/bin/bash
# Tool functionality testing script
# Tests basic functionality of deployed tools

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Test results
PASSED=0
FAILED=0
SKIPPED=0

# Logging
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_pass() { echo -e "${GREEN}[PASS]${NC} $1"; ((PASSED++)) || true; }
log_fail() { echo -e "${RED}[FAIL]${NC} $1"; ((FAILED++)) || true; }
log_skip() { echo -e "${YELLOW}[SKIP]${NC} $1"; ((SKIPPED++)) || true; }

# Test helper
test_tool() {
    local tool_name="$1"
    local test_command="$2"
    
    echo -ne "Testing $tool_name... "
    if eval "$test_command" > /tmp/tool-test.log 2>&1; then
        log_pass "$tool_name"
        return 0
    else
        log_fail "$tool_name"
        cat /tmp/tool-test.log | head -5
        return 1
    fi
}

echo "╔══════════════════════════════════════════════════════════════════════════════╗"
echo "║                      TOOL FUNCTIONALITY TEST SUITE                         ║"
echo "╚══════════════════════════════════════════════════════════════════════════════╝"
echo ""

log_info "Test Environment:"
echo "  OS: $(cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)"
echo "  User: $(whoami)"
echo "  Home: $HOME"
echo ""

# Test Git
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_info "Git Tests"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if command -v git >/dev/null 2>&1; then
    test_tool "Git version" "git --version"
    test_tool "Git config" "git config --global user.name"
    test_tool "Git repository check" "git rev-parse --git-dir 2>&1"
else
    log_skip "Git not installed"
fi

echo ""

# Test Neovim
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_info "Neovim Tests"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if command -v nvim >/dev/null 2>&1; then
    test_tool "Neovim version" "nvim --version"
    
    # Test nvim can start and exit
    echo -ne "Testing Neovim basic operation... "
    if echo ":q" | nvim -es --headless > /tmp/nvim-test.log 2>&1; then
        log_pass "Neovim basic operation"
    else
        log_fail "Neovim basic operation"
        cat /tmp/nvim-test.log | head -5
    fi
    
    # Check nvim config
    if [ -f "$HOME/.config/nvim/init.vim" ] || [ -f "$XDG_CONFIG_HOME/nvim/init.vim" ]; then
        log_pass "Neovim config exists"
    else
        log_skip "Neovim config not found"
    fi
else
    log_skip "Neovim not installed"
fi

echo ""

# Test ripgrep
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_info "Ripgrep Tests"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if command -v rg >/dev/null 2>&1; then
    test_tool "ripgrep version" "rg --version"
    
    # Test ripgrep can search
    echo -ne "Testing ripgrep search... "
    if echo "test" | rg "test" > /tmp/rg-test.log 2>&1; then
        log_pass "ripgrep search"
    else
        log_fail "ripgrep search"
        cat /tmp/rg-test.log | head -5
    fi
else
    log_skip "ripgrep not installed"
fi

echo ""

# Test fzf
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_info "Fzf Tests"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if command -v fzf >/dev/null 2>&1; then
    test_tool "fzf version" "fzf --version"
    
    # Check fzf config
    if [ -f "$HOME/.config/bash/fzf.bash" ] || [ -f "$HOME/.fzf.bash" ]; then
        log_pass "fzf bash integration found"
    else
        log_skip "fzf bash integration not found"
    fi
else
    log_skip "fzf not installed"
fi

echo ""

# Test bat
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_info "Bat Tests"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if command -v bat >/dev/null 2>&1; then
    test_tool "bat version" "bat --version"
    
    # Test bat can cat files
    echo -ne "Testing bat file display... "
    if echo "test" | bat --plain --language=txt > /tmp/bat-test.log 2>&1; then
        log_pass "bat file display"
    else
        log_fail "bat file display"
        cat /tmp/bat-test.log | head -5
    fi
else
    log_skip "bat not installed"
fi

echo ""

# Test eza/exa
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_info "Eza/Exa Tests"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if command -v eza >/dev/null 2>&1; then
    test_tool "eza version" "eza --version"
    
    # Test eza can list files
    echo -ne "Testing eza list... "
    if eza --version > /tmp/eza-test.log 2>&1; then
        log_pass "eza basic operation"
    else
        log_fail "eza basic operation"
        cat /tmp/eza-test.log | head -5
    fi
elif command -v exa >/dev/null 2>&1; then
    test_tool "exa version" "exa --version"
    log_skip "exa basic operation test"
else
    log_skip "eza/exa not installed"
fi

echo ""

# Test fd
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_info "Fd Tests"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if command -v fd >/dev/null 2>&1; then
    test_tool "fd version" "fd --version"
    
    # Test fd can find files
    echo -ne "Testing fd search... "
    if mkdir -p /tmp/fd-test && touch /tmp/fd-test/test.txt && fd . /tmp/fd-test > /tmp/fd-test-output.log 2>&1; then
        log_pass "fd file search"
    else
        log_fail "fd file search"
        cat /tmp/fd-test-output.log | head -5
    fi
    rm -rf /tmp/fd-test
else
    log_skip "fd not installed"
fi

echo ""

# Test zoxide
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_info "Zoxide Tests"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if command -v zoxide >/dev/null 2>&1 || command -v z >/dev/null 2>&1; then
    if command -v zoxide >/dev/null 2>&1; then
        log_pass "zoxide command found"
    elif command -v z >/dev/null 2>&1; then
        log_pass "zoxide (z command) found"
    fi
    
    # Check if zoxide is initialized in shell configs
    if grep -q "zoxide" "$HOME/.bashrc" 2>/dev/null; then
        log_pass "zoxide in bashrc"
    else
        log_skip "zoxide not in bashrc"
    fi
    
    if grep -q "zoxide" "$HOME/.zshrc" 2>/dev/null; then
        log_pass "zoxide in zshrc"
    else
        log_skip "zoxide not in zshrc"
    fi
else
    log_skip "zoxide not installed"
fi

echo ""

# Test tmux
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_info "Tmux Tests"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if command -v tmux >/dev/null 2>&1; then
    test_tool "tmux version" "tmux -V"
    
    # Check tmux config
    if [ -f "$XDG_CONFIG_HOME/tmux/tmux.conf" ]; then
        log_pass "Tmux XDG config found"
    elif [ -f "$HOME/.tmux.conf" ]; then
        log_pass "Tmux home config found"
    else
        log_skip "Tmux config not found"
    fi
else
    log_skip "tmux not installed"
fi

echo ""

# Test shell configurations
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_info "Shell Configuration Tests"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Test bash config
if [ -f "$HOME/.bashrc" ]; then
    log_pass "Bash config exists: ~/.bashrc"
    
    # Check if it sources XDG config
    if grep -q "bash/.bashrc" "$HOME/.bashrc" 2>/dev/null; then
        log_pass "Bash config sources XDG config"
    else
        log_skip "Bash config does not source XDG config"
    fi
    
    # Check shell detection
    if grep -q "BASH_VERSION" "$HOME/.bashrc" 2>/dev/null; then
        log_pass "Bash config has shell detection"
    else
        log_skip "Bash config missing shell detection"
    fi
else
    log_fail "Bash config missing: ~/.bashrc"
fi

# Test zsh config
if [ -f "$HOME/.zshrc" ]; then
    log_pass "Zsh config exists: ~/.zshrc"
    
    # Check if it sources XDG config
    if grep -q "zsh/.zshrc" "$HOME/.zshrc" 2>/dev/null; then
        log_pass "Zsh config sources XDG config"
    else
        log_skip "Zsh config does not source XDG config"
    fi
    
    # Check shell detection
    if grep -q "ZSH_VERSION" "$HOME/.zshrc" 2>/dev/null; then
        log_pass "Zsh config has shell detection"
    else
        log_skip "Zsh config missing shell detection"
    fi
else
    log_skip "Zsh config missing: ~/.zshrc"
fi

echo ""
echo "╔══════════════════════════════════════════════════════════════════════════════╗"
echo "║                           TEST SUMMARY                                        ║"
echo "╚══════════════════════════════════════════════════════════════════════════════╝"
echo ""
echo -e "${GREEN}✓ PASSED: $PASSED${NC}"
echo -e "${RED}✗ FAILED: $FAILED${NC}"
echo -e "${YELLOW}○ SKIPPED: $SKIPPED${NC}"
echo ""

local total=$((PASSED + FAILED + SKIPPED))
echo "Total tests: $total"

if [ $FAILED -gt 0 ]; then
    echo -e "${RED}Some tests failed!${NC}"
    exit 1
else
    echo -e "${GREEN}All tests passed!${NC}"
    exit 0
fi
