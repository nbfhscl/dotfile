#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Verify all configurations are properly set up

.DESCRIPTION
    Checks environment, verifies tool installations, and validates
    configuration files are in their correct locations.

.EXAMPLE
    .\Verify-Configuration.ps1

.EXAMPLE
    .\Verify-Configuration.ps1 -Verbose
#>

[CmdletBinding()]
param()

# Get the script directory
$ScriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { Get-Location }
$ModulePath = Join-Path (Split-Path -Parent $ScriptDir) ".config\powershell\modules"

# Import modules
try {
    Import-Module (Join-Path $ModulePath "UI.psm1") -ErrorAction Stop
    Import-Module (Join-Path $ModulePath "Verifier.psm1") -ErrorAction Stop
    Import-Module (Join-Path $ModulePath "DotfileInstaller.psm1") -ErrorAction Stop
} catch {
    Write-Host "[ERROR] Failed to import required modules: $_" -ForegroundColor Red
    exit 1
}

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Configuration Verification Report" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# Environment checks
Test-Environment

Write-Host "`n----------------------------------------" -ForegroundColor Cyan
Write-Host "Tool Installation Status" -ForegroundColor Cyan
Write-Host "----------------------------------------`n" -ForegroundColor Cyan

# Tool verification
Verify-AllTools

Write-Host "`n----------------------------------------" -ForegroundColor Cyan
Write-Host "Dotfile Status" -ForegroundColor Cyan
Write-Host "----------------------------------------`n" -ForegroundColor Cyan

# Dotfile status
Get-DotfileStatus

Write-Host "`n----------------------------------------" -ForegroundColor Cyan
Write-Host "Configuration Paths" -ForegroundColor Cyan
Write-Host "----------------------------------------`n" -ForegroundColor Cyan

# Show key paths
Write-Host "XDG_CONFIG_HOME: $env:XDG_CONFIG_HOME" -ForegroundColor $(if ($env:XDG_CONFIG_HOME) { "Green" } else { "Yellow" })
Write-Host "XDG_DATA_HOME:   $env:XDG_DATA_HOME" -ForegroundColor $(if ($env:XDG_DATA_HOME) { "Green" } else { "Yellow" })
Write-Host "PowerShell Profile: $($PROFILE.CurrentUserCurrentHost)" -ForegroundColor Cyan

# Check Neovim config
Write-Host "`n----------------------------------------" -ForegroundColor Cyan
Write-Host "Neovim Configuration" -ForegroundColor Cyan
Write-Host "----------------------------------------`n" -ForegroundColor Cyan

Verify-NeovimConfig

Write-Host "`n========================================" -ForegroundColor Green
Write-Host "Verification Complete" -ForegroundColor Green
Write-Host "========================================`n" -ForegroundColor Green
