#Requires -Version 5.1

<#
.SYNOPSIS
    Module de détection des logiciels - UpdatesFaciles Module 3
.DESCRIPTION
    Détection complète des logiciels installés, portables, raccourcis et cloud
    Conforme aux exigences UpdatesFaciles_Prompt7.md
.NOTES
    Fichier : Modules/SoftwareDetection/SoftwareDetection.psm1
    Version : 3.0
    Auteur : UpdatesFaciles Team
#>

# =============================================================================
# VARIABLES GLOBALES ET CONFIGURATION
# =============================================================================

$Script:DetectionConfig = @{
    TimeoutSeconds = 300  # 5 minutes max
    MaxConcurrentJobs = 5
    EnablePortableDetection = $true
    EnableShortcutDetection = $true
    EnableUpdateCheck = $true
    DebugMode = $false
}

# Chemins standards de détection
$Script:StandardPaths = @{
    ProgramFiles = @(
        "${env:ProgramFiles}",
        "${env:ProgramFiles(x86)}"
    )
    PortableApps = @(
        "C:\PortableApps",
        "$env:USERPROFILE\PortableApps",
        "$env:OneDrive\PortableApps",
        "$env:OneDriveCommercial\PortableApps"
    )
    CloudSync = @(
        "$env:OneDrive",
        "$env:OneDriveCommercial", 
        "$env:USERPROFILE\Google Drive",
        "$env:USERPROFILE\Dropbox"
    )
    Shortcuts = @{
        Desktop = "$env:USERPROFILE\Desktop"
        StartMenu = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs"
        CommonStartMenu = "$env:ALLUSERSPROFILE\Microsoft\Windows\Start Menu\Programs"
    }
}

# Registres Windows pour logiciels installés
$Script:RegistryPaths = @(
    "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
)

Write-Host "Module SoftwareDetection chargé - Version 3.0" -ForegroundColor Green

# =============================================================================
# FONCTIONS UTILITAIRES
# =============================================================================

function Write-DetectionLog {
    <#
    .SYNOPSIS
        Écriture de logs de détection
    .PARAMETER Message
        Message à logger
    .PARAMETER Level
        Niveau : Info, Warning, Error, Debug
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Message,
        
        [ValidateSet("Info", "Warning", "Error", "Debug")]
        [string]$Level = "Info"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"
    
    switch ($Level) {
        "Info" { if ($Script:DetectionConfig.DebugMode) { Write-Host $logMessage -ForegroundColor White } }
        "Warning" { Write-Warning $logMessage }
        "Error" { Write-Error $logMessage }
        "Debug" { if ($Script:DetectionConfig.DebugMode) { Write-Host $logMessage -ForegroundColor Cyan } }
    }
}

function Test-PathSafely {
    <#
    .SYNOPSIS
        Test d'existence de chemin sécurisé
    .PARAMETER Path
        Chemin à tester
    #>
    [CmdletBinding()]
    param([string]$Path)
    
    try {
        return (Test-Path $Path -ErrorAction SilentlyContinue)
    }
    catch {
        Write-DetectionLog "Erreur test chemin $Path : $($_.Exception.Message)" "Error"
        return $false
    }
}

function Get-FileVersionSafely {
    <#
    .SYNOPSIS
        Récupération sécurisée de version de fichier
    .PARAMETER FilePath
        Chemin du fichier
    #>
    [CmdletBinding()]
    param([string]$FilePath)
    
    try {
        if (Test-PathSafely $FilePath) {
            $versionInfo = [System.Diagnostics.FileVersionInfo]::GetVersionInfo($FilePath)
            return @{
                Version = $versionInfo.FileVersion
                ProductVersion = $versionInfo.ProductVersion
                CompanyName = $versionInfo.CompanyName
                ProductName = $versionInfo.ProductName
                FileDescription = $versionInfo.FileDescription
            }
        }
    }
    catch {
        Write-DetectionLog "Erreur version fichier $FilePath : $($_.Exception.Message)" "Debug"
    }
    
    return $null
}

# =============================================================================
# DÉTECTION LOGICIELS INSTALLÉS (REGISTRE)
# =============================================================================

function Get-InstalledSoftware {
    <#
    .SYNOPSIS
        Détection des logiciels installés via le registre Windows
    .DESCRIPTION
        Scan des clés de registre pour identifier tous les logiciels installés
    .PARAMETER IncludeSystemComponents
        Inclure les composants système
    .EXAMPLE
        Get-InstalledSoftware
    #>
    [CmdletBinding()]
    param(
        [switch]$IncludeSystemComponents
    )
    
    Write-DetectionLog "Début détection logiciels installés" "Info"
    $installedSoftware = @()
    $processedCount = 0
    
    try {
        foreach ($registryPath in $Script:RegistryPaths) {
            Write-DetectionLog "Scan registre : $registryPath" "Debug"
            
            try {
                $registryItems = Get-ItemProperty $registryPath -ErrorAction SilentlyContinue | 
                    Where-Object { 
                        $_.DisplayName -and 
                        (-not $_.SystemComponent -or $IncludeSystemComponents) -and
                        (-not $_.ParentKeyName) -and
                        ($_.DisplayName -notmatch "^(Update|Hotfix|Security Update)")
                    }
                
                foreach ($item in $registryItems) {
                    $processedCount++
                    
                    try {
                        # Import de la fonction New-SoftwareApp si pas déjà chargée
                        if (-not (Get-Command New-SoftwareApp -ErrorAction SilentlyContinue)) {
                            Write-DetectionLog "Fonction New-SoftwareApp non trouvée - Tentative de chargement" "Warning"
                            continue
                        }
                        
                        $software = New-SoftwareApp -Name $item.DisplayName `
                                                  -Version ($item.DisplayVersion -replace "^\s*$", "Inconnu") `
                                                  -Publisher ($item.Publisher -replace "^\s*$", "Inconnu") `
                                                  -InstallLocation ($item.InstallLocation -replace "^\s*$", "Inconnu") `
                                                  -Source "Installé" `
                                                  -State "À vérifier"
                        
                        $installedSoftware += $software
                        
                        if ($processedCount % 50 -eq 0) {
                            Write-DetectionLog "Progression : $processedCount logiciels traités" "Debug"
                        }
                    }
                    catch {
                        Write-DetectionLog "Erreur traitement élément registre : $($_.Exception.Message)" "Error"
                    }
                }
            }
            catch {
                Write-DetectionLog "Erreur accès registre $registryPath : $($_.Exception.Message)" "Error"
            }
        }
        
        Write-DetectionLog "Détection installés terminée : $($installedSoftware.Count) logiciels trouvés" "Info"
        return $installedSoftware
    }
    catch {
        Write-DetectionLog "Erreur générale détection installés : $($_.Exception.Message)" "Error"
        return @()
    }
}

# =============================================================================
# DÉTECTION LOGICIELS PORTABLES
# =============================================================================

function Get-PortableSoftware {
    <#
    .SYNOPSIS
        Détection des logiciels portables
    .DESCRIPTION
        Scan des dossiers standards pour identifier les applications portables
    .PARAMETER CustomPaths
        Chemins personnalisés à scanner
    .EXAMPLE
        Get-PortableSoftware -CustomPaths @("D:\MyPortableApps")
    #>
    [CmdletBinding()]
    param(
        [string[]]$CustomPaths = @()
    )
    
    if (-not $Script:DetectionConfig.EnablePortableDetection) {
        Write-DetectionLog "Détection portable désactivée" "Info"
        return @()
    }
    
    Write-DetectionLog "Début détection logiciels portables" "Info"
    $portableSoftware = @()
    
    # Combinaison des chemins standards et personnalisés
    $allPaths = $Script:StandardPaths.PortableApps + $Script:StandardPaths.CloudSync + $CustomPaths
    
    foreach ($basePath in $allPaths) {
        if (-not (Test-PathSafely $basePath)) {
            Write-DetectionLog "Chemin portable inexistant : $basePath" "Debug"
            continue
        }
        
        Write-DetectionLog "Scan dossier portable : $basePath" "Debug"
        
        try {
            # Recherche des exécutables dans les sous-dossiers
            $executables = Get-ChildItem -Path $basePath -Recurse -Include "*.exe" -ErrorAction SilentlyContinue |
                Where-Object { 
                    $_.Directory.Name -notmatch "^(temp|cache|logs?|backup|unins)" -and
                    $_.Name -notmatch "^(unins|setup|install)" 
                } |
                Select-Object -First 100  # Limitation pour performance
            
            foreach ($exe in $executables) {
                try {
                    $versionInfo = Get-FileVersionSafely $exe.FullName
                    
                    if (-not (Get-Command New-SoftwareApp -ErrorAction SilentlyContinue)) {
                        Write-DetectionLog "Fonction New-SoftwareApp non trouvée" "Warning"
                        continue
                    }
                    
                    $name = if ($versionInfo -and $versionInfo.ProductName) { 
                        $versionInfo.ProductName 
                    } else { 
                        $exe.BaseName 
                    }
                    
                    $version = if ($versionInfo -and $versionInfo.ProductVersion) { 
                        $versionInfo.ProductVersion 
                    } else { 
                        "Inconnu" 
                    }
                    
                    $publisher = if ($versionInfo -and $versionInfo.CompanyName) { 
                        $versionInfo.CompanyName 
                    } else { 
                        "Inconnu" 
                    }
                    
                    # Détection si dans dossier cloud synchronisé
                    $sourceType = if ($basePath -match "(OneDrive|Google Drive|Dropbox)") { "Cloud" } else { "Portable" }
                    
                    $software = New-SoftwareApp -Name $name `
                                              -Version $version `
                                              -Publisher $publisher `
                                              -InstallLocation $exe.DirectoryName `
                                              -Source $sourceType `
                                              -State "À vérifier"
                    
                    $portableSoftware += $software
                }
                catch {
                    Write-DetectionLog "Erreur traitement portable $($exe.FullName) : $($_.Exception.Message)" "Debug"
                }
            }
        }
        catch {
            Write-DetectionLog "Erreur scan dossier $basePath : $($_.Exception.Message)" "Error"
        }
    }
    
    Write-DetectionLog "Détection portables terminée : $($portableSoftware.Count) logiciels trouvés" "Info"
    return $portableSoftware
}

# =============================================================================
# DÉTECTION RACCOURCIS
# =============================================================================

function Get-ShortcutSoftware {
    <#
    .SYNOPSIS
        Détection des logiciels via raccourcis
    .DESCRIPTION
        Analyse des raccourcis sur le bureau et dans le menu démarrer
    .EXAMPLE
        Get-ShortcutSoftware
    #>
    [CmdletBinding()]
    param()
    
    if (-not $Script:DetectionConfig.EnableShortcutDetection) {
        Write-DetectionLog "Détection raccourcis désactivée" "Info"
        return @()
    }
    
    Write-DetectionLog "Début détection logiciels via raccourcis" "Info"
    $shortcutSoftware = @()
    
    # Création de l'objet COM pour lire les raccourcis
    try {
        $shell = New-Object -ComObject WScript.Shell
    }
    catch {
        Write-DetectionLog "Impossible de créer l'objet WScript.Shell : $($_.Exception.Message)" "Error"
        return @()
    }
    
    foreach ($location in $Script:StandardPaths.Shortcuts.Values) {
        if (-not (Test-PathSafely $location)) {
            Write-DetectionLog "Dossier raccourcis inexistant : $location" "Debug"
            continue
        }
        
        Write-DetectionLog "Scan raccourcis : $location" "Debug"
        
        try {
            $shortcuts = Get-ChildItem -Path $location -Recurse -Include "*.lnk" -ErrorAction SilentlyContinue |
                Select-Object -First 50  # Limitation pour performance
            
            foreach ($shortcut in $shortcuts) {
                try {
                    $link = $shell.CreateShortcut($shortcut.FullName)
                    $targetPath = $link.TargetPath
                    
                    if ($targetPath -and (Test-PathSafely $targetPath) -and $targetPath -match "\.exe$") {
                        $versionInfo = Get-FileVersionSafely $targetPath
                        
                        if (-not (Get-Command New-SoftwareApp -ErrorAction SilentlyContinue)) {
                            continue
                        }
                        
                        $name = if ($versionInfo -and $versionInfo.ProductName) { 
                            $versionInfo.ProductName 
                        } else { 
                            $shortcut.BaseName 
                        }
                        
                        $version = if ($versionInfo -and $versionInfo.ProductVersion) { 
                            $versionInfo.ProductVersion 
                        } else { 
                            "Inconnu" 
                        }
                        
                        $publisher = if ($versionInfo -and $versionInfo.CompanyName) { 
                            $versionInfo.CompanyName 
                        } else { 
                            "Inconnu" 
                        }
                        
                        $software = New-SoftwareApp -Name $name `
                                                  -Version $version `
                                                  -Publisher $publisher `
                                                  -InstallLocation (Split-Path $targetPath -Parent) `
                                                  -Source "Raccourci" `
                                                  -State "À vérifier"
                        
                        $shortcutSoftware += $software
                    }
                }
                catch {
                    Write-DetectionLog "Erreur traitement raccourci $($shortcut.FullName) : $($_.Exception.Message)" "Debug"
                }
            }
        }
        catch {
            Write-DetectionLog "Erreur scan raccourcis $location : $($_.Exception.Message)" "Error"
        }
    }
    
    # Nettoyage objet COM
    try {
        [System.Runtime.Interopservices.Marshal]::ReleaseComObject($shell) | Out-Null
    }
    catch {
        Write-DetectionLog "Erreur nettoyage objet COM : $($_.Exception.Message)" "Debug"
    }
    
    Write-DetectionLog "Détection raccourcis terminée : $($shortcutSoftware.Count) logiciels trouvés" "Info"
    return $shortcutSoftware
}

# =============================================================================
# FONCTION PRINCIPALE DE DÉTECTION
# =============================================================================

function Invoke-SoftwareDetection {
    <#
    .SYNOPSIS
        Fonction principale de détection de logiciels
    .DESCRIPTION
        Lance la détection complète : installés, portables, raccourcis
        Dédoublonne et consolide les résultats
    .PARAMETER IncludeInstalled
        Inclure la détection des logiciels installés
    .PARAMETER IncludePortable
        Inclure la détection des logiciels portables
    .PARAMETER IncludeShortcuts
        Inclure la détection via raccourcis
    .PARAMETER CustomPortablePaths
        Chemins personnalisés pour les portables
    .PARAMETER DebugMode
        Active le mode debug détaillé
    .EXAMPLE
        Invoke-SoftwareDetection -DebugMode
    .EXAMPLE
        Invoke-SoftwareDetection -IncludeInstalled -IncludePortable -CustomPortablePaths @("D:\Apps")
    #>
    [CmdletBinding()]
    param(
        [switch]$IncludeInstalled = $true,
        [switch]$IncludePortable = $true,
        [switch]$IncludeShortcuts = $true,
        [string[]]$CustomPortablePaths = @(),
        [switch]$DebugMode
    )
    
    # Configuration du mode debug
    $Script:DetectionConfig.DebugMode = $DebugMode.IsPresent
    
    Write-DetectionLog "=== DÉBUT DÉTECTION COMPLÈTE ===" "Info"
    Write-DetectionLog "Options : Installés=$IncludeInstalled, Portables=$IncludePortable, Raccourcis=$IncludeShortcuts" "Info"
    
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    $allSoftware = @()
    
    try {
        # Détection logiciels installés
        if ($IncludeInstalled) {
            Write-DetectionLog "--- Phase 1 : Logiciels installés ---" "Info"
            $installed = Get-InstalledSoftware
            $allSoftware += $installed
            Write-DetectionLog "Phase 1 terminée : $($installed.Count) logiciels installés" "Info"
        }
        
        # Détection logiciels portables
        if ($IncludePortable) {
            Write-DetectionLog "--- Phase 2 : Logiciels portables ---" "Info"
            $portable = Get-PortableSoftware -CustomPaths $CustomPortablePaths
            $allSoftware += $portable
            Write-DetectionLog "Phase 2 terminée : $($portable.Count) logiciels portables" "Info"
        }
        
        # Détection via raccourcis
        if ($IncludeShortcuts) {
            Write-DetectionLog "--- Phase 3 : Raccourcis ---" "Info"
            $shortcuts = Get-ShortcutSoftware
            $allSoftware += $shortcuts
            Write-DetectionLog "Phase 3 terminée : $($shortcuts.Count) raccourcis" "Info"
        }
        
        # Dédoublonnage intelligent
        Write-DetectionLog "--- Phase 4 : Dédoublonnage ---" "Info"
        $uniqueSoftware = Remove-DuplicateSoftware $allSoftware
        
        $stopwatch.Stop()
        
        Write-DetectionLog "=== DÉTECTION TERMINÉE ===" "Info"
        Write-DetectionLog "Total brut : $($allSoftware.Count) éléments" "Info"
        Write-DetectionLog "Total unique : $($uniqueSoftware.Count) logiciels" "Info"
        Write-DetectionLog "Durée : $([math]::Round($stopwatch.Elapsed.TotalSeconds, 2)) secondes" "Info"
        
        return $uniqueSoftware
    }
    catch {
        $stopwatch.Stop()
        Write-DetectionLog "ERREUR CRITIQUE détection : $($_.Exception.Message)" "Error"
        Write-DetectionLog "Stack trace : $($_.ScriptStackTrace)" "Error"
        return @()
    }
}

# =============================================================================
# DÉDOUBLONNAGE ET CONSOLIDATION
# =============================================================================

function Remove-DuplicateSoftware {
    <#
    .SYNOPSIS
        Supprime les doublons et consolide les informations
    .PARAMETER SoftwareList
        Liste des logiciels à dédoublonner
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [array]$SoftwareList
    )
    
    Write-DetectionLog "Début dédoublonnage de $($SoftwareList.Count) éléments" "Debug"
    
    $grouped = $SoftwareList | Group-Object -Property Name | Where-Object { $_.Name -and $_.Name -ne "Inconnu" }
    $uniqueSoftware = @()
    
    foreach ($group in $grouped) {
        try {
            # Prendre le logiciel avec le plus d'informations
            $bestSoftware = $group.Group | 
                Sort-Object @{Expression={($_.Publisher -ne "Inconnu")}; Descending=$true},
                           @{Expression={($_.Version -ne "Inconnu")}; Descending=$true},
                           @{Expression={($_.InstallLocation -ne "Inconnu")}; Descending=$true} |
                Select-Object -First 1
            
            # Consolider les sources multiples
            $sources = ($group.Group | Select-Object -ExpandProperty Source -Unique) -join ", "
            $bestSoftware.Source = $sources
            
            $uniqueSoftware += $bestSoftware
        }
        catch {
            Write-DetectionLog "Erreur dédoublonnage groupe '$($group.Name)' : $($_.Exception.Message)" "Error"
        }
    }
    
    Write-DetectionLog "Dédoublonnage terminé : $($uniqueSoftware.Count) logiciels uniques" "Debug"
    return $uniqueSoftware
}

# =============================================================================
# FONCTIONS DE CONFIGURATION
# =============================================================================

function Set-DetectionConfig {
    <#
    .SYNOPSIS
        Configure les paramètres de détection
    .PARAMETER TimeoutSeconds
        Timeout maximum en secondes
    .PARAMETER EnablePortableDetection
        Active/désactive la détection portable
    .PARAMETER EnableShortcutDetection
        Active/désactive la détection raccourcis
    .PARAMETER DebugMode
        Active/désactive le mode debug
    .EXAMPLE
        Set-DetectionConfig -TimeoutSeconds 600 -DebugMode $true
    #>
    [CmdletBinding()]
    param(
        [int]$TimeoutSeconds,
        [bool]$EnablePortableDetection,
        [bool]$EnableShortcutDetection,
        [bool]$DebugMode
    )
    
    if ($PSBoundParameters.ContainsKey('TimeoutSeconds')) {
        $Script:DetectionConfig.TimeoutSeconds = $TimeoutSeconds
    }
    if ($PSBoundParameters.ContainsKey('EnablePortableDetection')) {
        $Script:DetectionConfig.EnablePortableDetection = $EnablePortableDetection
    }
    if ($PSBoundParameters.ContainsKey('EnableShortcutDetection')) {
        $Script:DetectionConfig.EnableShortcutDetection = $EnableShortcutDetection
    }
    if ($PSBoundParameters.ContainsKey('DebugMode')) {
        $Script:DetectionConfig.DebugMode = $DebugMode
    }
    
    Write-DetectionLog "Configuration mise à jour" "Info"
}

function Get-DetectionConfig {
    <#
    .SYNOPSIS
        Retourne la configuration actuelle
    #>
    return $Script:DetectionConfig
}

# =============================================================================
# EXPORT DES FONCTIONS
# =============================================================================

Export-ModuleMember -Function @(
    'Invoke-SoftwareDetection',
    'Get-InstalledSoftware', 
    'Get-PortableSoftware',
    'Get-ShortcutSoftware',
    'Set-DetectionConfig',
    'Get-DetectionConfig',
    'Remove-DuplicateSoftware'
)