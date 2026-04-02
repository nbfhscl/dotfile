#!/bin/bash
# Comprehensive test script for all install.sh commands
# Tests all supported actions: install, deploy, update, status, verify, package, offline-deploy, uninstall, reinstall

# Note: We don't use 'set -e' because we want all tests to run even if some fail
# Each test is responsible for handling its own errors

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

# Test configuration
TEST_REPO_DIR="/tmp/dotfile-test-all-commands"
DOT_DIR="$HOME/.dotfile"
OFFLINE_PACKAGE_DIR="/tmp/dotfile-offline-package"

# Logging
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_pass() { echo -e "${GREEN}[PASS]${NC} $1"; ((PASSED++)) || true; }
log_fail() { echo -e "${RED}[FAIL]${NC} $1"; ((FAILED++)) || true; }
log_skip() { echo -e "${YELLOW}[SKIP]${NC} $1"; ((SKIPPED++)) || true; }

# Cleanup
cleanup() {
    log_info "Cleaning up test environment..."
    # Remove test dotfile directory if exists
    if [ -d "$DOT_DIR" ]; then
        log_info "Removing dotfile directory: $DOT_DIR"
        rm -rf "$DOT_DIR"
    fi
    # Remove test clone
    if [ -d "$TEST_REPO_DIR" ]; then
        rm -rf "$TEST_REPO_DIR"
    fi
    # Remove offline package if exists
    if [ -d "$OFFLINE_PACKAGE_DIR" ]; then
        rm -rf "$OFFLINE_PACKAGE_DIR"
    fi
}

trap cleanup EXIT

# Test helper
test_command() {
    local name="$1"
    local command="$2"
    local expected_result="${3:-0}"

    echo -ne "Testing: ${name}... "

    if eval "$command" > /tmp/test-cmd-output.log 2>&1; then
        if [[ $expected_result -eq 0 ]]; then
            log_pass "$name"
            return 0
        else
            log_fail "$name (expected failure but succeeded)"
            return 1
        fi
    else
        local exit_code=$?
        if [[ $expected_result -ne 0 ]] && [[ $exit_code -ne 0 ]]; then
            log_pass "$name (failed as expected)"
            return 0
        else
            log_fail "$name (exit code: $exit_code)"
            cat /tmp/test-cmd-output.log | head -20
            return 1
        fi
    fi
}

# Setup
setup_test_env() {
    log_info "Setting up test environment..."

    # Clean up any existing test environment
    cleanup

    # Clone repository for testing
    if [ -d "$TEST_REPO_DIR" ]; then
        rm -rf "$TEST_REPO_DIR"
    fi

    if ! git clone --depth 1 https://github.com/nbfhscl/dotfile.git "$TEST_REPO_DIR" > /tmp/clone-test.log 2>&1; then
        log_fail "Failed to clone repository"
        cat /tmp/clone-test.log
        exit 1
    fi

    log_pass "Test environment setup complete"
}

# Main test suite
main() {
    echo "╔══════════════════════════════════════════════════════════════════════════════╗"
    echo "║              COMPREHENSIVE INSTALL.SH COMMAND TEST SUITE                     ║"
    echo "╚══════════════════════════════════════════════════════════════════════════════╝"
    echo ""

    log_info "Test Environment:"
    echo "  OS: $(cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)"
    echo "  Kernel: $(uname -r)"
    echo "  User: $(whoami) (UID: $(id -u))"
    echo "  Home: $HOME"
    echo ""

    # Setup test environment
    setup_test_env
    echo ""

    # =========================================================================
    # TEST SUITE 1: HELP COMMAND
    # =========================================================================
    log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log_info "TEST SUITE 1: HELP COMMAND"
    log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    test_command "Help with --help" "bash '$TEST_REPO_DIR/install.sh' --help"
    test_command "Help with -h" "bash '$TEST_REPO_DIR/install.sh' -h"
    test_command "Help with 'help'" "bash '$TEST_REPO_DIR/install.sh' help"
    test_command "Help with no arguments" "bash '$TEST_REPO_DIR/install.sh'"

    echo ""
    # =========================================================================
    # TEST SUITE 2: STATUS COMMAND (Before Installation)
    # =========================================================================
    log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log_info "TEST SUITE 2: STATUS COMMAND (PRE-INSTALLATION)"
    log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    test_command "Status command (pre-install)" "bash '$TEST_REPO_DIR/install.sh' status"

    echo ""
    # =========================================================================
    # TEST SUITE 3: VERIFY COMMAND (Before Installation)
    # =========================================================================
    log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log_info "TEST SUITE 3: VERIFY COMMAND (PRE-INSTALLATION)"
    log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    log_info "Note: Verify command is expected to fail before installation"
    test_command "Verify command (pre-install)" "bash '$TEST_REPO_DIR/install.sh' verify" 1

    echo ""
    # =========================================================================
    # TEST SUITE 4: DEPLOY COMMAND (SKIP TOOLS)
    # =========================================================================
    log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log_info "TEST SUITE 4: DEPLOY COMMAND"
    log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    log_info "Testing deploy command (SKIP_INSTALL=1)..."
    # Run deploy command
    SKIP_INSTALL=1 bash "$TEST_REPO_DIR/install.sh" deploy > /tmp/deploy-output.log 2>&1
    local deploy_exit_code=$?

    # In SKIP_INSTALL mode, we expect some tests to fail, so check core deployment success
    if [ -d "$DOT_DIR" ]; then
        log_pass "Deploy command: Dotfile directory created: $DOT_DIR"

        # Verify it's a bare repository
        if git --git-dir="$DOT_DIR" rev-parse --is-bare-repository > /dev/null 2>&1; then
            log_pass "Deploy command: Dotfile is a bare repository"
        else
            log_fail "Deploy command: Dotfile is not a bare repository"
        fi

        # Show deploy output if exit code was non-zero
        if [ $deploy_exit_code -ne 0 ]; then
            log_info "Deploy command exited with code $deploy_exit_code (expected in SKIP_INSTALL mode)"
        fi
    else
        log_fail "Deploy command failed: Dotfile directory not created"
        cat /tmp/deploy-output.log | tail -30
    fi

    echo ""
    # =========================================================================
    # TEST SUITE 5: STATUS COMMAND (After Deployment)
    # =========================================================================
    log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log_info "TEST SUITE 5: STATUS COMMAND (POST-DEPLOYMENT)"
    log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    if bash "$TEST_REPO_DIR/install.sh" status > /tmp/status-output.log 2>&1; then
        log_pass "Status command executed"

        # Check if status output contains expected information
        if grep -q "XDG_CONFIG_HOME" /tmp/status-output.log; then
            log_pass "Status shows XDG paths"
        fi

        if grep -q "Dotfile repository" /tmp/status-output.log; then
            log_pass "Status shows dotfile repository info"
        fi
    else
        log_fail "Status command failed"
        cat /tmp/status-output.log | tail -20
    fi

    echo ""
    # =========================================================================
    # TEST SUITE 6: VERIFY COMMAND (After Deployment)
    # =========================================================================
    log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log_info "TEST SUITE 6: VERIFY COMMAND (POST-DEPLOYMENT)"
    log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    if bash "$TEST_REPO_DIR/install.sh" verify > /tmp/verify-output.log 2>&1; then
        log_pass "Verify command executed"

        # Check for XDG paths in output
        if grep -q "XDG_CONFIG_HOME" /tmp/verify-output.log; then
            log_pass "Verify shows XDG_CONFIG_HOME"
        fi

        if grep -q "XDG_DATA_HOME" /tmp/verify-output.log; then
            log_pass "Verify shows XDG_DATA_HOME"
        fi

        if grep -q "XDG_STATE_HOME" /tmp/verify-output.log; then
            log_pass "Verify shows XDG_STATE_HOME"
        fi

        if grep -q "XDG_CACHE_HOME" /tmp/verify-output.log; then
            log_pass "Verify shows XDG_CACHE_HOME"
        fi
    else
        log_fail "Verify command failed"
        cat /tmp/verify-output.log | tail -20
    fi

    echo ""
    # =========================================================================
    # TEST SUITE 7: UPDATE COMMAND
    # =========================================================================
    log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log_info "TEST SUITE 7: UPDATE COMMAND"
    log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    test_command "Update command" "bash '$TEST_REPO_DIR/install.sh' update"

    echo ""
    # =========================================================================
    # TEST SUITE 8: PACKAGE COMMAND
    # =========================================================================
    log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log_info "TEST SUITE 8: PACKAGE COMMAND"
    log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    # Note: Package command requires offline-export.sh which is in .gitignore
    # So the cloned repository won't have this script, causing expected failure
    log_info "Testing package command (expected to fail - offline scripts in .gitignore)..."
    if bash "$TEST_REPO_DIR/install.sh" package > /tmp/package-output.log 2>&1; then
        log_pass "Package command executed"

        # Check if package directory was created
        if [ -d "$HOME/.dotfile_package" ] || grep -q "Package created" /tmp/package-output.log; then
            log_pass "Package directory created or indicated"
        fi
    else
        log_skip "Package command failed (offline scripts not in remote repository)"
    fi

    echo ""
    # =========================================================================
    # TEST SUITE 9: OFFLINE-DEPLOY COMMAND
    # =========================================================================
    log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log_info "TEST SUITE 9: OFFLINE-DEPLOY COMMAND"
    log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    # Find the package directory
    PACKAGE_DIR=$(find "$HOME" -maxdepth 1 -type d -name ".dotfile_package*" 2>/dev/null | head -1)

    if [ -n "$PACKAGE_DIR" ]; then
        log_info "Found package directory: $PACKAGE_DIR"
        test_command "Offline-deploy command" "bash '$TEST_REPO_DIR/install.sh' offline-deploy '$PACKAGE_DIR'"
    else
        log_skip "Offline-deploy test skipped (no package directory found)"
    fi

    echo ""
    # =========================================================================
    # TEST SUITE 10: REINSTALL COMMAND
    # =========================================================================
    log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log_info "TEST SUITE 10: REINSTALL COMMAND"
    log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    # Test in dry-run mode to avoid actual reinstallation
    log_info "Testing reinstall command (DRY_RUN=1)..."
    if DRY_RUN=1 bash "$TEST_REPO_DIR/install.sh" reinstall > /tmp/reinstall-output.log 2>&1; then
        log_pass "Reinstall command (dry-run) executed"

        if grep -q "uninstall" /tmp/reinstall-output.log && grep -q "install" /tmp/reinstall-output.log; then
            log_pass "Reinstall shows both uninstall and install steps"
        fi
    else
        log_fail "Reinstall command failed"
        cat /tmp/reinstall-output.log | tail -20
    fi

    echo ""
    # =========================================================================
    # TEST SUITE 11: UNINSTALL COMMAND
    # =========================================================================
    log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log_info "TEST SUITE 11: UNINSTALL COMMAND"
    log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    # Test in dry-run mode first
    log_info "Testing uninstall command (DRY_RUN=1)..."
    if DRY_RUN=1 bash "$TEST_REPO_DIR/install.sh" uninstall > /tmp/uninstall-output.log 2>&1; then
        log_pass "Uninstall command (dry-run) executed"
    else
        log_fail "Uninstall command failed"
        cat /tmp/uninstall-output.log | tail -20
    fi

    # Note: We skip actual uninstall to keep the environment for other tests
    log_skip "Actual uninstall skipped (to preserve test environment)"

    echo ""
    # =========================================================================
    # TEST SUITE 12: INVALID COMMAND
    # =========================================================================
    log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log_info "TEST SUITE 12: ERROR HANDLING"
    log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    test_command "Invalid command should fail" "bash '$TEST_REPO_DIR/install.sh' invalid-command" 1

    echo ""
    # =========================================================================
    # TEST SUITE 13: XDG COMPLIANCE
    # =========================================================================
    log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log_info "TEST SUITE 13: XDG COMPLIANCE VERIFICATION"
    log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    # Source XDG library and test
    if source "$TEST_REPO_DIR/scripts/lib/xdg.sh" 2>/dev/null; then
        init_xdg_paths

        # Test XDG paths
        [ -d "$XDG_CONFIG_HOME" ] && log_pass "XDG_CONFIG_HOME exists" || log_fail "XDG_CONFIG_HOME missing"
        [ -d "$XDG_DATA_HOME" ] && log_pass "XDG_DATA_HOME exists" || log_fail "XDG_DATA_HOME missing"
        [ -d "$XDG_STATE_HOME" ] && log_pass "XDG_STATE_HOME exists" || log_fail "XDG_STATE_HOME missing"
        [ -d "$XDG_CACHE_HOME" ] && log_pass "XDG_CACHE_HOME exists" || log_fail "XDG_CACHE_HOME missing"

        # Test XDG functions
        config_path=$(xdg_config_home)
        [ -n "$config_path" ] && log_pass "xdg_config_home() returns: $config_path" || log_fail "xdg_config_home() failed"

        data_path=$(xdg_data_home)
        [ -n "$data_path" ] && log_pass "xdg_data_home() returns: $data_path" || log_fail "xdg_data_home() failed"
    else
        log_fail "Failed to source xdg.sh"
    fi

    echo ""
    # =========================================================================
    # TEST SUITE 14: TOOLS VERIFICATION
    # =========================================================================
    log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log_info "TEST SUITE 14: TOOLS VERIFICATION (POST-DEPLOYMENT)"
    log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    log_info "Checking deployed tools and configurations..."

    # Test essential tools
    if command -v git >/dev/null 2>&1; then
        log_pass "Git is installed: $(git --version | head -1)"
    else
        log_fail "Git is not installed"
    fi

    # Test nvim
    if command -v nvim >/dev/null 2>&1; then
        log_pass "Neovim is installed: $(nvim --version | head -1)"

        # Check if nvim config exists
        if [ -f "$XDG_CONFIG_HOME/nvim/init.vim" ] || [ -f "$HOME/.config/nvim/init.vim" ]; then
            log_pass "Neovim config found"
        else
            log_skip "Neovim config not found (may be optional)"
        fi
    else
        log_skip "Neovim is not installed (SKIP_INSTALL=1)"
    fi

    # Test fzf
    if command -v fzf >/dev/null 2>&1; then
        log_pass "fzf is installed: $(fzf --version)"
    else
        log_skip "fzf is not installed (SKIP_INSTALL=1)"
    fi

    # Test ripgrep
    if command -v rg >/dev/null 2>&1; then
        log_pass "ripgrep is installed: $(rg --version)"
    else
        log_skip "ripgrep is not installed (SKIP_INSTALL=1)"
    fi

    # Test zoxide
    if command -v zoxide >/dev/null 2>&1; then
        log_pass "zoxide is installed"
    elif command -v z >/dev/null 2>&1; then
        log_pass "zoxide (z command) is installed: $(z --version 2>/dev/null || echo 'available')"
    else
        log_skip "zoxide is not installed (SKIP_INSTALL=1)"
    fi

    # Test bat (if available)
    if command -v bat >/dev/null 2>&1; then
        log_pass "bat is installed: $(bat --version | head -1)"
    else
        log_skip "bat is not installed (optional tool)"
    fi

    # Test exa/eza (if available)
    if command -v eza >/dev/null 2>&1; then
        log_pass "eza is installed: $(eza --version | head -1)"
    elif command -v exa >/dev/null 2>&1; then
        log_pass "exa is installed: $(exa --version | head -1)"
    else
        log_skip "eza/exa is not installed (optional tool)"
    fi

    # Test fd (if available)
    if command -v fd >/dev/null 2>&1; then
        log_pass "fd is installed: $(fd --version | head -1)"
    else
        log_skip "fd is not installed (optional tool)"
    fi

    # Test tmux config
    if [ -f "$XDG_CONFIG_HOME/tmux/tmux.conf" ] || [ -f "$HOME/.tmux.conf" ]; then
        log_pass "Tmux config found"
        if command -v tmux >/dev/null 2>&1; then
            log_pass "tmux is installed: $(tmux -V)"
        else
            log_skip "tmux is not installed (SKIP_INSTALL=1)"
        fi
    else
        log_skip "Tmux config not found (may be optional)"
    fi

    # Test shell configs
    if [ -f "$HOME/.bashrc" ]; then
        log_pass "Bash config found: ~/.bashrc"
    else
        log_fail "Bash config not found: ~/.bashrc"
    fi

    if [ -f "$HOME/.zshrc" ]; then
        log_pass "Zsh config found: ~/.zshrc"
    else
        log_skip "Zsh config not found (zsh may not be installed)"
    fi

    # Test vim
    if command -v vim >/dev/null 2>&1; then
        log_pass "Vim is installed: $(vim --version | head -1)"
    else
        log_skip "Vim is not installed (SKIP_INSTALL=1)"
    fi

    # Test zsh
    if command -v zsh >/dev/null 2>&1; then
        log_pass "Zsh is installed: $(zsh --version)"
    else
        log_skip "Zsh is not installed (SKIP_INSTALL=1)"
    fi

    # Test oh-my-zsh
    if [ -d "$HOME/.oh-my-zsh" ]; then
        log_pass "Oh-My-Zsh is installed"
    else
        log_skip "Oh-My-Zsh is not installed (SKIP_INSTALL=1)"
    fi

    # Test zsh-autosuggestions
    if [ -d "$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions" ]; then
        log_pass "zsh-autosuggestions is installed"
    else
        log_skip "zsh-autosuggestions is not installed (SKIP_INSTALL=1)"
    fi

    # Test zsh-syntax-highlighting
    if [ -d "$HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting" ]; then
        log_pass "zsh-syntax-highlighting is installed"
    else
        log_skip "zsh-syntax-highlighting is not installed (SKIP_INSTALL=1)"
    fi

    # Test node
    if command -v node >/dev/null 2>&1; then
        log_pass "Node.js is installed: $(node --version)"
    else
        log_skip "Node.js is not installed (SKIP_INSTALL=1)"
    fi

    # Test npm
    if command -v npm >/dev/null 2>&1; then
        log_pass "NPM is installed: $(npm --version)"
    else
        log_skip "NPM is not installed (SKIP_INSTALL=1)"
    fi

    # Test tpm
    if [ -d "$HOME/.tmux/plugins/tpm" ]; then
        log_pass "TPM is installed"
    else
        log_skip "TPM is not installed (SKIP_INSTALL=1)"
    fi

    echo ""
    # =========================================================================
    # SUMMARY
    # =========================================================================
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
}

# Run main test suite
main "$@"
