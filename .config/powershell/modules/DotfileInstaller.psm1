# ============================================
# DotfileInstaller Module - Dotfile Management Functions
# ============================================

<#
.SYNOPSIS
    Provides functions for managing dotfile repository and deployment.

.DESCRIPTION
    This module handles the bare git repository setup for dotfiles,
    including initialization, deployment, backup of existing configs,
    and the 'dot' command alias.

.EXPORTED FUNCTIONS
    Initialize-DotfileRepo, Deploy-Dotfiles, Add-DotAliasToProfile,
    Backup-ExistingConfig, Get-DotfileStatus, Update-Dotfiles
#>

# Import UI module for output functions
Import-Module (Join-Path $PSScriptRoot 'UI.psm1') -ErrorAction SilentlyContinue

# Configuration variables
$script:Config = @{
    RepoUrl    = "https://github.com/nbfhscl/dotfile.git"
    DotDir     = "$env:USERPROFILE\.dotfile"
    AliasName  = "dot"
}

<#
.SYNOPSIS
    Get the current dotfile configuration.

.DESCRIPTION
    Returns a hashtable containing the current dotfile configuration settings.

.EXAMPLE
    Get-DotfileConfig
#>
function Get-DotfileConfig {
    [CmdletBinding()]
    param()

    return $script:Config.Clone()
}

<#
.SYNOPSIS
    Set or update dotfile configuration.

.PARAMETER RepoUrl
    The git repository URL for the dotfiles.

.PARAMETER DotDir
    The local directory for the bare dotfile repository.

.PARAMETER AliasName
    The name of the alias function (default: "dot").

.EXAMPLE
    Set-DotfileConfig -DotDir "$env:USERPROFILE\.mydotfiles"
#>
function Set-DotfileConfig {
    [CmdletBinding()]
    param(
        [string]$RepoUrl,
        [string]$DotDir,
        [string]$AliasName
    )

    if ($RepoUrl) { $script:Config.RepoUrl = $RepoUrl }
    if ($DotDir) { $script:Config.DotDir = $DotDir }
    if ($AliasName) { $script:Config.AliasName = $AliasName }
}

<#
.SYNOPSIS
    Initialize or update the dotfile bare repository.

.DESCRIPTION
    Clones the dotfile repository as a bare git repo if it doesn't exist.
    If it already exists, updates it by fetching from the remote.

.EXAMPLE
    Initialize-DotfileRepo
#>
function Initialize-DotfileRepo {
    [CmdletBinding()]
    param()

    $dotDir = $script:Config.DotDir
    $repoUrl = $script:Config.RepoUrl

    if (Test-Path $dotDir) {
        Write-WarningCustom ".dotfile directory already exists, will update instead of cloning"
        Push-Location $dotDir
        & git fetch origin 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Success "dotfile repository update completed"
        } else {
            Write-WarningCustom "Update failed, will continue with existing version"
        }
        Pop-Location
    } else {
        Write-Info "Cloning dotfile repository..."
        & git clone --bare $repoUrl $dotDir 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Success "dotfile repository clone completed"
        } else {
            Write-ErrorCustom "Failed to clone dotfile repository"
            throw "Failed to clone dotfile repository from $repoUrl"
        }
    }
}

<#
.SYNOPSIS
    Backup existing configuration files.

.DESCRIPTION
    Creates backups of existing files that conflict with dotfile deployment.

.PARAMETER ConflictList
    List of files to back up.

.PARAMETER BackupDir
    Directory to store backups (optional, auto-generated if not specified).

.EXAMPLE
    Backup-ExistingConfig -ConflictList @(".vimrc", ".gitconfig")
#>
function Backup-ExistingConfig {
    [CmdletBinding()]
    param(
        [string[]]$ConflictList,
        [string]$BackupDir
    )

    if (-not $BackupDir) {
        $BackupDir = "$env:USERPROFILE\.dotfile_backup_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
    }

    if ($ConflictList.Count -eq 0) {
        return
    }

    Write-WarningCustom "Found $($ConflictList.Count) conflicting files, will backup..."
    New-Item -ItemType Directory -Path $BackupDir -Force | Out-Null

    foreach ($file in $ConflictList) {
        $sourcePath = Join-Path $env:USERPROFILE $file
        $backupPath = Join-Path $BackupDir $file
        $backupDir = Split-Path -Parent $backupPath

        if (-not (Test-Path $backupDir)) {
            New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
        }

        Copy-Item $sourcePath $backupPath -Force
        Write-Info "  -> Backup: $file"
    }

    Write-Success "Backup saved to: $BackupDir"
    return $BackupDir
}

<#
.SYNOPSIS
    Deploy dotfiles from the bare repository.

.DESCRIPTION
    Checks out all files from the dotfile repository to the user's home directory.
    Handles conflicts by backing up existing files before deployment.

.PARAMETER SkipBackup
    Skip creating backups of existing files.

.EXAMPLE
    Deploy-Dotfiles
#>
function Deploy-Dotfiles {
    [CmdletBinding()]
    param(
        [switch]$SkipBackup = $false
    )

    Write-Info "Deploying dotfile..."

    $dotDir = $script:Config.DotDir

    # Create a temporary function for dot operations
    function Invoke-DotCommand {
        & git --git-dir="$dotDir" --work-tree="$env:USERPROFILE" $args
    }

    # Check for file conflicts
    Write-Info "Checking for file conflicts..."
    $trackedFiles = Invoke-DotCommand ls-tree -r --name-only HEAD 2>$null
    $conflicts = @()

    foreach ($file in $trackedFiles) {
        $targetPath = Join-Path $env:USERPROFILE $file
        if (Test-Path $targetPath) {
            $conflicts += $file
        }
    }

    # Backup existing files if there are conflicts
    if ($conflicts.Count -gt 0 -and -not $SkipBackup) {
        Backup-ExistingConfig -ConflictList $conflicts
    } elseif ($conflicts.Count -gt 0 -and $SkipBackup) {
        Write-WarningCustom "Found $($conflicts.Count) conflicts but backup is skipped"
    } else {
        Write-Success "No conflicts found"
    }

    # Deploy dotfiles
    Write-Info "Deploying dotfile..."
    Invoke-DotCommand checkout -f 2>$null

    if ($LASTEXITCODE -eq 0) {
        Write-Success "dotfile deployment completed"
        Invoke-DotCommand config --local status.showUntrackedFiles no
        return $true
    } else {
        Write-ErrorCustom "dotfile deployment failed"
        return $false
    }
}

<#
.SYNOPSIS
    Add the 'dot' alias function to the PowerShell profile.

.DESCRIPTION
    Adds a wrapper function for git that uses the dotfile bare repository.
    Only adds if the function doesn't already exist in the profile.

.EXAMPLE
    Add-DotAliasToProfile
#>
function Add-DotAliasToProfile {
    [CmdletBinding()]
    param()

    $profilePath = $PROFILE.CurrentUserCurrentHost
    $dotDir = $script:Config.DotDir
    $aliasName = $script:Config.AliasName

    $aliasLine = "function $aliasName { git --git-dir=`$dotDir --work-tree=`$env:USERPROFILE `$args }"

    if (-not (Test-Path $profilePath)) {
        Write-Info "Profile does not exist yet, alias will be added when profile is created"
        return
    }

    $profileContent = Get-Content $profilePath -Raw
    if ($profileContent -notmatch "function $aliasName") {
        Write-Info "Adding '$aliasName' alias to PowerShell Profile..."
        Add-Content -Path $profilePath -Value "`n# dotfile alias (auto-added)`n$aliasLine"
        Write-Success "'$aliasName' alias added"
    } else {
        Write-Info "'$aliasName' alias already exists in profile"
    }
}

<#
.SYNOPSIS
    Get the current status of the dotfile repository.

.DESCRIPTION
    Shows the git status of the dotfile bare repository.

.EXAMPLE
    Get-DotfileStatus
#>
function Get-DotfileStatus {
    [CmdletBinding()]
    param()

    $dotDir = $script:Config.DotDir

    if (-not (Test-Path $dotDir)) {
        Write-WarningCustom "Dotfile repository not found at: $dotDir"
        return
    }

    Write-Info "Dotfile repository status:"
    & git --git-dir="$dotDir" --work-tree="$env:USERPROFILE" status
}

<#
.SYNOPSIS
    Update the existing dotfile installation.

.DESCRIPTION
    Fetches the latest changes from the remote repository and deploys them.

.EXAMPLE
    Update-Dotfiles
#>
function Update-Dotfiles {
    [CmdletBinding()]
    param()

    Write-SectionHeader "Updating dotfiles"

    $dotDir = $script:Config.DotDir

    if (-not (Test-Path $dotDir)) {
        Write-ErrorCustom "Dotfile repository not found. Run Initialize-DotfileRepo first."
        return $false
    }

    # Fetch latest changes
    Write-Info "Fetching latest changes..."
    Push-Location $dotDir
    & git fetch origin 2>$null
    $fetchResult = $LASTEXITCODE
    Pop-Location

    if ($fetchResult -ne 0) {
        Write-ErrorCustom "Failed to fetch updates"
        return $false
    }

    # Get current branch
    $currentBranch = & git --git-dir="$dotDir" branch --show-current

    # Check if there are updates
    $localCommit = & git --git-dir="$dotDir" rev-parse HEAD
    $remoteCommit = & git --git-dir="$dotDir" rev-parse "origin/$currentBranch"

    if ($localCommit -eq $remoteCommit) {
        Write-Success "Already up to date"
        return $true
    }

    Write-Info "Updates available, deploying..."

    # Deploy the latest changes
    & git --git-dir="$dotDir" --work-tree="$env:USERPROFILE" fetch origin 2>$null
    & git --git-dir="$dotDir" --work-tree="$env:USERPROFILE" checkout origin/$currentBranch -f 2>$null

    if ($LASTEXITCODE -eq 0) {
        Write-Success "Dotfiles updated successfully"
        return $true
    } else {
        Write-ErrorCustom "Failed to update dotfiles"
        return $false
    }
}

<#
.SYNOPSIS
    Initialize the complete dotfile setup.

.DESCRIPTION
    Orchestrates the full dotfile initialization process:
    1. Initialize/update the bare repository
    2. Deploy dotfiles
    3. Add the 'dot' alias to profile

.EXAMPLE
    Initialize-DotfileSetup
#>
function Initialize-DotfileSetup {
    [CmdletBinding()]
    param()

    Write-SectionHeader "Starting dotfile deployment"

    try {
        Initialize-DotfileRepo
        Deploy-Dotfiles
        Add-DotAliasToProfile
        Write-Success "Dotfile setup completed successfully"
        return $true
    } catch {
        Write-ErrorCustom "Dotfile setup failed: $_"
        return $false
    }
}

<#
.SYNOPSIS
    Create the 'dot' function for interactive use.

.DESCRIPTION
    Returns a script block that can be used to create the 'dot' function.
    This is useful for adding to your profile manually.

.EXAMPLE
    Get-DotAliasFunction
#>
function Get-DotAliasFunction {
    [CmdletBinding()]
    param()

    $dotDir = $script:Config.DotDir
    $aliasName = $script:Config.AliasName

    return "function $aliasName { git --git-dir='$dotDir' --work-tree='$env:USERPROFILE' `$args }"
}

# Export module members
<#
.SYNOPSIS
    Remove dotfile installation

.DESCRIPTION
    Completely removes dotfile configuration and optionally restores system defaults
#>
function Uninstall-Dotfile {
    [CmdletBinding()]
    param(
        [switch]$RemoveBackups,
        [switch]$KeepProfile,
        [switch]$KeepTerminalSettings,
        [switch]$KeepVimConfig,
        [switch]$Quiet
    )

    $scriptPath = Join-Path $PSScriptRoot "..\scripts\Uninstall-Dotfile.ps1"

    if (-not (Test-Path $scriptPath)) {
        Write-ErrorCustom "Uninstall script not found: $scriptPath"
        return $false
    }

    # Build arguments array
    $args = @()
    if ($RemoveBackups) { $args += "-RemoveBackups" }
    if ($KeepProfile) { $args += "-KeepProfile" }
    if ($KeepTerminalSettings) { $args += "-KeepTerminalSettings" }
    if ($KeepVimConfig) { $args += "-KeepVimConfig" }
    if ($Quiet) { $args += "-Quiet" }

    # Execute uninstall script
    & $scriptPath @args
    return $true
}

# Export module members
Export-ModuleMember -Function @(
    'Get-DotfileConfig',
    'Set-DotfileConfig',
    'Initialize-DotfileRepo',
    'Backup-ExistingConfig',
    'Deploy-Dotfiles',
    'Add-DotAliasToProfile',
    'Get-DotfileStatus',
    'Update-Dotfiles',
    'Initialize-DotfileSetup',
    'Get-DotAliasFunction',
    'Uninstall-Dotfile'
)
