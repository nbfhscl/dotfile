# ============================================
# PowerShell 7 配置
# ============================================

# Oh-My-Posh 主题引擎
$env:POSH_THEMES_PATH = "$env:USERPROFILE\.poshthemes"
if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) {
    oh-my-posh init pwsh --config "$env:POSH_THEMES_PATH\paradox.omp.json" | Invoke-Expression
}

# PSReadLine
if (Get-Module -ListAvailable -Name PSReadLine) {
    Import-Module PSReadLine
    Set-PSReadLineOption -PredictionSource History
    Set-PSReadLineOption -PredictionViewStyle ListView
    Set-PSReadLineKeyHandler -Key "Tab" -Function MenuComplete
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

# dotfile 管理
function dot {
    git --git-dir="$env:USERPROFILE\.dotfile" --work-tree="$env:USERPROFILE" $args
}

# 别名
Set-Alias ll Get-ChildItem
Set-Alias grep Select-String
Set-Alias cat Get-Content

# 自定义函数
function Edit-Profile { & $EDITOR $PROFILE.CurrentUserCurrentHost }
function Reload-Profile { . $PROFILE.CurrentUserCurrentHost }
function Show-Env { Get-ChildItem Env: | Format-Table -AutoSize }
