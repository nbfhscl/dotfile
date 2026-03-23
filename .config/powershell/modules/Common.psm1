# ============================================
# Common Module - Shared Utilities and Boilerplate
# ============================================

<#
.SYNOPSIS
    Provides shared utility functions and boilerplate code for all dotfile scripts.

.DESCRIPTION
    This module consolidates common functionality used across all PowerShell scripts including:
    - Color-coded output functions (Write-Info, Write-Success, Write-Warning, Write-Error)
    - Common parameter validation
    - Shared path resolution utilities
    - Standard logging setup
    - Backup functionality
    - XDG base directory support
    - Error handling patterns

    This eliminates the 30+ lines of boilerplate repeated across every script.

.EXPORTED FUNCTIONS
    Write-Info, Write-Success, Write-WarningCustom, Write-ErrorCustom,
    Write-SectionHeader, Write-SectionComplete,
    Test-Administrator, Test-PowerShellVersion,
    Get-XDGConfigPath, Get-XDGDataPath, Initialize-XDGPaths,
    Backup-File, Backup-Directory,
    Invoke-CommandWithErrorHandling, Test-CommandAvailable,
    Confirm-Action, New-TemporaryDirectory,
    Get-RelativePath, Resolve-PathSafely
#>

# ============================================
# Color-Coded Output Functions
# ============================================

<#
.SYNOPSIS
    Write an informational message to the console.

.PARAMETER Message
    The message to display.

.PARAMETER NoPrefix
    Omit the [INFO] prefix.

.EXAMPLE
    Write-Info "Starting installation process..."
    Write-Info "Plain message" -NoPrefix
#>
function Write-Info {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,
        [switch]$NoPrefix
    )

    if ($NoPrefix) {
        $prefix = ""
    } else {
        $prefix = "[INFO] "
    }
    Write-Host "${prefix}$Message" -ForegroundColor Cyan
}

<#
.SYNOPSIS
    Write a success message to the console.

.PARAMETER Message
    The message to display.

.PARAMETER NoPrefix
    Omit the [SUCCESS] prefix.

.EXAMPLE
    Write-Success "Installation completed successfully!"
    Write-Success "Done!" -NoPrefix
#>
function Write-Success {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,
        [switch]$NoPrefix
    )

    if ($NoPrefix) {
        $prefix = ""
    } else {
        $prefix = "[SUCCESS] "
    }
    Write-Host "${prefix}$Message" -ForegroundColor Green
}

<#
.SYNOPSIS
    Write a warning message to the console.

.PARAMETER Message
    The message to display.

.PARAMETER NoPrefix
    Omit the [WARN] prefix.

.EXAMPLE
    Write-WarningCustom "This operation requires administrator privileges."
#>
function Write-WarningCustom {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,
        [switch]$NoPrefix
    )

    if ($NoPrefix) {
        $prefix = ""
    } else {
        $prefix = "[WARN] "
    }
    Write-Host "${prefix}$Message" -ForegroundColor Yellow
}

<#
.SYNOPSIS
    Write an error message to the console.

.PARAMETER Message
    The message to display.

.PARAMETER NoPrefix
    Omit the [ERROR] prefix.

.EXAMPLE
    Write-ErrorCustom "Failed to install package."
#>
function Write-ErrorCustom {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,
        [switch]$NoPrefix
    )

    if ($NoPrefix) {
        $prefix = ""
    } else {
        $prefix = "[ERROR] "
    }
    Write-Host "${prefix}$Message" -ForegroundColor Red
}

<#
.SYNOPSIS
    Display a section header for grouping related operations.

.PARAMETER Title
    The title of the section.

.PARAMETER Character
    The character to use for the border (default: '=').

.PARAMETER Width
    The width of the border (default: 42).

.EXAMPLE
    Write-SectionHeader "Installing Tools"
    Write-SectionHeader "Configuration" -Character "-" -Width 50
#>
function Write-SectionHeader {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Title,
        [string]$Character = "=",
        [int]$Width = 42
    )

    $line = $Character * $Width
    Write-Info $line
    Write-Info $Title
    Write-Info $line
}

<#
.SYNOPSIS
    Display a completion message for a section.

.PARAMETER Message
    The message to display.

.PARAMETER Character
    The character to use for the border (default: '=').

.PARAMETER Width
    The width of the border (default: 42).

.EXAMPLE
    Write-SectionComplete "Tools installation completed"
#>
function Write-SectionComplete {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,
        [string]$Character = "=",
        [int]$Width = 42
    )

    $line = $Character * $Width
    Write-Success $line
    Write-Success $Message
    Write-Success $line
}

# ============================================
# Validation Functions
# ============================================

<#
.SYNOPSIS
    Check if the current session has administrator privileges.

.DESCRIPTION
    Tests if the current PowerShell session is running with administrator rights.
    Returns true if running as admin, false otherwise.

.EXAMPLE
    if (-not (Test-Administrator)) {
        Write-ErrorCustom "This script requires administrator privileges"
        exit 1
    }
#>
function Test-Administrator {
    [CmdletBinding()]
    [OutputType([bool])]
    param()

    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    $isAdmin = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

    return $isAdmin
}

<#
.SYNOPSIS
    Check if the current PowerShell version meets requirements.

.PARAMETER MinimumVersion
    The minimum version required (default: 7.0).

.PARAMETER WarnOnly
    Only warn if version is too low, don't return false.

.EXAMPLE
    if (-not (Test-PowerShellVersion -MinimumVersion 7.0)) {
        Write-ErrorCustom "PowerShell 7+ required"
        exit 1
    }
#>
function Test-PowerShellVersion {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [version]$MinimumVersion = "5.1",
        [switch]$WarnOnly
    )

    $currentVersion = $PSVersionTable.PSVersion

    if ($currentVersion -lt $MinimumVersion) {
        $message = "PowerShell $MinimumVersion or higher is required (current: $currentVersion)"
        if ($WarnOnly) {
            Write-WarningCustom $message
            return $true
        } else {
            Write-ErrorCustom $message
            return $false
        }
    }

    return $true
}

<#
.SYNOPSIS
    Test if a command is available in the current environment.

.PARAMETER CommandName
    The name of the command to check.

.EXAMPLE
    if (Test-CommandAvailable "git") {
        Write-Info "Git is installed"
    }
#>
function Test-CommandAvailable {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$CommandName
    )

    $command = Get-Command $CommandName -ErrorAction SilentlyContinue
    return $null -ne $command
}

# ============================================
# XDG Base Directory Support
# ============================================

<#
.SYNOPSIS
    Get the XDG config home directory.

.DESCRIPTION
    Returns the XDG_CONFIG_HOME environment variable if set,
    otherwise returns the default XDG path ($env:USERPROFILE\.config).

.PARAMETER Subdirectory
    Optional subdirectory to append (e.g., "nvim").

.EXAMPLE
    $nvimConfig = Get-XDGConfigPath "nvim"
    Returns: C:\Users\Username\.config\nvim
#>
function Get-XDGConfigPath {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [string]$Subdirectory
    )

    if ($env:XDG_CONFIG_HOME) {
        $basePath = $env:XDG_CONFIG_HOME
    } else {
        $basePath = Join-Path $env:USERPROFILE ".config"
    }

    if ($Subdirectory) {
        return Join-Path $basePath $Subdirectory
    }

    return $basePath
}

<#
.SYNOPSIS
    Get the XDG data home directory.

.DESCRIPTION
    Returns the XDG_DATA_HOME environment variable if set,
    otherwise returns the default XDG path ($env:USERPROFILE\.local\share).

.PARAMETER Subdirectory
    Optional subdirectory to append (e.g., "vim-data").

.EXAMPLE
    $vimData = Get-XDGDataPath "vim-data"
    Returns: C:\Users\Username\.local\share\vim-data
#>
function Get-XDGDataPath {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [string]$Subdirectory
    )

    if ($env:XDG_DATA_HOME) {
        $basePath = $env:XDG_DATA_HOME
    } else {
        $basePath = Join-Path $env:USERPROFILE ".local\share"
    }

    if ($Subdirectory) {
        return Join-Path $basePath $Subdirectory
    }

    return $basePath
}

<#
.SYNOPSIS
    Initialize XDG base directories if they don't exist.

.DESCRIPTION
    Creates XDG_CONFIG_HOME, XDG_DATA_HOME, XDG_STATE_HOME, and XDG_CACHE_HOME
    directories if they don't exist.
    Also sets environment variables for the current session if not already set.

.PARAMETER SetEnvironment
    Set environment variables for the current session.

.EXAMPLE
    Initialize-XDGPaths
    Initialize-XDGPaths -SetEnvironment
#>
function Initialize-XDGPaths {
    [CmdletBinding()]
    param(
        [switch]$SetEnvironment
    )

    $configPath = Get-XDGConfigPath
    $dataPath = Get-XDGDataPath
    $statePath = if ($env:XDG_STATE_HOME) { $env:XDG_STATE_HOME } else { Join-Path $env:USERPROFILE ".local\state" }
    $cachePath = if ($env:XDG_CACHE_HOME) { $env:XDG_CACHE_HOME } else { Join-Path $env:USERPROFILE ".cache" }

    # Create directories if they don't exist
    if (-not (Test-Path $configPath)) {
        New-Item -ItemType Directory -Path $configPath -Force | Out-Null
        Write-Info "Created XDG_CONFIG_HOME: $configPath"
    }

    if (-not (Test-Path $dataPath)) {
        New-Item -ItemType Directory -Path $dataPath -Force | Out-Null
        Write-Info "Created XDG_DATA_HOME: $dataPath"
    }

    if (-not (Test-Path $statePath)) {
        New-Item -ItemType Directory -Path $statePath -Force | Out-Null
        Write-Info "Created XDG_STATE_HOME: $statePath"
    }

    if (-not (Test-Path $cachePath)) {
        New-Item -ItemType Directory -Path $cachePath -Force | Out-Null
        Write-Info "Created XDG_CACHE_HOME: $cachePath"
    }

    # Set environment variables for current session
    if ($SetEnvironment) {
        if (-not $env:XDG_CONFIG_HOME) {
            $env:XDG_CONFIG_HOME = $configPath
        }
        if (-not $env:XDG_DATA_HOME) {
            $env:XDG_DATA_HOME = $dataPath
        }
        if (-not $env:XDG_STATE_HOME) {
            $env:XDG_STATE_HOME = $statePath
        }
        if (-not $env:XDG_CACHE_HOME) {
            $env:XDG_CACHE_HOME = $cachePath
        }
    }
}

<#
.SYNOPSIS
    Test if legacy configuration exists.

.DESCRIPTION
    Checks if a legacy configuration file or directory exists at the specified path.

.PARAMETER LegacyPath
    The legacy path to check.

.EXAMPLE
    $hasLegacy = Test-LegacyConfig "$env:USERPROFILE\.vimrc"
#>
function Test-LegacyConfig {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$LegacyPath
    )

    return Test-Path $LegacyPath
}

<#
.SYNOPSIS
    Migrate legacy configuration to XDG-compliant path.

.DESCRIPTION
    Moves legacy configuration to XDG path and creates a symbolic link for backward compatibility.

.PARAMETER LegacyPath
    The legacy configuration path.

.PARAMETER XDGPath
    The XDG-compliant target path.

.PARAMETER BackupDirectory
    Directory to store backups (optional).

.EXAMPLE
    Move-LegacyConfigToXDG -LegacyPath "$env:USERPROFILE\.vimrc" -XDGPath (Get-XDGConfigPath "vim\vimrc")
#>
function Move-LegacyConfigToXDG {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$LegacyPath,

        [Parameter(Mandatory = $true)]
        [string]$XDGPath,

        [string]$BackupDirectory
    )

    # Source must exist
    if (-not (Test-Path $LegacyPath)) {
        Write-Info "No legacy config at $LegacyPath, skipping migration"
        return
    }

    # Create target directory
    $targetDir = Split-Path -Parent $XDGPath
    if (-not (Test-Path $targetDir)) {
        New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
    }

    # If target already exists, backup it
    if (Test-Path $XDGPath) {
        if ($BackupDirectory) {
            if (-not (Test-Path $BackupDirectory)) {
                New-Item -ItemType Directory -Path $BackupDirectory -Force | Out-Null
            }
            $backupPath = Join-Path $BackupDirectory (Split-Path -Leaf $XDGPath)
            Move-Item -Path $XDGPath -Destination $backupPath -Force
            Write-Info "Backed up existing XDG config to $backupPath"
        } else {
            Remove-Item -Path $XDGPath -Recurse -Force
        }
    }

    # Move source to target
    Move-Item -Path $LegacyPath -Destination $XDGPath -Force
    Write-Info "Migrated $LegacyPath to $XDGPath"

    # Create symbolic link for backward compatibility (requires admin)
    try {
        New-Item -ItemType SymbolicLink -Path $LegacyPath -Target $XDGPath -Force | Out-Null
        Write-Info "Created symlink: $LegacyPath -> $XDGPath"
    } catch {
        Write-WarningCustom "Could not create symlink (requires admin): $_"
        Write-Info "You can manually create a symlink if needed:"
        Write-Info "  mklink /D `"$LegacyPath`" `"$XDGPath`""
    }
}

<#
.SYNOPSIS
    Create XDG-compliant symlinks for backward compatibility.

.DESCRIPTION
    Creates symbolic links from legacy paths to XDG paths if the legacy paths don't exist.

.PARAMETER XDGPath
    The XDG-compliant path.

.PARAMETER LegacyPath
    The legacy path to create symlink at.

.EXAMPLE
    New-XDGCompatSymlink -XDGPath (Get-XDGConfigPath "vim") -LegacyPath "$env:USERPROFILE\.vim"
#>
function New-XDGCompatSymlink {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$XDGPath,

        [Parameter(Mandatory = $true)]
        [string]$LegacyPath
    )

    # If legacy path exists and is not a symlink, back it up
    if ((Test-Path $LegacyPath) -and (Get-Item $LegacyPath).LinkType -ne "SymbolicLink") {
        $backupDir = "$env:USERPROFILE\.dotfile_backup_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
        if (-not (Test-Path $backupDir)) {
            New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
        }
        $backupPath = Join-Path $backupDir (Split-Path -Leaf $LegacyPath)
        Move-Item -Path $LegacyPath -Destination $backupPath -Force
        Write-Info "Backed up existing $LegacyPath to $backupPath"
    }

    # Create symlink if it doesn't exist
    if (-not (Test-Path $LegacyPath)) {
        try {
            New-Item -ItemType SymbolicLink -Path $LegacyPath -Target $XDGPath -Force | Out-Null
            Write-Info "Created symlink: $LegacyPath -> $XDGPath"
        } catch {
            Write-WarningCustom "Could not create symlink: $_"
        }
    }
}

<#
.SYNOPSIS
    Verify XDG path compliance.

.DESCRIPTION
    Checks that all XDG environment variables are set and directories exist.

.PARAMETER XDGPaths
    Hashtable of XDG paths (optional, defaults to current environment).

.EXAMPLE
    $isValid = Test-XDGCompliance
#>
function Test-XDGCompliance {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [hashtable]$XDGPaths
    )

    # If not provided, get from environment
    if (-not $XDGPaths) {
        $XDGPaths = @{
            ConfigHome = $env:XDG_CONFIG_HOME
            DataHome   = $env:XDG_DATA_HOME
            StateHome  = $env:XDG_STATE_HOME
            CacheHome  = $env:XDG_CACHE_HOME
        }
    }

    $errors = 0

    foreach ($path in $XDGPaths.GetEnumerator()) {
        if (-not $path.Value) {
            Write-ErrorCustom "XDG_$($path.Key.Replace('Home', '_HOME')) is not set"
            $errors++
        } elseif (-not (Test-Path $path.Value)) {
            Write-ErrorCustom "XDG_$($path.Key.Replace('Home', '_HOME')) ($($path.Value)) does not exist"
            $errors++
        }
    }

    return $errors -eq 0
}

<#
.SYNOPSIS
    Ensure XDG-compliant application structure.

.DESCRIPTION
    Creates standard XDG directory structure for an application.

.PARAMETER AppName
    Name of the application.

.PARAMETER Subdirectories
    Array of subdirectories to create in format "type:path" (e.g., "config:plugins", "data:cache").

.EXAMPLE
    Add-XDGAppStructure -AppName "myapp" -Subdirectories @("config:plugins", "data:cache", "cache:temp")
#>
function Add-XDGAppStructure {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$AppName,

        [string[]]$Subdirectories
    )

    $configDir = Join-Path (Get-XDGConfigPath) $AppName
    $dataDir = Join-Path (Get-XDGDataPath) $AppName
    $stateDir = if ($env:XDG_STATE_HOME) { Join-Path $env:XDG_STATE_HOME $AppName } else { Join-Path $env:USERPROFILE ".local\state\$AppName" }
    $cacheDir = if ($env:XDG_CACHE_HOME) { Join-Path $env:XDG_CACHE_HOME $AppName } else { Join-Path $env:USERPROFILE ".cache\$AppName" }

    # Create base directories
    foreach ($dir in @($configDir, $dataDir, $stateDir, $cacheDir)) {
        if (-not (Test-Path $dir)) {
            New-Item -ItemType Directory -Path $dir -Force | Out-Null
        }
    }

    # Create subdirectories if specified
    if ($Subdirectories) {
        foreach ($subdir in $Subdirectories) {
            if ($subdir -match '^(config|data|state|cache):(.+)$') {
                $type = $Matches[1]
                $path = $Matches[2]

                $targetDir = switch ($type) {
                    'config' { Join-Path $configDir $path }
                    'data'   { Join-Path $dataDir $path }
                    'state'  { Join-Path $stateDir $path }
                    'cache'  { Join-Path $cacheDir $path }
                }

                if (-not (Test-Path $targetDir)) {
                    New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
                }
            }
        }
    }
}

# ============================================
# Backup Functions
# ============================================

<#
.SYNOPSIS
    Create a backup of a file with timestamp.

.DESCRIPTION
    Creates a timestamped backup of the specified file.
    Returns the path to the backup file.

.PARAMETER Path
    The file to backup.

.PARAMETER BackupDirectory
    Directory to store backups (optional, defaults to same directory as file).

.PARAMETER TimestampFormat
    Format for timestamp (default: yyyyMMdd_HHmmss).

.EXAMPLE
    $backup = Backup-File "C:\Users\Username\.gitconfig"
    Creates: C:\Users\Username\.gitconfig.backup_20250106_143022
#>
function Backup-File {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,
        [string]$BackupDirectory,
        [string]$TimestampFormat = "yyyyMMdd_HHmmss"
    )

    if (-not (Test-Path $Path)) {
        Write-WarningCustom "File not found: $Path"
        return $null
    }

    $timestamp = Get-Date -Format $TimestampFormat
    $filename = Split-Path $Path -Leaf
    $backupName = "$filename.backup_$timestamp"

    if ($BackupDirectory) {
        if (-not (Test-Path $BackupDirectory)) {
            New-Item -ItemType Directory -Path $BackupDirectory -Force | Out-Null
        }
        $backupPath = Join-Path $BackupDirectory $backupName
    } else {
        $backupPath = "$Path.backup_$timestamp"
    }

    Copy-Item $Path $backupPath -Force
    Write-Info "Backup created: $backupPath"

    return $backupPath
}

<#
.SYNOPSIS
    Create a backup of a directory with timestamp.

.DESCRIPTION
    Creates a timestamped backup of the specified directory.
    Returns the path to the backup directory.

.PARAMETER Path
    The directory to backup.

.PARAMETER BackupRootDirectory
    Root directory for backups (optional, defaults to parent of Path).

.PARAMETER IncludePathInName
    Include the original directory name in the backup folder name.

.EXAMPLE
    $backup = Backup-Directory "C:\Users\Username\.vim"
    Creates: C:\Users\Username\.vim.backup_20250106_143022

.EXAMPLE
    $backup = Backup-Directory "C:\Users\Username\.vim" -BackupRootDirectory "C:\Backups"
    Creates: C:\Backups\.vim.backup_20250106_143022
#>
function Backup-Directory {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,
        [string]$BackupRootDirectory,
        [switch]$IncludePathInName
    )

    if (-not (Test-Path $Path)) {
        Write-WarningCustom "Directory not found: $Path"
        return $null
    }

    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $dirname = Split-Path $Path -Leaf

    if ($IncludePathInName) {
        $backupName = "$dirname.backup_$timestamp"
    } else {
        $backupName = ".backup_$timestamp"
    }

    if ($BackupRootDirectory) {
        if (-not (Test-Path $BackupRootDirectory)) {
            New-Item -ItemType Directory -Path $BackupRootDirectory -Force | Out-Null
        }
        $backupPath = Join-Path $BackupRootDirectory $backupName
    } else {
        $backupPath = "$Path.backup_$timestamp"
    }

    Copy-Item $Path $backupPath -Recurse -Force
    Write-Info "Backup created: $backupPath"

    return $backupPath
}

# ============================================
# Error Handling Functions
# ============================================

<#
.SYNOPSIS
    Execute a script block with standardized error handling.

.DESCRIPTION
    Wraps script execution with try/catch and optional logging.
    Returns true if successful, false otherwise.

.PARAMETER ScriptBlock
    The script block to execute.

.PARAMETER ErrorMessage
    Custom error message (default: "Operation failed").

.PARAMETER SuccessMessage
    Optional message to display on success.

.PARAMETER ThrowOnError
    Throw exception on error (default: false).

.PARAMETER ReturnOutput
    Return the output from the script block instead of boolean.

.EXAMPLE
    $result = Invoke-CommandWithErrorHandling {
        Copy-Item $source $destination
    } -ErrorMessage "Failed to copy file"
#>
function Invoke-CommandWithErrorHandling {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [scriptblock]$ScriptBlock,
        [string]$ErrorMessage = "Operation failed",
        [string]$SuccessMessage,
        [switch]$ThrowOnError,
        [switch]$ReturnOutput
    )

    try {
        $output = & $ScriptBlock

        if ($SuccessMessage) {
            Write-Success $SuccessMessage
        }

        if ($ReturnOutput) {
            return $output
        }

        return $true
    } catch {
        $errorDetails = $_.Exception.Message
        Write-ErrorCustom "${ErrorMessage}: ${errorDetails}"

        if ($ThrowOnError) {
            throw
        }

        return $false
    }
}

# ============================================
# User Interaction Functions
# ============================================

<#
.SYNOPSIS
    Prompt user for confirmation.

.DESCRIPTION
    Displays a confirmation prompt and returns true if user confirms.
    Automatically returns false if -Force is in global scope.

.PARAMETER Message
    The confirmation message.

.PARAMETER DefaultToYes
    Default to Yes if user presses Enter (default: false).

.EXAMPLE
    if (Confirm-Action "Delete all backups") {
        # Delete backups
    }

.EXAMPLE
    $global:Force = $true
    if (Confirm-Action "Delete all backups") {
        # Automatically confirmed due to -Force
    }
#>
function Confirm-Action {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,
        [switch]$DefaultToYes
    )

    # Check for global -Force flag
    if ($null -ne $global:Force -and $global:Force) {
        return $true
    }

    $default = if ($DefaultToYes) { 0 } else { 1 }
    $yesNo = if ($DefaultToYes) { "[Y/n]" } else { "[y/N]" }

    $title = "Confirm Action"
    $question = "$Message $yesNo"

    $choices = New-Object Collections.ObjectModel.Collection[Management.Automation.Host.ChoiceDescription]
    $choices.Add((New-Object Management.Automation.Host.ChoiceDescription "&Yes", "Continue"))
    $choices.Add((New-Object Management.Automation.Host.ChoiceDescription "&No", "Cancel"))

    $decision = $Host.UI.PromptForChoice($title, $question, $choices, $default)
    return $decision -eq 0
}

# ============================================
# Path Utility Functions
# ============================================

<#
.SYNOPSIS
    Create a temporary directory.

.DESCRIPTION
    Creates a temporary directory in the system temp folder.
    Returns the path to the created directory.
    The directory is not automatically deleted.

.PARAMETER Prefix
    Prefix for the directory name (default: "tmp").

.PARAMETER BasePath
    Base path for temp directory (default: system temp path).

.EXAMPLE
    $tempDir = New-TemporaryDirectory
    # Use $tempDir for operations
    # Clean up when done: Remove-Item $tempDir -Recurse
#>
function New-TemporaryDirectory {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [string]$Prefix = "tmp",
        [string]$BasePath
    )

    if ($BasePath) {
        if (-not (Test-Path $BasePath)) {
            New-Item -ItemType Directory -Path $BasePath -Force | Out-Null
        }
    } else {
        $BasePath = $env:TEMP
    }

    $tempName = "$Prefix-$(Get-Date -Format 'yyyyMMddHHmmss')-$(Get-Random -Maximum 9999)"
    $tempPath = Join-Path $BasePath $tempName

    New-Item -ItemType Directory -Path $tempPath -Force | Out-Null
    return $tempPath
}

<#
.SYNOPSIS
    Get relative path from base to target.

.DESCRIPTION
    Calculates the relative path from a base directory to a target file/directory.

.PARAMETER BasePath
    The base directory path.

.PARAMETER TargetPath
    The target file or directory path.

.EXAMPLE
    Get-RelativePath "C:\Users\Username" "C:\Users\Username\.config\nvim"
    Returns: .config\nvim
#>
function Get-RelativePath {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$BasePath,
        [Parameter(Mandatory = $true)]
        [string]$TargetPath
    )

    $base = Resolve-Path $BasePath -ErrorAction SilentlyContinue
    $target = Resolve-Path $TargetPath -ErrorAction SilentlyContinue

    if ($null -eq $base) { $base = $BasePath }
    if ($null -eq $target) { $target = $TargetPath }

    return (Split-Path $target -NoQualifier).Substring((Split-Path $base -NoQualifier).Length + 1)
}

<#
.SYNOPSIS
    Safely resolve a path without errors.

.DESCRIPTION
    Attempts to resolve a path. Returns null if the path doesn't exist
    instead of throwing an error.

.PARAMETER Path
    The path to resolve.

.PARAMETER RelativeToBase
    If path is relative, resolve it relative to this base path.

.EXAMPLE
    $resolved = Resolve-PathSafely "C:\Nonexistent\Path"
    Returns: $null
#>
function Resolve-PathSafely {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,
        [string]$RelativeToBase
    )

    try {
        if ($RelativeToBase -and -not [System.IO.Path]::IsPathRooted($Path)) {
            $Path = Join-Path $RelativeToBase $Path
        }

        $resolved = Resolve-Path $Path -ErrorAction Stop
        return $resolved.Path
    } catch {
        return $null
    }
}

# ============================================
# Logging Functions
# ============================================

<#
.SYNOPSIS
    Initialize logging for a script.

.DESCRIPTION
    Sets up file-based logging with optional console output.
    Returns the path to the log file.

.PARAMETER LogDirectory
    Directory for log files (default: %USERPROFILE%\.dotfile\logs).

.PARAMETER LogName
    Name for the log file (default: script name).

.PARAMETER Level
    Logging level: Debug, Info, Warning, Error (default: Info).

.PARAMETER IncludeDateInName
    Include date in log filename (default: true).

.EXAMPLE
    $logFile = Initialize-Logging -LogName "MyScript"
    Write-Log "Script started" -LogFile $logFile
#>
function Initialize-Logging {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [string]$LogDirectory = "$env:USERPROFILE\.dotfile\logs",
        [string]$LogName = (Split-Path $PSCommandPath -Leaf),
        [ValidateSet("Debug", "Info", "Warning", "Error")]
        [string]$Level = "Info",
        [switch]$IncludeDateInName
    )

    # Create log directory if it doesn't exist
    if (-not (Test-Path $LogDirectory)) {
        New-Item -ItemType Directory -Path $LogDirectory -Force | Out-Null
    }

    # Generate log filename
    if ($IncludeDateInName) {
        $dateStr = Get-Date -Format "yyyyMMdd"
        if ($IncludeDateInName) {
            $logFileName = "${LogName}_${dateStr}.log"
        } else {
            $logFileName = "${LogName}.log"
        }
    } else {
        $logFileName = "${LogName}.log"
    }

    $logPath = Join-Path $LogDirectory $logFileName

    # Write header to log file
    $separator = "=" * 80
    Add-Content -Path $logPath -Value ""
    Add-Content -Path $logPath -Value $separator
    Add-Content -Path $logPath -Value "Log started: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    Add-Content -Path $logPath -Value "Script: $PSCommandPath"
    Add-Content -Path $logPath -Value "User: $env:USERNAME"
    Add-Content -Path $logPath -Value "Computer: $env:COMPUTERNAME"
    Add-Content -Path $logPath -Value $separator

    return $logPath
}

<#
.SYNOPSIS
    Write a message to a log file.

.DESCRIPTION
    Appends a timestamped message to the specified log file.

.PARAMETER Message
    The message to log.

.PARAMETER LogFile
    Path to the log file (required).

.PARAMETER Level
    Log level: Debug, Info, Warning, Error (default: Info).

.PARAMETER PassThru
    Also write to console using Write-Info/Write-WarningCustom/Write-ErrorCustom.

.EXAMPLE
    Write-Log "Operation completed" -LogFile $logFile -Level Info
#>
function Write-Log {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,
        [Parameter(Mandatory = $true)]
        [string]$LogFile,
        [ValidateSet("Debug", "Info", "Warning", "Error")]
        [string]$Level = "Info",
        [switch]$PassThru
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"

    try {
        Add-Content -Path $LogFile -Value $logEntry -ErrorAction Stop
    } catch {
        # Silently fail if we can't write to log
    }

    if ($PassThru) {
        switch ($Level) {
            "Debug" { Write-Info $Message }
            "Info" { Write-Info $Message }
            "Warning" { Write-WarningCustom $Message }
            "Error" { Write-ErrorCustom $Message }
        }
    }
}

# ============================================
# Module Exports
# ============================================

Export-ModuleMember -Function @(
    # Output Functions
    'Write-Info',
    'Write-Success',
    'Write-WarningCustom',
    'Write-ErrorCustom',
    'Write-SectionHeader',
    'Write-SectionComplete',

    # Validation Functions
    'Test-Administrator',
    'Test-PowerShellVersion',
    'Test-CommandAvailable',

    # XDG Functions
    'Get-XDGConfigPath',
    'Get-XDGDataPath',
    'Initialize-XDGPaths',
    'Test-LegacyConfig',
    'Move-LegacyConfigToXDG',
    'New-XDGCompatSymlink',
    'Test-XDGCompliance',
    'Add-XDGAppStructure',

    # Backup Functions
    'Backup-File',
    'Backup-Directory',

    # Error Handling Functions
    'Invoke-CommandWithErrorHandling',

    # User Interaction Functions
    'Confirm-Action',

    # Path Utility Functions
    'New-TemporaryDirectory',
    'Get-RelativePath',
    'Resolve-PathSafely',

    # Logging Functions
    'Initialize-Logging',
    'Write-Log'
)
