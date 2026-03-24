#!/bin/bash
set -euo pipefail

GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_pass() { echo -e "${GREEN}[PASS]${NC} $1"; }
log_fail() { echo -e "${RED}[FAIL]${NC} $1"; }

TEST_REPO_DIR="/tmp/dotfile-smoke"

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
    echo "== Arch Smoke Test: install.sh -> zsh -> zoxide =="
    log_info "OS: $(grep '^PRETTY_NAME=' /etc/os-release | cut -d= -f2- | tr -d '\"')"

    clone_test_repo

    log_info "Running install.sh install with AUTO_SWITCH_SHELL=1"
    local install_exit=0
    AUTO_SWITCH_SHELL=1 bash "$TEST_REPO_DIR/install.sh" install > /tmp/install-smoke.log 2>&1 || install_exit=$?
    if [[ $install_exit -ne 0 ]]; then
        log_info "install.sh install exited with code $install_exit; continuing shell smoke checks"
        tail -60 /tmp/install-smoke.log
    else
        log_pass "install.sh install completed"
    fi

    local zsh_path
    zsh_path="$(command -v zsh || true)"
    if [[ -z "$zsh_path" ]]; then
        log_fail "zsh not available after install"
        exit 1
    fi
    log_pass "zsh installed at $zsh_path"

    local login_shell
    login_shell="$(getent passwd "$(id -un)" | cut -d: -f7)"
    if [[ "$login_shell" != "$zsh_path" ]]; then
        log_fail "default shell mismatch: expected $zsh_path, got ${login_shell:-<empty>}"
        exit 1
    fi
    log_pass "default shell switched to zsh"

    mkdir -p /tmp/zoxide-smoke-target
    if ! "$zsh_path" -lic '
        command -v zoxide >/dev/null 2>&1
        type z >/dev/null 2>&1
        zoxide add /tmp/zoxide-smoke-target
        z zoxide-smoke-target
        [[ "$PWD" == "/tmp/zoxide-smoke-target" ]]
    ' > /tmp/zoxide-smoke.log 2>&1; then
        log_fail "zoxide is not working in a fresh login zsh session"
        cat /tmp/zoxide-smoke.log
        exit 1
    fi
    log_pass "fresh login zsh session can run zoxide and z"

    if [[ $install_exit -ne 0 ]]; then
        log_info "Shell smoke passed, but install.sh reported non-zero exit code: $install_exit"
    fi

    log_info "Smoke test passed"
}

main "$@"
