#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Show the current status of your dotfiles

.DESCRIPTION
    Displays the git status of your dotfile repository,
    showing which files have been modified, added, or deleted.

.EXAMPLE
    .\Show-DotfileStatus.ps1
#>

[CmdletBinding()]
param()

# Get the script directory
$ScriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { Get-Location }
$ModulePath = Join-Path (Split-Path -Parent $ScriptDir) ".config\powershell\modules"

# Import modules
try {
    Import-Module (Join-Path $ModulePath "DotfileInstaller.psm1") -ErrorAction Stop
} catch {
    Write-Host "[ERROR] Failed to import required modules: $_" -ForegroundColor Red
    exit 1
}

# Show status
Get-DotfileStatus
