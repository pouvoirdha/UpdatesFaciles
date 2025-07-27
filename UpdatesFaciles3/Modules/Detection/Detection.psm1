#requires -Version 7.0

<#
.SYNOPSIS
    Module de détection des logiciels installés pour UpdatesFaciles
.DESCRIPTION
    Ce module fournit les fonctions nécessaires pour détecter les logiciels
    installés sur le système et vérifier leurs versions.
.VERSION
    1.0.0
.AUTHOR
    UpdatesFaciles Team
#>

# Variables globales du module
$script:LogPath = ".\logs.txt"
$script:CacheExpiry = 300 # 5 minutes en secondes
$script:SoftwareCache = @{}

#region Fonctions utilitaires

function Write-Log {
    <#
    .SYNOPSIS
        Écrit un message dans le fichier de log
    #>
    param(
        [Parameter(Mandatory)]
        [string]$Message,
        
        [ValidateSet('INFO', 'WARNING', 'ERROR', 'DEBUG')]
        [string]$Level = 'INFO'
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    
    try {
        Add-Content -Path $script:LogPath -Value $logEntry -Encoding UTF8 -ErrorAction Stop
    }
    catch {
        Write-Warning "Impossible d'écrire dans le log: $_"
    }
}

function Test-RegistryKey {
    <#
    .SYNOPSIS
        Teste l'existence d'une clé de registre
    #>
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )
    
    try {
        return Test-Path -Path $Path -ErrorAction Stop
    }
    catch {
        return $false
    }
}

#endregion

#region Fonctions de détection principales

function Get-InstalledSoftwareFromRegistry {
    <#
    .SYNOPSIS
        Récupère la liste des logiciels installés depuis le registre
    .DESCRIPTION
        Scanne les clés de registre standard pour lister les logiciels installés
    .OUTPUTS
        Array d'objets contenant les informations des logiciels
    #>
    [CmdletBinding()]
    param()
    
    Write-Log "Début de la détection des logiciels depuis le registre"
    
    $registryPaths = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*"
    )
    
    $installedSoftware = @()
    
    foreach ($path in $registryPaths) {
        try {
            Write-Log "Scan du chemin: $path" -Level DEBUG
            
            $items = Get-ItemProperty -Path $path -ErrorAction SilentlyContinue | 
                     Where-Object { 
                         $_.DisplayName -and 
                         -not $_.SystemComponent -and 
                         -not $_.WindowsInstaller -and
                         $_.DisplayName -notmatch "^(KB|Security Update|Update for)" 
                     }
            
            foreach ($item in $items) {
                $software = [PSCustomObject]@{
                    Name = $item.DisplayName
                    Version = $item.DisplayVersion
                    Publisher = $item.Publisher
                    InstallDate = $item.InstallDate
                    InstallLocation = $item.InstallLocation
                    UninstallString = $item.UninstallString
                    RegistryKey = $item.PSPath
                    Architecture = if ($path -match "WOW6432Node") { "x86" } else { "x64" }
                    Source = "Registry"
                }
                $installedSoftware += $software
            }
        }
        catch {
            Write-Log "Erreur lors du scan de $path : $_" -Level ERROR
        }
    }
    
    Write-Log "Détection terminée. $($installedSoftware.Count) logiciels trouvés"
    return $installedSoftware
}

function Get-InstalledSoftwareFromWMI {
    <#
    .SYNOPSIS
        Récupère la liste des logiciels installés via WMI
    .DESCRIPTION
        Utilise WMI Win32_Product pour lister les logiciels (plus lent mais plus complet)
    .OUTPUTS
        Array d'objets contenant les informations des logiciels
    #>
    [CmdletBinding()]
    param()
    
    Write-Log "Début de la détection des logiciels via WMI"
    
    try {
        $wmiSoftware = Get-CimInstance -ClassName Win32_Product -ErrorAction Stop | 
                       Where-Object { $_.Name -and $_.Version }
        
        $installedSoftware = @()
        foreach ($software in $wmiSoftware) {
            $item = [PSCustomObject]@{
                Name = $software.Name
                Version = $software.Version
                Publisher = $software.Vendor
                InstallDate = $software.InstallDate
                InstallLocation = $software.InstallLocation
                UninstallString = ""
                RegistryKey = ""
                Architecture = "Unknown"
                Source = "WMI"
            }
            $installedSoftware += $item
        }
        
        Write-Log "Détection WMI terminée. $($installedSoftware.Count) logiciels trouvés"
        return $installedSoftware
    }
    catch {
        Write-Log "Erreur lors de la détection WMI: $_" -Level ERROR
        return @()
    }
}

function Get-InstalledSoftwareFromPackageManager {
    <#
    .SYNOPSIS
        Récupère les logiciels installés via les gestionnaires de paquets
    .DESCRIPTION
        Détecte les logiciels installés via Chocolatey, Winget, etc.
    #>
    [CmdletBinding()]
    param()
    
    Write-Log "Début de la détection via gestionnaires de paquets"
    $installedSoftware = @()
    
    # Chocolatey
    if (Get-Command choco -ErrorAction SilentlyContinue) {
        try {
            Write-Log "Détection des paquets Chocolatey" -Level DEBUG
            $chocoList = choco list -lo -r 2>$null
            
            foreach ($line in $chocoList) {
                if ($line -match "^(.+)\|(.+)$") {
                    $software = [PSCustomObject]@{
                        Name = $matches[1]
                        Version = $matches[2]
                        Publisher = "Chocolatey"
                        InstallDate = ""
                        InstallLocation = ""
                        UninstallString = "choco uninstall $($matches[1])"
                        RegistryKey = ""
                        Architecture = "Package"
                        Source = "Chocolatey"
                    }
                    $installedSoftware += $software
                }
            }
        }
        catch {
            Write-Log "Erreur lors de la détection Chocolatey: $_" -Level ERROR
        }
    }
    
    # Winget
    if (Get-Command winget -ErrorAction SilentlyContinue) {
        try {
            Write-Log "Détection des paquets Winget" -Level DEBUG
            $wingetList = winget list --accept-source-agreements 2>$null | 
                         Select-Object -Skip 2 | 
                         Where-Object { $_ -and $_ -notmatch "^-+$" }
            
            foreach ($line in $wingetList) {
                if ($line -match "^(.+?)\s+(.+?)\s+(.+?)?\s*$") {
                    $software = [PSCustomObject]@{
                        Name = $matches[1].Trim()
                        Version = $matches[2].Trim()
                        Publisher = "Winget"
                        InstallDate = ""
                        InstallLocation = ""
                        UninstallString = "winget uninstall `"$($matches[1].Trim())`""
                        RegistryKey = ""
                        Architecture = "Package"
                        Source = "Winget"
                    }
                    $installedSoftware += $software
                }
            }
        }
        catch {
            Write-Log "Erreur lors de la détection Winget: $_" -Level ERROR
        }
    }
    
    Write-Log "Détection gestionnaires terminée. $($installedSoftware.Count) paquets trouvés"
    return $installedSoftware
}

function Get-AllInstalledSoftware {
    <#
    .SYNOPSIS
        Fonction principale pour récupérer tous les logiciels installés
    .DESCRIPTION
        Combine toutes les méthodes de détection disponibles
    .PARAMETER UseCache
        Utilise le cache si disponible et valide
    .PARAMETER IncludeWMI
        Inclut la détection WMI (plus lente)
    .OUTPUTS
        Array d'objets contenant tous les logiciels détectés
    #>
    [CmdletBinding()]
    param(
        [switch]$UseCache,
        [switch]$IncludeWMI
    )
    
    # Vérification du cache
    if ($UseCache -and $script:SoftwareCache.ContainsKey('Data')) {
        $cacheAge = (Get-Date) - $script:SoftwareCache['Timestamp']
        if ($cacheAge.TotalSeconds -lt $script:CacheExpiry) {
            Write-Log "Utilisation du cache (âge: $([math]::Round($cacheAge.TotalSeconds))s)"
            return $script:SoftwareCache['Data']
        }
    }
    
    Write-Log "Début de la détection complète des logiciels installés"
    $allSoftware = @()
    
    # Détection depuis le registre (rapide et fiable)
    $registrySoftware = Get-InstalledSoftwareFromRegistry
    $allSoftware += $registrySoftware
    
    # Détection via gestionnaires de paquets
    $packageSoftware = Get-InstalledSoftwareFromPackageManager  
    $allSoftware += $packageSoftware
    
    # Détection WMI (optionnelle car lente)
    if ($IncludeWMI) {
        $wmiSoftware = Get-InstalledSoftwareFromWMI
        $allSoftware += $wmiSoftware
    }
    
    # Suppression des doublons basée sur le nom
    $uniqueSoftware = $allSoftware | 
                     Group-Object -Property Name | 
                     ForEach-Object { 
                         # Prioriser Registry > Package > WMI
                         $_.Group | Sort-Object @{
                             Expression = {
                                 switch ($_.Source) {
                                     'Registry' { 1 }
                                     'Chocolatey' { 2 }
                                     'Winget' { 3 }
                                     'WMI' { 4 }
                                     default { 5 }
                                 }
                             }
                         } | Select-Object -First 1
                     }
    
    # Tri par nom
    $uniqueSoftware = $uniqueSoftware | Sort-Object Name
    
    # Mise à jour du cache
    $script:SoftwareCache = @{
        'Data' = $uniqueSoftware
        'Timestamp' = Get-Date
    }
    
    Write-Log "Détection terminée. $($uniqueSoftware.Count) logiciels uniques trouvés"
    return $uniqueSoftware
}

function Find-SoftwareByName {
    <#
    .SYNOPSIS
        Recherche un logiciel spécifique par nom
    .PARAMETER Name
        Nom du logiciel à rechercher (supporte les wildcards)
    .PARAMETER ExactMatch
        Recherche exacte (pas de wildcards)
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Name,
        
        [switch]$ExactMatch
    )
    
    $allSoftware = Get-AllInstalledSoftware -UseCache
    
    if ($ExactMatch) {
        return $allSoftware | Where-Object { $_.Name -eq $Name }
    }
    else {
        return $allSoftware | Where-Object { $_.Name -like "*$Name*" }
    }
}

function Test-SoftwareInstalled {
    <#
    .SYNOPSIS
        Vérifie si un logiciel est installé
    .PARAMETER Name
        Nom du logiciel à vérifier
    .OUTPUTS
        Boolean indiquant si le logiciel est installé
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Name
    )
    
    $software = Find-SoftwareByName -Name $Name
    return ($software.Count -gt 0)
}

function Get-SoftwareVersion {
    <#
    .SYNOPSIS
        Récupère la version d'un logiciel installé
    .PARAMETER Name
        Nom du logiciel
    .OUTPUTS
        String contenant la version ou $null si non trouvé
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Name
    )
    
    $software = Find-SoftwareByName -Name $Name -ExactMatch | Select-Object -First 1
    return $software.Version
}

#endregion

#region Fonctions de comparaison de versions

function Compare-Version {
    <#
    .SYNOPSIS
        Compare deux versions de logiciels
    .PARAMETER Version1
        Première version à comparer
    .PARAMETER Version2
        Seconde version à comparer
    .OUTPUTS
        -1 si Version1 < Version2, 0 si égales, 1 si Version1 > Version2
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Version1,
        
        [Parameter(Mandatory)]
        [string]$Version2
    )
    
    try {
        $v1 = [Version]$Version1
        $v2 = [Version]$Version2
        return $v1.CompareTo($v2)
    }
    catch {
        # Fallback pour les versions non standard
        if ($Version1 -eq $Version2) { return 0 }
        if ($Version1 -lt $Version2) { return -1 }
        return 1
    }
}

function Test-UpdateAvailable {
    <#
    .SYNOPSIS
        Vérifie si une mise à jour est disponible pour un logiciel
    .PARAMETER SoftwareName
        Nom du logiciel
    .PARAMETER LatestVersion
        Version la plus récente disponible
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$SoftwareName,
        
        [Parameter(Mandatory)]
        [string]$LatestVersion
    )
    
    $currentVersion = Get-SoftwareVersion -Name $SoftwareName
    if (-not $currentVersion) {
        return $false
    }
    
    $comparison = Compare-Version -Version1 $currentVersion -Version2 $LatestVersion
    return ($comparison -lt 0)
}

#endregion

#region Export des fonctions

Export-ModuleMember -Function @(
    'Get-AllInstalledSoftware',
    'Find-SoftwareByName', 
    'Test-SoftwareInstalled',
    'Get-SoftwareVersion',
    'Compare-Version',
    'Test-UpdateAvailable',
    'Get-InstalledSoftwareFromRegistry',
    'Get-InstalledSoftwareFromWMI',
    'Get-InstalledSoftwareFromPackageManager'
)

#endregion

# Initialisation du module
Write-Log "Module Detection.psm1 chargé avec succès"