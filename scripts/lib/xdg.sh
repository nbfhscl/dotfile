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
