<#
.SYNOPSIS
    Crée un objet PowerShell représentant un logiciel détecté ou géré.

.DESCRIPTION
    Utilisé dans tout le projet UpdatesFaciles. L’objet contient toutes les infos utiles sur le logiciel : nom, éditeur, version, état, chemin, etc.

.EXAMPLE
    $app = New-SoftwareApp -Name "VLC" -Publisher "VideoLAN" -Version "3.0.18" -Type "Installed" -State "Present" -InstallPath "C:\Program Files\VideoLAN\VLC\vlc.exe" -Source "Registry" -CanInstall $false -CanUninstall $true
#>

function New-SoftwareApp {
    param (
        [string]$Name,
        [string]$Publisher,
        [string]$Version,
        [ValidateSet('Installed','Portable','Cloud','Shortcut')]
        [string]$Type,
        [ValidateSet('Present','Missing','Corrupted','Unknown')]
        [string]$State,
        [string]$InstallPath,
        [ValidateSet('Registry','FileSystem','Shortcut','API','Custom')]
        [string]$Source,
        [bool]$CanInstall,
        [bool]$CanUninstall
    )

    return [PSCustomObject]@{
        Name         = $Name
        Publisher    = $Publisher
        Version      = $Version
        Type         = $Type
        State        = $State
        InstallPath  = $InstallPath
        Source       = $Source
        CanInstall   = $CanInstall
        CanUninstall = $CanUninstall
    }
}

function New-SoftwareApp {
    param (
        [string]$Name,
        [string]$Version,
        [string]$Source = "Installé", # Installé / Portable / Raccourci / Cloud
        [string]$Path = "",
        [string]$Publisher = "",
        [string]$State = "Inconnu"
    )
    return [PSCustomObject]@{
        Name      = $Name
        Version   = $Version
        Source    = $Source
        Path      = $Path
        Publisher = $Publisher
        State     = $State
    }
}