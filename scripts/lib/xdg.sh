#!/bin/bash

# Shared XDG path helpers for Unix entrypoints.
# Follows XDG Base Directory Specification:
# https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html

# ============================================================================
# XDG Path Getters
# ============================================================================

xdg_config_home() {
  echo "${XDG_CONFIG_HOME:-$HOME/.config}"
}

xdg_data_home() {
  echo "${XDG_DATA_HOME:-$HOME/.local/share}"
}

xdg_state_home() {
  echo "${XDG_STATE_HOME:-$HOME/.local/state}"
}

xdg_cache_home() {
  echo "${XDG_CACHE_HOME:-$HOME/.cache}"
}

# ============================================================================
# XDG Path Initialization
# ============================================================================

init_xdg_paths() {
  local config_home data_home state_home cache_home

  config_home="$(xdg_config_home)"
  data_home="$(xdg_data_home)"
  state_home="$(xdg_state_home)"
  cache_home="$(xdg_cache_home)"

  mkdir -p "$config_home" "$data_home" "$state_home" "$cache_home"

  export XDG_CONFIG_HOME="$config_home"
  export XDG_DATA_HOME="$data_home"
  export XDG_STATE_HOME="$state_home"
  export XDG_CACHE_HOME="$cache_home"
}

# ============================================================================
# XDG Status Display
# ============================================================================

print_xdg_status() {
  echo "XDG_CONFIG_HOME=$XDG_CONFIG_HOME"
  echo "XDG_DATA_HOME=$XDG_DATA_HOME"
  echo "XDG_STATE_HOME=$XDG_STATE_HOME"
  echo "XDG_CACHE_HOME=$XDG_CACHE_HOME"
}

# ============================================================================
# Legacy Config Migration
# ============================================================================

# Detect if legacy configuration exists
detect_legacy_config() {
  local legacy_path="$1"
  if [[ -e "$legacy_path" ]]; then
    return 0  # Legacy config found
  fi
  return 1  # No legacy config
}

# Migrate legacy configuration to XDG path
# Usage: migrate_legacy_config <source> <target> [backup_dir]
migrate_legacy_config() {
  local source="$1"
  local target="$2"
  local backup_dir="${3:-$HOME/.dotfile_backup_$(date +%Y%m%d_%H%M%S)}"

  # Source must exist
  if [[ ! -e "$source" ]]; then
    return 0  # Nothing to migrate
  fi

  # Create target directory
  local target_dir
  target_dir="$(dirname "$target")"
  mkdir -p "$target_dir"

  # If target already exists, backup it
  if [[ -e "$target" ]]; then
    mkdir -p "$backup_dir"
    local backup_path="$backup_dir/$(basename "$target")"
    mv "$target" "$backup_path"
  fi

  # Move source to target
  mv "$source" "$target"

  # Create symlink for backward compatibility
  ln -s "$target" "$source"
}

# Create XDG-compliant symlink for legacy path
# Usage: create_xdg_compat_symlink <xdg_path> <legacy_path>
create_xdg_compat_symlink() {
  local xdg_path="$1"
  local legacy_path="$2"

  # If legacy path exists and is not a symlink, back it up
  if [[ -e "$legacy_path" && ! -L "$legacy_path" ]]; then
    local backup_dir="$HOME/.dotfile_backup_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$backup_dir"
    mv "$legacy_path" "$backup_dir/"
  fi

  # Create symlink if it doesn't exist
  if [[ ! -e "$legacy_path" ]]; then
    ln -s "$xdg_path" "$legacy_path"
  fi
}

# ============================================================================
# XDG Compliance Verification
# ============================================================================

# Verify that XDG paths are properly set and directories exist
verify_xdg_paths() {
  local errors=0

  for var in XDG_CONFIG_HOME XDG_DATA_HOME XDG_STATE_HOME XDG_CACHE_HOME; do
    if [[ -z "${!var}" ]]; then
      echo "Error: $var is not set" >&2
      ((errors++))
    elif [[ ! -d "${!var}" ]]; then
      echo "Error: $var (${!var}) is not a directory" >&2
      ((errors++))
    fi
  done

  return $errors
}

# Check if a specific config uses XDG paths
# Usage: is_xdg_compliant <app_name>
is_xdg_compliant() {
  local app_name="$1"
  local xdg_config="$XDG_CONFIG_HOME/$app_name"
  local legacy_config="$HOME/.$app_name"
  local legacy_file="$HOME/${app_name}rc"

  # Check if using XDG path
  if [[ -d "$xdg_config" || -f "$xdg_config" ]]; then
    return 0  # Compliant
  fi

  # Check if still using legacy path
  if [[ -d "$legacy_config" || -f "$legacy_config" || -f "$legacy_file" ]]; then
    return 1  # Non-compliant
  fi

  # No config found (neutral)
  return 2
}

# ============================================================================
# XDG Structure Setup
# ============================================================================

# Ensure proper XDG directory structure for an application
# Usage: ensure_xdg_app_structure <app_name> [subdirs...]
ensure_xdg_app_structure() {
  local app_name="$1"
  shift
  local subdirs=("$@")

  local config_dir="$XDG_CONFIG_HOME/$app_name"
  local data_dir="$XDG_DATA_HOME/$app_name"
  local state_dir="$XDG_STATE_HOME/$app_name"
  local cache_dir="$XDG_CACHE_HOME/$app_name"

  mkdir -p "$config_dir" "$data_dir" "$state_dir" "$cache_dir"

  # Create subdirectories if specified
  for subdir in "${subdirs[@]}"; do
    local target_dir
    case "$subdir" in
      config:*)
        target_dir="$config_dir/${subdir#config:}"
        ;;
      data:*)
        target_dir="$data_dir/${subdir#data:}"
        ;;
      state:*)
        target_dir="$state_dir/${subdir#state:}"
        ;;
      cache:*)
        target_dir="$cache_dir/${subdir#cache:}"
        ;;
      *)
        target_dir="$config_dir/$subdir"
        ;;
    esac
    mkdir -p "$target_dir"
  done
}
