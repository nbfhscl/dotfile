#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Deploy dotfiles only (skip tool installation)

.DESCRIPTION
    Clones and deploys the dotfile repository without installing any tools.
    Useful for updating existing dotfiles or deploying to a new system
    where tools are already installed.

.EXAMPLE
    .\Deploy-Dotfiles.ps1

.EXAMPLE
    .\Deploy-Dotfiles.ps1 -SkipBackup
#>

[CmdletBinding()]
param(
    [switch]$SkipBackup = $false
)

# Get the script directory
$ScriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { Get-Location }
$ModulePath = Join-Path (Split-Path -Parent $ScriptDir) ".config\powershell\modules"
$RepoRoot = Split-Path -Parent $ScriptDir

# Import modules
try {
    Import-Module (Join-Path $ModulePath "UI.psm1") -ErrorAction Stop
    Import-Module (Join-Path $ModulePath "DotfileInstaller.psm1") -ErrorAction Stop
    Import-Module (Join-Path $ModulePath "ConfigDeployer.psm1") -ErrorAction Stop
} catch {
    Write-Host "[ERROR] Failed to import required modules: $_" -ForegroundColor Red
    exit 1
}

# Change to repo root
Push-Location $RepoRoot

try {
    Write-Host "[INFO] Starting dotfile deployment" -ForegroundColor Cyan

    # Initialize and deploy
    Initialize-DotfileRepo
    Deploy-Dotfiles -SkipBackup:$SkipBackup
    Add-DotAliasToProfile

    Write-Host "[SUCCESS] Dotfiles deployed successfully" -ForegroundColor Green
    Write-Host "[INFO] Run '. \$PROFILE' or restart PowerShell to apply changes" -ForegroundColor Cyan
} finally {
    Pop-Location
}
