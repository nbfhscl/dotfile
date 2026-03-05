# ============================================
# Common.psm1 Demo - Before and After Comparison
# ============================================

<#
This script demonstrates the code reduction achieved by using the Common module.

Run this script to see:
1. How much code is eliminated
2. How consistent output becomes across all scripts
3. How easy it is to use the Common module
#>

param(
    [switch]$ShowBefore
)

Import-Module (Join-Path $PSScriptRoot 'Common.psm1')

if ($ShowBefore) {
    Write-Host @"
========================================
BEFORE: Without Common Module
========================================

To get the same functionality without the Common module,
every script would need this boilerplate:

# ====== Output Functions (20 lines) ======
function Write-Info {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor Cyan
}

function Write-Success {
    param([string]$Message)
    Write-Host "[SUCCESS] $Message" -ForegroundColor Green
}

function Write-WarningCustom {
    param([string]$Message)
    Write-Host "[WARN] $Message" -ForegroundColor Yellow
}

function Write-ErrorCustom {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
}

function Write-SectionHeader {
    param([string]$Title, [string]$Character = '=', [int]$Width = 42)
    `$line = `$Character * `$Width
    Write-Host "[INFO] `$line" -ForegroundColor Cyan
    Write-Host "[INFO] `$Title" -ForegroundColor Cyan
    Write-Host "[INFO] `$line" -ForegroundColor Cyan
}

# ====== Validation Functions (10 lines) ======
function Test-Administrator {
    `$currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    `$principal = New-Object Security.Principal.WindowsPrincipal(`$currentUser)
    return `$principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Test-PowerShellVersion {
    param([version]`$MinimumVersion = "7.0")
    return `$PSVersionTable.PSVersion -ge `$MinimumVersion
}

function Test-CommandAvailable {
    param([string]`$CommandName)
    return `$null -ne (Get-Command `$CommandName -ErrorAction SilentlyContinue)
}

# ====== XDG Support (15 lines) ======
function Get-XDGConfigPath {
    param([string]`$Subdirectory)
    if (`$env:XDG_CONFIG_HOME) {
        `$basePath = `$env:XDG_CONFIG_HOME
    } else {
        `$basePath = Join-Path `$env:USERPROFILE ".local\config"
    }
    if (`$Subdirectory) {
        return Join-Path `$basePath `$Subdirectory
    }
    return `$basePath
}

function Get-XDGDataPath {
    param([string]`$Subdirectory)
    if (`$env:XDG_DATA_HOME) {
        `$basePath = `$env:XDG_DATA_HOME
    } else {
        `$basePath = Join-Path `$env:USERPROFILE ".local\data"
    }
    if (`$Subdirectory) {
        return Join-Path `$basePath `$Subdirectory
    }
    return `$basePath
}

# ====== Backup Functions (20 lines) ======
function Backup-File {
    param(
        [string]`$Path,
        [string]`$BackupDirectory,
        [string]`$TimestampFormat = "yyyyMMdd_HHmmss"
    )
    if (-not (Test-Path `$Path)) {
        Write-Warning "File not found: `$Path"
        return `$null
    }
    `$timestamp = Get-Date -Format `$TimestampFormat
    `$filename = Split-Path `$Path -Leaf
    `$backupName = "`$filename.backup_`$timestamp"
    if (`$BackupDirectory) {
        if (-not (Test-Path `$BackupDirectory)) {
            New-Item -ItemType Directory -Path `$BackupDirectory -Force | Out-Null
        }
        `$backupPath = Join-Path `$BackupDirectory `$backupName
    } else {
        `$backupPath = "`$Path.backup_`$timestamp"
    }
    Copy-Item `$Path `$backupPath -Force
    Write-Host "[INFO] Backup created: `$backupPath" -ForegroundColor Cyan
    return `$backupPath
}

function Backup-Directory {
    param(
        [string]`$Path,
        [string]`$BackupRootDirectory,
        [switch]`$IncludePathInName
    )
    # ... similar implementation ...
}

# ====== Error Handling (10 lines) ======
function Invoke-CommandWithErrorHandling {
    param(
        [scriptblock]`$ScriptBlock,
        [string]`$ErrorMessage = "Operation failed",
        [string]`$SuccessMessage,
        [switch]`$ThrowOnError
    )
    try {
        & `$ScriptBlock
        if (`$SuccessMessage) {
            Write-Host "[SUCCESS] `$SuccessMessage" -ForegroundColor Green
        }
        return `$true
    } catch {
        Write-Host "[ERROR] `${ErrorMessage}: `$_" -ForegroundColor Red
        if (`$ThrowOnError) { throw }
        return `$false
    }
}

# ====== Path Utilities (10 lines) ======
function New-TemporaryDirectory {
    param([string]`$Prefix = "tmp", [string]`$BasePath)
    if (`$BasePath) {
        if (-not (Test-Path `$BasePath)) {
            New-Item -ItemType Directory -Path `$BasePath -Force | Out-Null
        }
    } else {
        `$BasePath = `$env:TEMP
    }
    `$tempName = "`$Prefix-$(Get-Date -Format 'yyyyMMddHHmmss')-$(Get-Random -Maximum 9999)"
    `$tempPath = Join-Path `$BasePath `$tempName
    New-Item -ItemType Directory -Path `$tempPath -Force | Out-Null
    return `$tempPath
}

# ====== Total: 85+ lines of boilerplate ======

"@
}

Write-SectionHeader "Common.psm1 Code Reduction Demo"

Write-Info "With Common.psm1, all that boilerplate becomes:"
Write-Success "Import-Module (Join-Path `$PSScriptRoot 'modules\Common.psm1')"

Write-Success "# All 21 functions immediately available:"
Write-Success "# - Write-Info, Write-Success, Write-WarningCustom, Write-ErrorCustom"
Write-Success "# - Write-SectionHeader, Write-SectionComplete"
Write-Success "# - Test-Administrator, Test-PowerShellVersion, Test-CommandAvailable"
Write-Success "# - Get-XDGConfigPath, Get-XDGDataPath, Initialize-XDGPaths"
Write-Success "# - Backup-File, Backup-Directory"
Write-Success "# - Invoke-CommandWithErrorHandling"
Write-Success "# - Confirm-Action"
Write-Success "# - New-TemporaryDirectory, Get-RelativePath, Resolve-PathSafely"
Write-Success "# - Initialize-Logging, Write-Log"

Write-Info "That's 85+ lines of boilerplate reduced to 1 line!"

Write-SectionHeader "Live Demo"

Write-Info "Let's see it in action..."

Write-SectionHeader "1. Color-Coded Output"
Write-Info "Information message"
Write-Success "Success message"
Write-WarningCustom "Warning message"
Write-ErrorCustom "Error message"

Write-SectionHeader "2. Validation Functions"
$isAdmin = Test-Administrator
Write-Info "Running as administrator: $isAdmin"

$psVersion = Test-PowerShellVersion -MinimumVersion 7.0
Write-Info "PowerShell 7+ available: $psVersion"

$gitAvailable = Test-CommandAvailable "git"
Write-Info "Git available: $gitAvailable"

Write-SectionHeader "3. XDG Paths"
$nvimConfig = Get-XDGConfigPath "nvim"
Write-Info "Neovim config path: $nvimConfig"

$vimData = Get-XDGDataPath "vim-data"
Write-Info "Vim data path: $vimData"

Write-SectionHeader "4. Backup Function"
$testFile = Join-Path $env:TEMP "demo_test.txt"
"Demo content" | Out-File $testFile
$backup = Backup-File $testFile
Remove-Item $testFile, $backup -Force -ErrorAction SilentlyContinue

Write-SectionHeader "5. Error Handling"
$result = Invoke-CommandWithErrorHandling {
    $date = Get-Date
    return $date
} -ErrorMessage "Failed to get date" -SuccessMessage "Successfully got date"

Write-SectionHeader "6. Temporary Directory"
$tempDir = New-TemporaryDirectory -Prefix "demo"
Write-Success "Created temp directory: $tempDir"
Remove-Item $tempDir -Force -Recurse

Write-SectionComplete "Demo completed successfully!"

Write-Success "Summary:"
Write-Info "  - 85+ lines of boilerplate eliminated"
Write-Info "  - 21 reusable functions available"
Write-Info "  - Consistent output across all scripts"
Write-Info "  - Best practices built-in"
Write-Info "  - Well-documented with examples"

Write-Success "Import the Common module in your scripts today!"
Write-Info "  Import-Module (Join-Path `$PSScriptRoot 'modules\Common.psm1')"
