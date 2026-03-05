# ============================================
# Common.psm1 Usage Examples
# ============================================
#
# This file demonstrates how to use the Common module
# to reduce boilerplate in your scripts.
#
# Run: . .\Common-Examples.ps1
# ============================================

# Import the Common module
Import-Module (Join-Path $PSScriptRoot 'Common.psm1')

# ============================================
# EXAMPLE 1: Basic Output Functions
# ============================================

function Example1_Output {
    Write-SectionHeader "Example 1: Color-Coded Output"

    Write-Info "This is an informational message"
    Write-Success "This is a success message"
    Write-WarningCustom "This is a warning message"
    Write-ErrorCustom "This is an error message"

    # Output without prefix
    Write-Info "Plain message without prefix" -NoPrefix

    Write-SectionComplete "Output examples completed"
}

# ============================================
# EXAMPLE 2: Validation Functions
# ============================================

function Example2_Validation {
    Write-SectionHeader "Example 2: Validation Functions"

    # Check for administrator privileges
    if (Test-Administrator) {
        Write-Success "Running with administrator privileges"
    } else {
        Write-WarningCustom "Running without administrator privileges"
    }

    # Check PowerShell version
    if (Test-PowerShellVersion -MinimumVersion 7.0) {
        Write-Success "PowerShell version meets requirements"
    } else {
        Write-ErrorCustom "PowerShell 7+ required"
        return
    }

    # Check if command is available
    if (Test-CommandAvailable "git") {
        Write-Success "Git is installed"
    } else {
        Write-WarningCustom "Git is not available"
    }
}

# ============================================
# EXAMPLE 3: XDG Base Directory Support
# ============================================

function Example3_XDGPaths {
    Write-SectionHeader "Example 3: XDG Base Directory Support"

    # Get XDG config path
    $nvimConfig = Get-XDGConfigPath "nvim"
    Write-Info "Neovim config path: $nvimConfig"

    # Get XDG data path
    $vimData = Get-XDGDataPath "vim-data"
    Write-Info "Vim data path: $vimData"

    # Initialize XDG directories (creates them if they don't exist)
    Initialize-XDGPaths -SetEnvironment
    Write-Success "XDG paths initialized"
    Write-Info "XDG_CONFIG_HOME: $env:XDG_CONFIG_HOME"
    Write-Info "XDG_DATA_HOME: $env:XDG_DATA_HOME"
}

# ============================================
# EXAMPLE 4: Backup Functions
# ============================================

function Example4_Backup {
    Write-SectionHeader "Example 4: Backup Functions"

    # Create a test file
    $testFile = Join-Path $env:TEMP "test_backup.txt"
    "Test content" | Out-File $testFile

    # Backup the file
    $backup = Backup-File $testFile
    Write-Success "File backed up to: $backup"

    # Create a test directory
    $testDir = Join-Path $env:TEMP "test_backup_dir"
    New-Item -ItemType Directory -Path $testDir -Force | Out-Null
    "Test file" | Out-File (Join-Path $testDir "file.txt")

    # Backup the directory
    $dirBackup = Backup-Directory $testDir
    Write-Success "Directory backed up to: $dirBackup"

    # Cleanup
    Remove-Item $testFile, $testDir -Force -Recurse
}

# ============================================
# EXAMPLE 5: Error Handling
# ============================================

function Example5_ErrorHandling {
    Write-SectionHeader "Example 5: Error Handling"

    # Simple error handling
    $result = Invoke-CommandWithErrorHandling {
        # This will succeed
        "Success output"
    } -ErrorMessage "Failed to execute" -SuccessMessage "Operation succeeded"

    if ($result) {
        Write-Success "Command executed successfully"
    }

    # Error handling with return output
    $output = Invoke-CommandWithErrorHandling {
        # This will succeed and return output
        Get-Date
    } -ErrorMessage "Failed to get date" -ReturnOutput

    Write-Info "Current date: $output"

    # Error handling with exception (this will fail)
    $failed = Invoke-CommandWithErrorHandling {
        throw "Intentional error"
    } -ErrorMessage "Expected failure"

    if (-not $failed) {
        Write-Info "Error was caught and handled gracefully"
    }
}

# ============================================
# EXAMPLE 6: User Confirmation
# ============================================

function Example6_Confirmation {
    Write-SectionHeader "Example 6: User Confirmation"

    # Simple confirmation
    $confirmed = Confirm-Action "Do you want to continue?"

    if ($confirmed) {
        Write-Success "User confirmed the action"
    } else {
        Write-Info "User cancelled the action"
    }

    # Confirmation with default yes
    $confirmedYes = Confirm-Action "Continue with default yes?" -DefaultToYes

    # Using -Force flag (for automation)
    # $global:Force = $true
    # $forced = Confirm-Action "This will be auto-confirmed"
}

# ============================================
# EXAMPLE 7: Path Utilities
# ============================================

function Example7_PathUtilities {
    Write-SectionHeader "Example 7: Path Utilities"

    # Create temporary directory
    $tempDir = New-TemporaryDirectory -Prefix "example"
    Write-Success "Created temp directory: $tempDir"

    # Get relative path
    $relative = Get-RelativePath $env:USERPROFILE "$env:USERPROFILE\.config\nvim"
    Write-Info "Relative path: $relative"

    # Safe path resolution
    $resolved = Resolve-PathSafely "C:\Windows"
    if ($resolved) {
        Write-Success "Resolved path: $resolved"
    }

    $notFound = Resolve-PathSafely "C:\Nonexistent\Path"
    if ($null -eq $notFound) {
        Write-Info "Path doesn't exist (returned null instead of error)"
    }

    # Cleanup
    Remove-Item $tempDir -Force -Recurse
}

# ============================================
# EXAMPLE 8: Logging
# ============================================

function Example8_Logging {
    Write-SectionHeader "Example 8: Logging"

    # Initialize logging
    $logFile = Initialize-Logging -LogName "ExampleScript" -Level Info
    Write-Success "Log file created: $logFile"

    # Write log entries
    Write-Log "Script started" -LogFile $logFile -Level Info
    Write-Log "Performing operation" -LogFile $logFile -Level Info
    Write-Log "Operation completed" -LogFile $logFile -Level Success

    # Write log with console output
    Write-Log "Important message" -LogFile $logFile -Level Info -PassThru

    Write-Info "Check the log file for all entries"
}

# ============================================
# EXAMPLE 9: Complete Script Template
# ============================================

<#
.SYNOPSIS
    Template showing how to use Common.psm1 in a real script.

.DESCRIPTION
    This template demonstrates best practices for using the Common module
    to eliminate boilerplate code.

.EXAMPLE
    .\Script-Template.ps1 -WhatIf
    .\Script-Template.ps1 -Force -Verbose
#>
function Script-Template {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [switch]$Force
    )

    # Import Common module
    Import-Module (Join-Path $PSScriptRoot 'modules\Common.psm1')

    # Set global Force flag for Confirm-Action function
    $global:Force = $Force

    # Initialize logging
    $logFile = Initialize-Logging -LogName "MyScript"
    Write-Log "Script started" -LogFile $logFile -Level Info

    # Validate prerequisites
    Write-SectionHeader "Validating Prerequisites"

    if (-not (Test-PowerShellVersion -MinimumVersion 7.0)) {
        Write-Log "PowerShell version check failed" -LogFile $logFile -Level Error
        return 1
    }

    if (-not (Test-CommandAvailable "git")) {
        Write-Log "Git not found" -LogFile $logFile -Level Error
        Write-ErrorCustom "Git is required"
        return 1
    }

    Write-Success "Prerequisites validated"

    # Main operation
    Write-SectionHeader "Main Operation"

    $result = Invoke-CommandWithErrorHandling {
        # Your main logic here
        Write-Info "Processing..."

        # Use XDG paths for cross-platform compatibility
        $configPath = Get-XDGConfigPath "myapp"
        Initialize-XDGPaths -SetEnvironment

        # Backup existing config if it exists
        if (Test-Path $configPath) {
            Backup-Directory $configPath | Out-Null
        }

        # Continue with your logic...
        return $true
    } -ErrorMessage "Operation failed" -SuccessMessage "Operation completed successfully"

    # Cleanup
    Write-SectionHeader "Cleanup"

    if ($result) {
        Write-Success "Script completed successfully"
        Write-Log "Script completed" -LogFile $logFile -Level Info
        return 0
    } else {
        Write-ErrorCustom "Script failed"
        Write-Log "Script failed" -LogFile $logFile -Level Error
        return 1
    }
}

# ============================================
# Run Examples
# ============================================

function Run-AllExamples {
    [CmdletBinding()]
    param(
        [ValidateSet('All', 'Output', 'Validation', 'XDG', 'Backup', 'ErrorHandling', 'Confirmation', 'Paths', 'Logging')]
        [string]$Example = 'All'
    )

    switch ($Example) {
        'All' {
            Example1_Output
            Write-Host ""

            Example2_Validation
            Write-Host ""

            Example3_XDGPaths
            Write-Host ""

            Example4_Backup
            Write-Host ""

            Example5_ErrorHandling
            Write-Host ""

            Example7_PathUtilities
            Write-Host ""

            Example8_Logging
        }
        'Output' { Example1_Output }
        'Validation' { Example2_Validation }
        'XDG' { Example3_XDGPaths }
        'Backup' { Example4_Backup }
        'ErrorHandling' { Example5_ErrorHandling }
        'Confirmation' { Example6_Confirmation }
        'Paths' { Example7_PathUtilities }
        'Logging' { Example8_Logging }
    }
}

# Export examples
Export-ModuleMember -Function @(
    'Run-AllExamples',
    'Script-Template'
)

# If run directly, execute examples
if ($MyInvocation.InvocationName -ne '.') {
    Run-AllExamples
}
