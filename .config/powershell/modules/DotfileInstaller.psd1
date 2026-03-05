# ============================================
# DotfileInstaller Module Manifest
# ============================================

@{
    # Script module or binary module file associated with this manifest.
    RootModule = 'DotfileInstaller.psm1'

    # Version number of this module.
    ModuleVersion = '1.0.0'

    # Supported PSEditions
    CompatiblePSEditions = @('Core', 'Desktop')

    # ID used to uniquely identify this module
    GUID = 'a1b2c3d4-e5f6-4a5b-8c7d-9e0f1a2b3c4d'

    # Author of this module
    Author = 'dotfile'

    # Company or vendor of this module
    CompanyName = 'Unknown'

    # Copyright statement for this module
    Copyright = '(c) 2026 dotfile'

    # Description of the functionality provided by this module
    Description = 'Modular PowerShell dotfile installer with support for development tools and configuration management.'

    # Minimum version of the PowerShell engine required by this module
    PowerShellVersion = '5.1'

    # Modules that must be imported into the global environment prior to importing this module
    RequiredModules = @(
        @{ ModuleName = 'UI'; ModuleVersion = '1.0.0' },
        @{ ModuleName = 'ToolInstaller'; ModuleVersion = '1.0.0' },
        @{ ModuleName = 'ConfigDeployer'; ModuleVersion = '1.0.0' },
        @{ ModuleName = 'Verifier'; ModuleVersion = '1.0.0' }
    )

    # Assemblies that must be loaded prior to importing this module
    # RequiredAssemblies = @()

    # Type files (.ps1xml) to be loaded when importing this module
    # TypesToProcess = @()

    # Format files (.ps1xml) to be loaded when importing this module
    # FormatsToProcess = @()

    # Modules to import as nested modules of the module specified in RootModule/ModuleToProcess
    # NestedModules = @()

    # Functions to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no functions to export.
    FunctionsToExport = @(
        'Get-DotfileConfig',
        'Set-DotfileConfig',
        'Initialize-DotfileRepo',
        'Backup-ExistingConfig',
        'Deploy-Dotfiles',
        'Add-DotAliasToProfile',
        'Get-DotfileStatus',
        'Update-Dotfiles',
        'Initialize-DotfileSetup',
        'Get-DotAliasFunction'
    )

    # Cmdlets to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no cmdlets to export.
    CmdletsToExport = @()

    # Variables to export from this module
    VariablesToExport = @()

    # Aliases to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no aliases to export.
    AliasesToExport = @()

    # DSC resources to export from this module
    # DscResourcesToExport = @()

    # List of all modules packaged with this module
    # ModuleList = @()

    # List of all files packaged with this module
    # FileList = @()

    # Private data to pass to the module specified in RootModule/ModuleToProcess
    PrivateData = @{

        PSData = @{

            # Tags applied to this module. These help with module discovery in online galleries.
            Tags = @('Dotfiles', 'Development', 'Configuration', 'Installer', 'Windows', 'Neovim', 'PowerShell')

            # A URL to the license for this module.
            # LicenseUri = ''

            # A URL to the main website for this project.
            ProjectUri = 'https://github.com/nbfhscl/dotfile'

            # A URL to an icon representing this module.
            # IconUri = ''

            # ReleaseNotes of this module
            # ReleaseNotes = ''

        } # End of PSData hashtable

    } # End of PrivateData hashtable

    # HelpInfo URI of this module
    # HelpInfoURI = ''

    # Default prefix for commands exported from this module. Override the default prefix using Import-Module -Prefix.
    # DefaultCommandPrefix = ''
}
