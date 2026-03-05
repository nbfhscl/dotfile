# ============================================
# UI Module - User Interface Functions
# ============================================

<#
.SYNOPSIS
    Provides consistent colored output functions for the dotfile installer.

.DESCRIPTION
    This module exports functions for formatted console output with color-coded
    severity levels: Info (Cyan), Success (Green), Warning (Yellow), Error (Red).

.EXPORTED FUNCTIONS
    Write-Info, Write-Success, Write-Warning, Write-Error, Show-ManualInstallHelp
#>

# Manual installation download links
$script:ManualInstallLinks = @{
    "Git" = "https://git-scm.com/download/win"
    "Node.js" = "https://nodejs.org/"
    "Neovim" = "https://github.com/neovim/neovim/releases"
    "Windows Terminal" = "https://aka.ms/terminal"
    "PowerShell" = "https://github.com/PowerShell/PowerShell/releases"
}

<#
.SYNOPSIS
    Write an informational message to the console.

.PARAMETER Message
    The message to display.

.EXAMPLE
    Write-Info "Starting installation process..."
#>
function Write-Info {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message
    )
    Write-Host "[INFO] $Message" -ForegroundColor Cyan
}

<#
.SYNOPSIS
    Write a success message to the console.

.PARAMETER Message
    The message to display.

.EXAMPLE
    Write-Success "Installation completed successfully!"
#>
function Write-Success {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message
    )
    Write-Host "[SUCCESS] $Message" -ForegroundColor Green
}

<#
.SYNOPSIS
    Write a warning message to the console.

.PARAMETER Message
    The message to display.

.EXAMPLE
    Write-Warning "This operation requires administrator privileges."
#>
function Write-WarningCustom {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message
    )
    Write-Host "[WARN] $Message" -ForegroundColor Yellow
}

<#
.SYNOPSIS
    Write an error message to the console.

.PARAMETER Message
    The message to display.

.EXAMPLE
    Write-ErrorCustom "Failed to install package."
#>
function Write-ErrorCustom {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message
    )
    Write-Host "[ERROR] $Message" -ForegroundColor Red
}

<#
.SYNOPSIS
    Display manual installation help for a tool.

.PARAMETER ToolName
    The name of the tool to show help for.

.DESCRIPTION
    Displays a warning message with the download URL for manual installation
    of the specified tool.

.EXAMPLE
    Show-ManualInstallHelp -ToolName "Git"
#>
function Show-ManualInstallHelp {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ToolName
    )

    if ($script:ManualInstallLinks.ContainsKey($ToolName)) {
        Write-WarningCustom "Please install $ToolName manually:"
        Write-Info "Download URL: $($script:ManualInstallLinks[$ToolName])"
    }
}

<#
.SYNOPSIS
    Display a section header for grouping related operations.

.PARAMETER Title
    The title of the section.

.PARAMETER Character
    The character to use for the border (default: '=').

.EXAMPLE
    Write-SectionHeader "Installing Tools"
#>
function Write-SectionHeader {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Title,
        [string]$Character = "="
    )

    $line = $Character * 42
    Write-Info $line
    Write-Info $Title
    Write-Info $line
}

<#
.SYNOPSIS
    Display a completion message for a section.

.PARAMETER Message
    The message to display.

.EXAMPLE
    Write-SectionComplete "Tools installation completed"
#>
function Write-SectionComplete {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message
    )

    Write-Success "=========================================="
    Write-Success $Message
    Write-Success "=========================================="
}

# Export module members
Export-ModuleMember -Function @(
    'Write-Info',
    'Write-Success',
    'Write-WarningCustom',
    'Write-ErrorCustom',
    'Show-ManualInstallHelp',
    'Write-SectionHeader',
    'Write-SectionComplete'
)
