#
# Module manifest for module 'Unifi'
#
# Generated by: Elmar Niederkofler
#
# Generated on: 24.01.2020
#
# Modified Elmar Niederkofler 24.01.2020

@{
    ModuleVersion        = '1.0.0'
    GUID                 = '6d390ab4-57aa-49ea-8bf0-93d1281297ec'
    Author               = 'Elmar Niederkofler'
    CompanyName          = 'Telmekom'
    Copyright            = '(c) 2020 Elmar Niederkofler. All rights reserved.'
    Description          = 'PowerShell Unifi Controller management and automation'
    RootModule           = 'Unifi.psm1'
    FunctionsToExport    = @(
        'Add-UServerFile',
        'Add-USiteFile',
        'Add-UCredentialFile',
        'Open-USite'
    )

    CmdletsToExport      = @()
    VariablesToExport    = @()
    PowerShellVersion    = '6.2'
    DscResourcesToExport = @()
    FileList             = @(
        '.\Examples',
        '.\README.md',
        '.\Unifi.psm1'
    )
    
    PrivateData          = @{
        PSData = @{
            Tags         = @('automation', 'web', 'powershell', 'windows', 'unifi')
            LicenseUri   = 'https://github.com/BuggeXX/Unifi/blob/master/LICENSE'
            ProjectUri   = 'https://github.com/BuggeXX/Unifi'
            ReleaseNotes = 'Managing Unifi Controller with PowerShell'
    
            # A URL to an icon representing this module.
            # IconUri = ''
            #Prerelease = 'beta1'
        } # End of PSData hashtable
    
    } # End of PrivateData hashtable
    
    # Supported PSEditions
    # CompatiblePSEditions = @()

    # Aliases to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no aliases to export.
    #AliasesToExport = @()

    # Script files (.ps1) that are run in the caller's environment prior to importing this module.
    # ScriptsToProcess = @()

    # Assemblies that must be loaded prior to importing this module
    # RequiredAssemblies = @()
       
    # Name of the Windows PowerShell host required by this module
    # PowerShellHostName = ''
    
    # Minimum version of the Windows PowerShell host required by this module
    # PowerShellHostVersion = ''
    
    # Minimum version of Microsoft .NET Framework required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
    # DotNetFrameworkVersion = ''
    
    # Minimum version of the common language runtime (CLR) required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
    # CLRVersion = ''

    # Modules that must be imported into the global environment prior to importing this module
    # RequiredModules = @()
    
    # Processor architecture (None, X86, Amd64) required by this module
    # ProcessorArchitecture = ''
    
    # Type files (.ps1xml) to be loaded when importing this module
    # TypesToProcess = @()
    
    # Format files (.ps1xml) to be loaded when importing this module
    # FormatsToProcess = @()
    
    # Modules to import as nested modules of the module specified in RootModule/ModuleToProcess
    # NestedModules = @()
    
    # List of all modules packaged with this module
    # ModuleList = @()
    
    # Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
    
    # HelpInfo URI of this module
    # HelpInfoURI = ''
    
    # Default prefix for commands exported from this module. Override the default prefix using Import-Module -Prefix.
    # DefaultCommandPrefix = ''
    
}
    