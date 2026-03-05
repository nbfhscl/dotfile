#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Install development tools only (no dotfile deployment)

.DESCRIPTION
    Installs Windows Terminal, PowerShell 7, Git, Node.js, Neovim,
    Oh-My-Posh, and various PowerShell modules without deploying dotfiles.

.EXAMPLE
    .\Install-Tools.ps1

.EXAMPLE
    .\Install-Tools.ps1 -DryRun
#>

[CmdletBinding()]
param(
    [switch]$DryRun = $false
)

# Get the script directory
$ScriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { Get-Location }
$ModulePath = Join-Path (Split-Path -Parent $ScriptDir) ".config\powershell\modules"

# Import modules
try {
    Import-Module (Join-Path $ModulePath "UI.psm1") -ErrorAction Stop
    Import-Module (Join-Path $ModulePath "ToolInstaller.psm1") -ErrorAction Stop
    Import-Module (Join-Path $ModulePath "Verifier.psm1") -ErrorAction Stop
} catch {
    Write-Host "[ERROR] Failed to import required modules: $_" -ForegroundColor Red
    exit 1
}

if ($DryRun) {
    Write-Host "[WARN] Dry run mode enabled" -ForegroundColor Yellow
}

# Install all development tools
Install-AllDevelopmentTools -DryRun:$DryRun

Write-Host "[SUCCESS] Development tools installation completed" -ForegroundColor Green
