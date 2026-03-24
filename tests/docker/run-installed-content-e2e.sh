#!/bin/bash
set -euo pipefail

GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_pass() { echo -e "${GREEN}[PASS]${NC} $1"; }
log_fail() { echo -e "${RED}[FAIL]${NC} $1"; }

TEST_REPO_DIR="/tmp/dotfile-installed-content"

clone_test_repo() {
    rm -rf "$TEST_REPO_DIR"

    if [[ -n "${LOCAL_REPO_SRC:-}" && -d "${LOCAL_REPO_SRC}/.git" ]]; then
        log_info "Copying repository from mounted workspace: $LOCAL_REPO_SRC"
        mkdir -p "$TEST_REPO_DIR"
        cp -a "$LOCAL_REPO_SRC/." "$TEST_REPO_DIR/"
        return 0
    fi

    local repo_url="${REPO_URL:-https://github.com/nbfhscl/dotfile.git}"
    log_info "Cloning repository from remote: $repo_url"
    git clone --depth 1 "$repo_url" "$TEST_REPO_DIR"
}

main() {
    echo "== Arch Full Installed Content E2E =="
    log_info "OS: $(grep '^PRETTY_NAME=' /etc/os-release | cut -d= -f2- | tr -d '\"')"

    clone_test_repo

    log_info "Running install.sh install with AUTO_SWITCH_SHELL=1"
    AUTO_SWITCH_SHELL=1 bash "$TEST_REPO_DIR/install.sh" install > /tmp/install-full-e2e.log 2>&1 || {
        log_fail "install.sh install failed"
        tail -80 /tmp/install-full-e2e.log
        exit 1
    }
    log_pass "install.sh install completed"

    log_info "Running installed-content functionality suite"
    bash "$TEST_REPO_DIR/tests/docker/test-tools-functionality.sh" || {
        log_fail "installed-content functionality suite failed"
        exit 1
    }
    log_pass "installed-content functionality suite passed"

    local zsh_path
    local login_shell
    zsh_path="$(command -v zsh)"
    login_shell="$(getent passwd "$(id -un)" | cut -d: -f7)"

    if [[ "$login_shell" != "$zsh_path" ]]; then
        log_fail "default shell mismatch: expected $zsh_path, got ${login_shell:-<empty>}"
        exit 1
    fi
    log_pass "default shell switched to zsh"

    if ! "$zsh_path" -lic 'type z >/dev/null 2>&1 && command -v zoxide >/dev/null 2>&1'; then
        log_fail "fresh login zsh session is missing zoxide integration"
        exit 1
    fi
    log_pass "fresh login zsh session includes zoxide integration"

    log_info "Full installed-content E2E passed"
}

main "$@"
