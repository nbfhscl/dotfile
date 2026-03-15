#!/bin/bash

# Shared lifecycle action contract for Unix entrypoints.

readonly DOTFILE_ACTIONS=(
  "install"
  "deploy"
  "update"
  "status"
  "verify"
  "package"
  "offline-deploy"
  "uninstall"
  "reinstall"
)

is_supported_action() {
  local requested_action=$1
  local action

  for action in "${DOTFILE_ACTIONS[@]}"; do
    if [ "$action" = "$requested_action" ]; then
      return 0
    fi
  done

  return 1
}
