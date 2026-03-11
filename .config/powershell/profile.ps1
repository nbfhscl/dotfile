# ============================================
# PowerShell Configuration
# ============================================

# Oh-My-Posh Theme Engine
$env:POSH_THEMES_PATH = "$env:USERPROFILE\.poshthemes"
if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) {
    # Try to use a custom theme, fall back to built-in theme
    $customTheme = "$env:POSH_THEMES_PATH\simple.omp.json"
    if (Test-Path $customTheme) {
        oh-my-posh init pwsh --config $customTheme | Invoke-Expression
    } else {
        # Use built-in theme as fallback
        oh-my-posh init pwsh --config "$env:POSH_THEMES_PATH\jandedobbeleer.omp.json" | Invoke-Expression
    }
}

# PSReadLine - Compatible with version 2.0.0+
if (Get-Module -ListAvailable -Name PSReadLine) {
    Import-Module PSReadLine
    # Basic key bindings that work with all PSReadLine versions
    Set-PSReadLineKeyHandler -Key "Tab" -Function MenuComplete
    Set-PSReadLineKeyHandler -Key "Ctrl+d" -Function DeleteChar
    Set-PSReadLineKeyHandler -Key "Ctrl+w" -Function BackwardDeleteWord
}

# Terminal-Icons
if (Get-Module -ListAvailable -Name Terminal-Icons) {
    Import-Module Terminal-Icons
}

# zoxide
if (Get-Command zoxide -ErrorAction SilentlyContinue) {
    Invoke-Expression (& { (zoxide init powershell | Out-String) })
}

# PSFzf
if (Get-Module -ListAvailable -Name PSFzf) {
    Import-Module PSFzf
    Set-PsFzfOption -PSReadlineChordProvider Ctrl+t -PsReadlineChordReverseHistory Ctrl+r
}

# --- psmux Configuration ---
# Point psmux to your dotfiles directory
$env:PSMUX_CONFIG = "$env:USERPROFILE\.config\tmux\tmux.conf"

# --- Alias for tmux-like muscle memory ---
if (Get-Command psmux -ErrorAction SilentlyContinue) {
    Set-Alias -Name tmux -Value psmux
}

# dotfile management
function dot {
    git --git-dir="$env:USERPROFILE\.dotfile" --work-tree="$env:USERPROFILE" $args
}

# Aliases (avoiding conflicts with built-in aliases)
Set-Alias ll Get-ChildItem
Set-Alias grep Select-String

# Custom functions
function Edit-Profile { & $env:EDITOR $PROFILE.CurrentUserCurrentHost }
function Reload-Profile { . $PROFILE.CurrentUserCurrentHost }
function Show-Env { Get-ChildItem Env: | Format-Table -AutoSize }
