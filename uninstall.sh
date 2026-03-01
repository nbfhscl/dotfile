#!/bin/bash
# uninstall.sh - 卸载由 install.sh 部署的 dotfile

set -euo pipefail

DOT_DIR="$HOME/.dotfile"
WORK_TREE="$HOME"
ALIAS_NAME="dot"
BACKUP_DIR="$HOME/.dotfile_uninstall_backup_$(date +%Y%m%d_%H%M%S)"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

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

dot() {
  git --git-dir="$DOT_DIR" --work-tree="$WORK_TREE" "$@"
}

remove_alias_from_rc() {
  local rc_file="$1"
  [ -f "$rc_file" ] || return 0

  if grep -q "alias $ALIAS_NAME='git --git-dir=\$HOME/.dotfile/ --work-tree=\$HOME'" "$rc_file"; then
    sed -i "\|alias $ALIAS_NAME='git --git-dir=\$HOME/.dotfile/ --work-tree=\$HOME'|d" "$rc_file"
    log "Removed '$ALIAS_NAME' alias from $rc_file"
  fi
}

if ! command -v git >/dev/null 2>&1; then
  error "Git is not installed."
fi

if [ ! -d "$DOT_DIR" ]; then
  error "No .dotfile repository found at $DOT_DIR."
fi

if ! dot rev-parse --is-bare-repository >/dev/null 2>&1; then
  error "$DOT_DIR is not a valid bare git repository."
fi

log "Collecting tracked files from dotfile repository..."
tracked_files="$(dot ls-tree -r --name-only HEAD || true)"

if [ -n "$tracked_files" ]; then
  mkdir -p "$BACKUP_DIR"
  log "Backing up tracked files to: $BACKUP_DIR"

  while IFS= read -r file; do
    [ -n "$file" ] || continue
    src="$WORK_TREE/$file"
    dst="$BACKUP_DIR/$file"
    if [ -e "$src" ] || [ -L "$src" ]; then
      mkdir -p "$(dirname "$dst")"
      cp -a "$src" "$dst"
      rm -rf "$src"
      echo "  → removed $file"
    fi
  done <<< "$tracked_files"
else
  warn "No tracked files found at HEAD. Skipping file removal."
fi

log "Removing bare repository at $DOT_DIR"
rm -rf "$DOT_DIR"

remove_alias_from_rc "$HOME/.zshrc"
remove_alias_from_rc "$HOME/.bashrc"
remove_alias_from_rc "$HOME/.profile"

log "Dotfile uninstalled successfully."
if [ -d "$BACKUP_DIR" ]; then
  log "Backup saved to: $BACKUP_DIR"
fi
