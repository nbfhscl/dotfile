#!/usr/bin/env bats

setup() {
  REPO_ROOT="/home/arch/develop/dotfile"
}

@test "install.sh help advertises the unified lifecycle actions" {
  run bash "$REPO_ROOT/install.sh" --help

  [ "$status" -eq 0 ]
  [[ "$output" == *"install"* ]]
  [[ "$output" == *"deploy"* ]]
  [[ "$output" == *"update"* ]]
  [[ "$output" == *"status"* ]]
  [[ "$output" == *"verify"* ]]
  [[ "$output" == *"package"* ]]
  [[ "$output" == *"offline-deploy"* ]]
  [[ "$output" == *"uninstall"* ]]
  [[ "$output" == *"reinstall"* ]]
}

@test "install.sh status reports XDG paths in dry-run mode" {
  mkdir -p "$BATS_TEST_TMPDIR/home"

  run env HOME="$BATS_TEST_TMPDIR/home" DRY_RUN=1 bash "$REPO_ROOT/install.sh" status

  [ "$status" -eq 0 ]
  [[ "$output" == *"XDG_CONFIG_HOME"* ]]
  [[ "$output" == *"$BATS_TEST_TMPDIR/home/.config"* ]]
  [[ "$output" == *"XDG_DATA_HOME"* ]]
  [[ "$output" == *"$BATS_TEST_TMPDIR/home/.local/share"* ]]
}

@test "install.sh reinstall previews uninstall and install steps in dry-run mode" {
  mkdir -p "$BATS_TEST_TMPDIR/home/.dotfile"

  run env HOME="$BATS_TEST_TMPDIR/home" DRY_RUN=1 bash "$REPO_ROOT/install.sh" reinstall

  [ "$status" -eq 0 ]
  [[ "$output" == *"Would uninstall tracked dotfiles"* ]]
  [[ "$output" == *"Would install required tools"* ]]
}

@test "install.ps1 action contract includes uninstall and reinstall" {
  run grep -F '[ValidateSet("Install", "Deploy", "Update", "Status", "Verify", "Package", "OfflineDeploy", "Uninstall", "Reinstall")]' \
    "$REPO_ROOT/install.ps1"

  [ "$status" -eq 0 ]
}

@test "install.ps1 help text does not advertise invalid or removed entrypoints" {
  run grep -nE 'Action Help|Deploy-To-Offline-Machine\.ps1|Package-Offline-Installer\.ps1' \
    "$REPO_ROOT/install.ps1"

  [ "$status" -ne 0 ]
}

@test "DotfileInstaller exposes update and status flags on Initialize-DotfileRepo" {
  run grep -F 'param(' -A 6 "$REPO_ROOT/.config/powershell/modules/DotfileInstaller.psm1"

  [ "$status" -eq 0 ]
  [[ "$output" == *'[switch]$Update'* ]]
  [[ "$output" == *'[switch]$StatusOnly'* ]]
}

@test "DotfileInstaller provides a shared Invoke-DotCommand helper" {
  run grep -F 'function Invoke-DotCommand' "$REPO_ROOT/.config/powershell/modules/DotfileInstaller.psm1"

  [ "$status" -eq 0 ]
}

@test "install.ps1 uninstall path no longer passes unsupported quiet parameters" {
  run grep -F 'Invoke-QuickUninstall -Force -Quiet:$Quiet -RemoveBackups:$RemoveBackups' "$REPO_ROOT/install.ps1"

  [ "$status" -ne 0 ]
}

@test "install.ps1 status path uses Invoke-DotCommand instead of session-only dot alias" {
  run grep -F '$status = Invoke-DotCommand status --porcelain' "$REPO_ROOT/install.ps1"

  [ "$status" -eq 0 ]
}

@test "install.ps1 update path resets the bare repository to the remote default ref before deploy" {
  run grep -F 'Invoke-DotCommand reset --hard $targetRef' "$REPO_ROOT/install.ps1"

  [ "$status" -eq 0 ]
}

@test "install.ps1 uninstall path uses custom uninstall mapping" {
  run grep -F 'Invoke-CustomUninstall' "$REPO_ROOT/install.ps1"

  [ "$status" -eq 0 ]
}

@test "install.ps1 can clear uninstall backups when requested" {
  run grep -F 'Clear-UninstallBackups -Force:$Force' "$REPO_ROOT/install.ps1"

  [ "$status" -eq 0 ]
}

@test "offline package installer is built around bundled module installation" {
  run grep -F 'function Install-BundledModules' "$REPO_ROOT/install.ps1"

  [ "$status" -eq 0 ]
}

@test "offline package installer no longer uses online Install-Module bootstrap" {
  run grep -F 'Install-Module -Name `$_.Name' "$REPO_ROOT/install.ps1"

  [ "$status" -ne 0 ]
}

@test "offline deploy delegates to the bundled offline installer script" {
  run grep -F '& $offlineInstallerPath -SkipTools:$SkipTools -OnlyDotfile:$OnlyDotfile -DryRun:$DryRun' "$REPO_ROOT/install.ps1"

  [ "$status" -eq 0 ]
}

@test "install.sh package delegates to offline-export.sh instead of export.sh" {
  run grep -F 'local package_script="$ROOT_DIR/scripts/offline-export.sh"' "$REPO_ROOT/install.sh"

  [ "$status" -eq 0 ]
}

@test "offline-export.sh supports non-interactive confirmation via AUTO_YES" {
  run grep -F 'AUTO_YES="${AUTO_YES:-}"' "$REPO_ROOT/scripts/offline-export.sh"

  [ "$status" -eq 0 ]
}
