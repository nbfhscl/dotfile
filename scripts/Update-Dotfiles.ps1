#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Update existing dotfile installation

.DESCRIPTION
    Fetches the latest changes from the dotfile repository
    and deploys them to your home directory.

.EXAMPLE
    .\Update-Dotfiles.ps1

.EXAMPLE
    .\Update-Dotfiles.ps1 -Verbose
#>

[CmdletBinding()]
param()

# Get the script directory
$ScriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { Get-Location }
$ModulePath = Join-Path (Split-Path -Parent $ScriptDir) ".config\powershell\modules"

# Import modules
try {
    Import-Module (Join-Path $ModulePath "UI.psm1") -ErrorAction Stop
    Import-Module (Join-Path $ModulePath "DotfileInstaller.psm1") -ErrorAction Stop
} catch {
    Write-Host "[ERROR] Failed to import required modules: $_" -ForegroundColor Red
    exit 1
}

# Update dotfiles
$result = Update-Dotfiles

if ($result) {
    Write-Host "[INFO] You may need to reload your profile: . \$PROFILE" -ForegroundColor Cyan
} else {
    Write-Host "[ERROR] Update failed. Check the error messages above." -ForegroundColor Red
    exit 1
}
