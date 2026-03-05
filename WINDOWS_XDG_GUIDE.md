# Windows XDG Configuration Guide

This guide explains how to configure your Windows system to use XDG Base Directory Specification, enabling Linux-style paths for Neovim and other applications.

## What is XDG?

XDG (X Desktop Group) Base Directory Specification is a standard for defining where applications store user data on Unix-like systems. The standard paths are:

- `~/.config` - Configuration files
- `~/.local/share` - Application data
- `~/.local/state` - Application state

## Current Implementation

Your system now supports XDG paths on Windows:

### Environment Variables Set
```powershell
XDG_CONFIG_HOME = C:\Users\ADMIN\.config
XDG_DATA_HOME = C:\Users\ADMIN\.local\share
XDG_STATE_HOME = C:\Users\ADMIN\.local\state
```

### Neovim Configuration
- **Primary Path**: `C:\Users\ADMIN\.config\nvim` (XDG standard)
- **Backup Path**: `C:\Users\ADMIN\AppData\Local\nvim` (Windows standard)
- **Runtime Path**: `C:\Users\ADMIN\AppData\Local\nvim-data\vimfiles` (Windows standard)

## Why This Approach?

1. **Cross-Platform Consistency**: Use the same configuration management as Linux/macOS
2. **Git Integration**: Your `.config` directory is part of your dotfiles repository
3. **Compatibility**: Windows tools can still use the standard paths
4. **Future-Proof**: More tools are adopting XDG standards

## Verification

Use these scripts to verify your configuration:

### 1. Quick Verification
```powershell
.\verify-nvim-config.ps1
```

### 2. XDG Neovim Test
```powershell
.\test-xdg-nvim.ps1
```

## Common Issues and Solutions

### Issue: Neovim still uses Windows path
**Solution**: Neovim may need to be restarted after setting environment variables. The symbolic link approach is used as a fallback.

### Issue: XDG paths not recognized
**Solution**:
1. Restart your PowerShell session
2. Run `install.ps1 -OnlyDotfile` to re-deploy configuration
3. Check environment variables are set permanently

### Issue: Plugin installations in wrong location
**Solution**: Most plugins will now install to `~/.local/share/nvim/site` following XDG standards.

## Manual Management

### Managing Neovim Config
Since your config is at `~/.config/nvim`, you can manage it just like on Linux:

```powershell
# Edit config code
cd ~/.config/nvim
nvim

# Add new plugins
cd ~/.config/nvim/lua/plugins
# Add your plugin files

# Update from repository
cd D:\develop\dotfile
git pull
```

### Environment Variables

If you need to modify XDG paths, edit:

`C:\Users\ADMIN\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1`

## Benefits

1. **Familiar Workflow**: Use the same commands and paths as on Linux
2. **Git Integration**: Full version control over your configuration
3. **Cross-Platform**: Same dotfiles work on Windows, Linux, and macOS
4. **Tool Compatibility**: More tools support XDG natively
5. **Cleaner Path Structure**: No more messy `AppData` directories

## Maintenance

The `install.ps1` script will:
- Keep XDG environment variables up to date
- Synchronize configuration between XDG and Windows paths
- Verify installation with post-deployment checks

## Troubleshooting

### Check Environment Variables
```powershell
[System.Environment]::GetEnvironmentVariable('XDG_CONFIG_HOME', 'User')
[System.Environment]::GetEnvironmentVariable('XDG_DATA_HOME', 'User')
```

### Force Re-deployment
```powershell
.\install.ps1 -OnlyDotfile
```

### Manual XDG Setup
If automatic setup fails:

```powershell
# Set permanently
[System.Environment]::SetEnvironmentVariable('XDG_CONFIG_HOME',
    "$env:USERPROFILE\.config", 'User')
[System.Environment]::SetEnvironmentVariable('XDG_DATA_HOME',
    "$env:USERPROFILE\.local\share", 'User')
[System.Environment]::SetEnvironmentVariable('XDG_STATE_HOME',
    "$env:USERPROFILE\.local\state", 'User')

# Restart PowerShell and test
nvim --headless "+echo stdpath('config')" +q
```

## Next Steps

1. Restart your PowerShell session to ensure environment variables are loaded
2. Run the verification scripts to confirm everything works
3. Start using `~/.config/nvim` as your primary Neovim configuration directory
4. Enjoy a Linux-like workflow on Windows!