#Requires -Version 5.1

<#
.SYNOPSIS
    Module de détection des logiciels - UpdatesFaciles Module 3
.DESCRIPTION
    Détection complète des logiciels installés, portables, raccourcis et cloud
    Conforme aux exigences UpdatesFaciles_Prompt.txt
.NOTES
    Fichier : Sources/SoftwareDetection.psm1
    Version : 3.3
    Auteur : UpdatesFaciles Team
    Date : 2025-08-07
    Notes : Correction absence Get-ShortcutSoftware, suppression doublon Get-PortableSoftware, amélioration déduplication
#>

# Vérification des dépendances
if (-not (Test-Path P:\Git\UpdatesFaciles\Sources\SoftwareApp.psm1)) {
    Write-Error "Module SoftwareApp.psm1 requis à P:\Git\UpdatesFaciles\Sources\SoftwareApp.psm1"
    return
}
Import-Module P:\Git\UpdatesFaciles\Sources\SoftwareApp.psm1 -Force

Write-Host "Module SoftwareDetection chargé - Version 3.3" -ForegroundColor Green
Write-Host "Fonctions disponibles : $(Get-Command -Module SoftwareDetection | Select-Object -ExpandProperty Name)" -ForegroundColor Green

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

$Script:StandardPaths = @{
    ProgramFiles = @(
        "${env:ProgramFiles}",
        "${env:ProgramFiles(x86)}"
    )
    PortableApps = @(
        "C:\PortableApps",
        "$env:USERPROFILE\PortableApps"
    )
    CloudSync = @() # Chemins cloud désactivés par défaut
    Shortcuts = @{
        Desktop = "$env:USERPROFILE\Desktop"
        StartMenu = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs"
        CommonStartMenu = "$env:ALLUSERSPROFILE\Microsoft\Windows\Start Menu\Programs"
    }
}

$Script:RegistryPaths = @(
    "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
)

# =============================================================================
# FONCTIONS UTILITAIRES
# =============================================================================

function Write-DetectionLog {
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
                        $software = New-SoftwareApp -Name $item.DisplayName `
                                                  -Version ($item.DisplayVersion -replace "^\s*$", "Inconnu") `
                                                  -Publisher ($item.Publisher -replace "^\s*$", "Inconnu") `
                                                  -Path ($item.InstallLocation -replace "^\s*$", "Inconnu") `
                                                  -Source "Installé" `
                                                  -State "Inconnu"
                        
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
    
    $allPaths = $Script:StandardPaths.PortableApps + $Script:StandardPaths.CloudSync + $CustomPaths
    
    foreach ($basePath in $allPaths) {
        if (-not (Test-PathSafely $basePath)) {
            Write-DetectionLog "Chemin portable inexistant : $basePath" "Debug"
            continue
        }
        
        Write-DetectionLog "Scan dossier portable : $basePath" "Debug"
        
        try {
            $executables = Get-ChildItem -Path $basePath -Recurse -Include "*.exe" -ErrorAction SilentlyContinue |
                Where-Object { 
                    $_.Directory.Name -notmatch "^(temp|cache|logs?|backup|unins)" -and
                    $_.Name -notmatch "^(unins|setup|install)" 
                } |
                Group-Object -Property DirectoryName |
                ForEach-Object {
                    $_.Group | Sort-Object {
                        $versionInfo = Get-FileVersionSafely $_.FullName
                        $versionString = if ($versionInfo -and $versionInfo.ProductVersion) {
                            $versionInfo.ProductVersion
                        } else {
                            "0.0"
                        }
                        try {
                            [Version]::Parse(($versionString -replace '[^\d.]', ''))
                        } catch {
                            Write-DetectionLog "Version invalide pour $($_.FullName) : $versionString" "Debug"
                            [Version]::new(0,0)
                        }
                    } -Descending | Select-Object -First 1
                }
            
            if (-not $executables) {
                Write-DetectionLog "Aucun exécutable trouvé dans $basePath" "Debug"
                continue
            }
            
            foreach ($exe in $executables) {
                try {
                    $versionInfo = Get-FileVersionSafely $exe.FullName
                    
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
                    
                    $sourceType = if ($basePath -match "(OneDrive|Google Drive|Dropbox)") { "Cloud" } else { "Portable" }
                    
                    $software = New-SoftwareApp -Name $name `
                                              -Version $version `
                                              -Publisher $publisher `
                                              -Path $exe.DirectoryName `
                                              -Source $sourceType `
                                              -State "Inconnu"
                    
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
    [CmdletBinding()]
    param()
    
    if (-not $Script:DetectionConfig.EnableShortcutDetection) {
        Write-DetectionLog "Détection raccourcis désactivée" "Info"
        return @()
    }
    
    Write-DetectionLog "Début détection logiciels via raccourcis" "Info"
    $shortcutSoftware = @()
    
    try {
        $shell = New-Object -ComObject WScript.Shell
        Write-DetectionLog "Objet WScript.Shell créé (Type: $($shell.GetType().FullName))" "Debug"
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
                Select-Object -First 50
            Write-DetectionLog "Raccourcis trouvés dans $location : $($shortcuts.Count)" "Debug"
        }
        catch {
            Write-DetectionLog "Erreur scan raccourcis $location : $($_.Exception.Message)" "Error"
            continue
        }
        
        foreach ($shortcut in $shortcuts) {
            Write-DetectionLog "Traitement raccourci : $($shortcut.FullName)" "Debug"
            try {
                $link = $shell.CreateShortcut($shortcut.FullName)
                Write-DetectionLog "Shortcut créé pour : $($shortcut.FullName)" "Debug"
                $targetPath = $link.TargetPath
                Write-DetectionLog "TargetPath brut : '$targetPath'" "Debug"
                
                if ([string]::IsNullOrWhiteSpace($targetPath)) {
                    Write-DetectionLog "TargetPath est vide ou null pour $($shortcut.FullName)" "Debug"
                    continue
                }
                
                if (-not (Test-PathSafely $targetPath)) {
                    Write-DetectionLog "TargetPath n'existe pas : $targetPath" "Debug"
                    continue
                }
                
                if (-not ($targetPath -match "\.exe$")) {
                    Write-DetectionLog "TargetPath n'est pas un exécutable : $targetPath" "Debug"
                    continue
                }
                
                Write-DetectionLog "TargetPath valide : $targetPath" "Debug"
                $versionInfo = Get-FileVersionSafely $targetPath
                Write-DetectionLog "VersionInfo : $($versionInfo | ConvertTo-Json -Depth 2)" "Debug"
                
                $name = if ($versionInfo -and $versionInfo.ProductName) { 
                    $versionInfo.ProductName 
                } else { 
                    $shortcut.BaseName 
                }
                Write-DetectionLog "Nom détecté : $name" "Debug"
                
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
                                          -Path (Split-Path $targetPath -Parent) `
                                          -Source "Raccourci" `
                                          -State "Inconnu"
                Write-DetectionLog "Logiciel ajouté : $($software.Name)" "Debug"
                
                $shortcutSoftware += $software
            }
            catch {
                Write-DetectionLog "Erreur traitement raccourci $($shortcut.FullName) : $($_.Exception.Message)" "Debug"
            }
        }
    }
    
    try {
        [System.Runtime.Interopservices.Marshal]::ReleaseComObject($shell) | Out-Null
        Write-DetectionLog "Objet COM libéré" "Debug"
    }
    catch {
        Write-DetectionLog "Erreur nettoyage objet COM : $($_.Exception.Message)" "Debug"
    }
    
    Write-DetectionLog "Détection raccourcis terminée : $($shortcutSoftware.Count) logiciels trouvés" "Info"
    return $shortcutSoftware
}

# =============================================================================
# CONFIGURATION DES CHEMINS CLOUD
# =============================================================================

function Enable-CloudSyncDetection {
    [CmdletBinding()]
    param(
        [switch]$OneDrive,
        [switch]$GoogleDrive,
        [switch]$Dropbox
    )
    
    $cloudPaths = @()
    if ($OneDrive) { $cloudPaths += "$env:OneDrive" }
    if ($GoogleDrive) { $cloudPaths += "$env:USERPROFILE\Google Drive" }
    if ($Dropbox) { $cloudPaths += "$env:USERPROFILE\Dropbox" }
    $Script:StandardPaths.CloudSync = $cloudPaths
    Write-DetectionLog "Cloud sync activé : $($cloudPaths -join ', ')" "Info"
}

# =============================================================================
# FONCTION PRINCIPALE DE DÉTECTION
# =============================================================================

function Invoke-SoftwareDetection {
    [CmdletBinding()]
    param(
        [switch]$IncludeInstalled = $true,
        [switch]$IncludePortable = $true,
        [switch]$IncludeShortcuts = $true,
        [string[]]$CustomPortablePaths = @(),
        [switch]$DebugMode
    )
    
    $Script:DetectionConfig.DebugMode = $DebugMode.IsPresent
    
    Write-DetectionLog "=== DÉBUT DÉTECTION COMPLÈTE ===" "Info"
    Write-DetectionLog "Options : Installés=$IncludeInstalled, Portables=$IncludePortable, Raccourcis=$IncludeShortcuts" "Info"
    
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    $allSoftware = @()
    
    try {
        if ($IncludeInstalled) {
            Write-DetectionLog "--- Phase 1 : Logiciels installés ---" "Info"
            $installed = Get-InstalledSoftware
            $allSoftware += $installed
            Write-DetectionLog "Phase 1 terminée : $($installed.Count) logiciels installés" "Info"
        }
        
        if ($IncludePortable) {
            Write-DetectionLog "--- Phase 2 : Logiciels portables ---" "Info"
            $portable = Get-PortableSoftware -CustomPaths $CustomPortablePaths
            $allSoftware += $portable
            Write-DetectionLog "Phase 2 terminée : $($portable.Count) logiciels portables" "Info"
        }
        
        if ($IncludeShortcuts) {
            Write-DetectionLog "--- Phase 3 : Raccourcis ---" "Info"
            $shortcuts = Get-ShortcutSoftware
            $allSoftware += $shortcuts
            Write-DetectionLog "Phase 3 terminée : $($shortcuts.Count) raccourcis" "Info"
        }
        
        Write-DetectionLog "--- Phase 4 : Dédoublonnage ---" "Info"
        if ($allSoftware -and $allSoftware.Count -gt 0) {
            Write-DetectionLog "Appel Remove-DuplicateSoftware avec $($allSoftware.Count) éléments" "Debug"
            $uniqueSoftware = Remove-DuplicateSoftware -SoftwareList $allSoftware
        } else {
            Write-DetectionLog "SoftwareList vide, retourne @()" "Debug"
            $uniqueSoftware = @()
        }
        
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
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [array]$SoftwareList
    )
    
    Write-DetectionLog "Début dédoublonnage de $($SoftwareList.Count) éléments" "Debug"
    
    if (-not $SoftwareList) {
        Write-DetectionLog "SoftwareList vide, retourne @()" "Debug"
        return @()
    }
    
    $uniqueSoftware = @()
    $seen = @{}
    
    foreach ($software in $SoftwareList) {
        try {
            if (-not $software.Name -or $software.Name -eq "Inconnu") {
                continue
            }
            
            # Créer une clé unique basée sur Name, Version, et Publisher (exclure Path pour plus de déduplication)
            $key = "$($software.Name)-$($software.Version)-$($software.Publisher)"
            
            if (-not $seen.ContainsKey($key)) {
                # Préférer la source dans l'ordre : Installé > Raccourci > Portable > Cloud
                $sourcePriority = @{
                    "Installé" = 4
                    "Raccourci" = 3
                    "Portable" = 2
                    "Cloud" = 1
                }
                $software.SourcePriority = $sourcePriority[$software.Source] ? $sourcePriority[$software.Source] : 0
                $seen[$key] = $software
            } else {
                # Si doublon, garder celui avec la priorité de source la plus élevée
                $existing = $seen[$key]
                $existingPriority = $existing.SourcePriority ? $existing.SourcePriority : 0
                $newPriority = $sourcePriority[$software.Source] ? $sourcePriority[$software.Source] : 0
                if ($newPriority -gt $existingPriority) {
                    $seen[$key] = $software
                }
                Write-DetectionLog "Doublon détecté : $($software.Name) (Version: $($software.Version), Source: $($software.Source), Path: $($software.Path))" "Debug"
            }
        }
        catch {
            Write-DetectionLog "Erreur dédoublonnage élément '$($software.Name)' : $($_.Exception.Message)" "Error"
        }
    }
    
    $uniqueSoftware = $seen.Values | Sort-Object { $_.SourcePriority } -Descending | ForEach-Object {
        $_.PSObject.Properties.Remove('SourcePriority')
        $_
    }
    
    Write-DetectionLog "Dédoublonnage terminé : $($uniqueSoftware.Count) logiciels uniques" "Debug"
    return $uniqueSoftware
}

# =============================================================================
# FONCTIONS DE CONFIGURATION
# =============================================================================

function Set-DetectionConfig {
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
    'Remove-DuplicateSoftware',
    'Enable-CloudSyncDetection'
)