#Requires -Version 5.1
<#
.SYNOPSIS
    Script d'installation pour UpdatesFaciles
.DESCRIPTION
    Configure l'environnement, crée la structure de dossiers, installe les modules requis
    et vérifie les dépendances pour le projet UpdatesFaciles.
.EXAMPLE
    .\Setup-UpdatesFaciles.ps1
.NOTES
    Auteur: UpdatesFaciles Team
    Version: 1.0
    Compatible: PowerShell 5.1+, .NET 4.7.2+
#>

[CmdletBinding()]
param(
    [string]$InstallPath = ".\UpdatesFaciles",
    [switch]$Force,
    [switch]$SkipModuleInstall
)

# Configuration des couleurs pour une meilleure lisibilité
$Host.UI.RawUI.ForegroundColor = "White"

function Write-SetupMessage {
    param(
        [string]$Message,
        [ValidateSet("Info", "Success", "Warning", "Error")]
        [string]$Type = "Info"
    )
    
    $colors = @{
        "Info" = "Cyan"
        "Success" = "Green" 
        "Warning" = "Yellow"
        "Error" = "Red"
    }
    
    Write-Host "[$Type] $Message" -ForegroundColor $colors[$Type]
}

function Test-Prerequisites {
    Write-SetupMessage "Vérification des prérequis..." -Type "Info"
    
    # Vérification PowerShell
    $psVersion = $PSVersionTable.PSVersion
    Write-SetupMessage "PowerShell version: $($psVersion.ToString())" -Type "Info"
    
    if ($psVersion.Major -lt 5) {
        Write-SetupMessage "PowerShell 5.1+ requis. Version actuelle: $($psVersion.ToString())" -Type "Error"
        return $false
    }
    
    # Vérification .NET Framework
    try {
        $dotnetVersion = [System.Runtime.InteropServices.RuntimeInformation]::FrameworkDescription
        Write-SetupMessage ".NET Framework: $dotnetVersion" -Type "Info"
    }
    catch {
        Write-SetupMessage "Impossible de détecter la version .NET Framework" -Type "Warning"
    }
    
    # Vérification des droits d'exécution
    $executionPolicy = Get-ExecutionPolicy
    if ($executionPolicy -eq "Restricted") {
        Write-SetupMessage "Policy d'exécution restrictive détectée: $executionPolicy" -Type "Warning"
        Write-SetupMessage "Exécutez: Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser" -Type "Info"
    }
    
    return $true
}

function New-ProjectStructure {
    param([string]$Path)
    
    Write-SetupMessage "Création de la structure de projet dans: $Path" -Type "Info"
    
    $folders = @(
        "Sources",
        "Models", 
        "ViewModels",
        "Views",
        "Views\Styles",
        "Actions",
        "Localization", 
        "Plugins",
        "Tests",
        "Libs",
        "Libs\MahApps.Metro",
        "Ressources",
        "Modules",
        "Modules\SoftwareApp",
        "Modules\Detection", 
        "Modules\Actions",
        "Modules\UI",
        "Modules\Logging",
        "Modules\Security"
    )
    
    try {
        if (-not (Test-Path $Path)) {
            New-Item -Path $Path -ItemType Directory -Force | Out-Null
        }
        
        foreach ($folder in $folders) {
            $fullPath = Join-Path $Path $folder
            if (-not (Test-Path $fullPath)) {
                New-Item -Path $fullPath -ItemType Directory -Force | Out-Null
                Write-SetupMessage "Créé: $folder" -Type "Success"
            }
        }
        
        # Création des fichiers de configuration de base
        $configFiles = @{
            "prefs.json" = '{"theme": "light", "language": "fr-FR", "scanOptions": {"installed": true, "portable": true, "shortcuts": true}}'
            "logs.txt" = "# UpdatesFaciles - Journal des opérations`n"
            "audit.log" = "# UpdatesFaciles - Audit sécurisé`n"
        }
        
        foreach ($file in $configFiles.GetEnumerator()) {
            $filePath = Join-Path $Path $file.Key
            if (-not (Test-Path $filePath)) {
                Set-Content -Path $filePath -Value $file.Value -Encoding UTF8
                Write-SetupMessage "Créé: $($file.Key)" -Type "Success"
            }
        }
        
        return $true
    }
    catch {
        Write-SetupMessage "Erreur lors de la création de la structure: $($_.Exception.Message)" -Type "Error"
        return $false
    }
}

function Install-RequiredModules {
    if ($SkipModuleInstall) {
        Write-SetupMessage "Installation des modules ignorée (SkipModuleInstall)" -Type "Warning"
        return
    }
    
    Write-SetupMessage "Installation des modules requis..." -Type "Info"
    
    $requiredModules = @(
        @{Name = "Pester"; MinVersion = "5.7.1"; Description = "Framework de tests unitaires"},
        @{Name = "platyPS"; MinVersion = "0.14.0"; Description = "Génération de documentation"},
        @{Name = "ChocolateyGet"; MinVersion = "4.1.0"; Description = "Gestion Chocolatey"; Optional = $true},
        @{Name = "CredentialManager"; MinVersion = "2.0"; Description = "Gestion sécurisée des identifiants"; Optional = $true}
    )
    
    foreach ($module in $requiredModules) {
        try {
            Write-SetupMessage "Vérification du module: $($module.Name)" -Type "Info"
            
            $installedModule = Get-Module -Name $module.Name -ListAvailable | 
                Sort-Object Version -Descending | Select-Object -First 1
            
            if ($installedModule) {
                if ($installedModule.Version -ge [Version]$module.MinVersion) {
                    Write-SetupMessage "$($module.Name) v$($installedModule.Version) - OK" -Type "Success"
                    continue
                }
                else {
                    Write-SetupMessage "$($module.Name) v$($installedModule.Version) - Mise à jour requise (min: $($module.MinVersion))" -Type "Warning"
                }
            }
            
            Write-SetupMessage "Installation de $($module.Name)..." -Type "Info"
            Install-Module -Name $module.Name -MinimumVersion $module.MinVersion -Scope CurrentUser -Force -AllowClobber
            Write-SetupMessage "$($module.Name) installé avec succès" -Type "Success"
        }
        catch {
            if ($module.Optional) {
                Write-SetupMessage "Module optionnel $($module.Name) non installé: $($_.Exception.Message)" -Type "Warning"
            }
            else {
                Write-SetupMessage "Erreur critique - Module $($module.Name): $($_.Exception.Message)" -Type "Error"
                throw
            }
        }
    }
}

function New-HelperModule {
    param([string]$ProjectPath)
    
    $helperPath = Join-Path $ProjectPath "PromptHelper.psm1"
    
    if (Test-Path $helperPath) {
        Write-SetupMessage "PromptHelper.psm1 existe déjà" -Type "Info"
        return
    }
    
    $helperContent = @'
# PromptHelper.psm1 - Utilitaires pour UpdatesFaciles
function Write-PromptLogo {
    <#
    .SYNOPSIS
        Affiche le logo ASCII d'UpdatesFaciles
    #>
    $logo = @"
    ╔══════════════════════════════════════╗
    ║           UpdatesFaciles             ║
    ║     Assistant de gestion logiciels   ║
    ║              v1.0.0                  ║
    ╚══════════════════════════════════════╝
"@
    Write-Host $logo -ForegroundColor Cyan
}

function Update-PromptNotes {
    <#
    .SYNOPSIS
        Journalise les changements dans le projet
    #>
    param(
        [string]$Message,
        [string]$Module,
        [string]$FilePath = ".\logs.txt"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Module] $Message"
    Add-Content -Path $FilePath -Value $logEntry -Encoding UTF8
}

function Test-MahAppsAvailability {
    <#
    .SYNOPSIS
        Vérifie la disponibilité de MahApps.Metro
    #>
    $mahAppsPath = ".\Libs\MahApps.Metro\MahApps.Metro.dll"
    return (Test-Path $mahAppsPath)
}

Export-ModuleMember -Function Write-PromptLogo, Update-PromptNotes, Test-MahAppsAvailability
'@
    
    try {
        Set-Content -Path $helperPath -Value $helperContent -Encoding UTF8
        Write-SetupMessage "PromptHelper.psm1 créé" -Type "Success"
    }
    catch {
        Write-SetupMessage "Erreur lors de la création de PromptHelper.psm1: $($_.Exception.Message)" -Type "Error"
    }
}

function Show-InstallationSummary {
    param([string]$ProjectPath)
    
    Write-SetupMessage "`n=== RÉSUMÉ DE L'INSTALLATION ===" -Type "Info"
    Write-SetupMessage "Projet installé dans: $ProjectPath" -Type "Success"
    Write-SetupMessage "`nPour commencer:" -Type "Info"
    Write-Host "  cd $ProjectPath" -ForegroundColor Yellow
    Write-Host "  .\Test-UpdatesFaciles.ps1  # Diagnostic" -ForegroundColor Yellow
    Write-Host "  .\main.ps1                 # Lancement" -ForegroundColor Yellow
    
    Write-SetupMessage "`nModules suivants à développer:" -Type "Info"
    $modules = @(
        "Module 2: Interface graphique WPF",
        "Module 3: Détection logicielle", 
        "Module 4: Actions (install/update)",
        "Module 5: Préférences utilisateur",
        "Module 6: Logs & audit"
    )
    
    foreach ($module in $modules) {
        Write-Host "  - $module" -ForegroundColor Gray
    }
}

function Write-PromptLogo {
    $logo = @"
    ╔══════════════════════════════════════╗
    ║           UpdatesFaciles             ║
    ║     Assistant de gestion logiciels   ║
    ║              v1.0.0                  ║
    ╚══════════════════════════════════════╝
"@
    Write-Host $logo -ForegroundColor Cyan
}

# === EXÉCUTION PRINCIPALE ===
try {
    Write-PromptLogo
    Write-SetupMessage "Début de l'installation d'UpdatesFaciles" -Type "Info"
    
    # Vérification des prérequis
    if (-not (Test-Prerequisites)) {
        Write-SetupMessage "Prérequis non satisfaits. Installation interrompue." -Type "Error"
        exit 1
    }
    
    # Résolution du chemin d'installation
    $fullInstallPath = Resolve-Path $InstallPath -ErrorAction SilentlyContinue
    if (-not $fullInstallPath) {
        $fullInstallPath = $InstallPath
    }
    
    # Vérification de l'existence du projet
    if ((Test-Path $fullInstallPath) -and (-not $Force)) {
        Write-SetupMessage "Le dossier $fullInstallPath existe déjà. Utilisez -Force pour écraser." -Type "Warning"
        $response = Read-Host "Continuer quand même? (o/N)"
        if ($response -notmatch "^[oO]") {
            Write-SetupMessage "Installation annulée par l'utilisateur." -Type "Info"
            exit 0
        }
    }
    
    # Création de la structure
    if (-not (New-ProjectStructure -Path $fullInstallPath)) {
        Write-SetupMessage "Erreur lors de la création de la structure. Installation interrompue." -Type "Error"
        exit 1
    }
    
    # Installation des modules
    Install-RequiredModules
    
    # Création du module helper
    New-HelperModule -ProjectPath $fullInstallPath
    
    # Résumé final
    Show-InstallationSummary -ProjectPath $fullInstallPath
    
    Write-SetupMessage "`nInstallation terminée avec succès!" -Type "Success"
}
catch {
    Write-SetupMessage "Erreur fatale: $($_.Exception.Message)" -Type "Error"
    Write-SetupMessage "Stack trace: $($_.ScriptStackTrace)" -Type "Error"
    exit 1
}

