<#
.SYNOPSIS
Initialise le projet UpdatesFaciles (structure + modules + dépendances)

.DESCRIPTION
Crée les dossiers, installe les modules requis (Pester, platyPS, etc.), vérifie PowerShell ≥ 7 et .NET ≥ 4.7.2,
copie les DLL MahApps.Metro dans /Libs, et prépare les fichiers essentiels.

.EXAMPLE
.\Setup-UpdatesFaciles.ps1
#>

# 🔎 Vérifie PowerShell ≥ 7.0
$psVersion = $PSVersionTable.PSVersion.Major
if ($psVersion -lt 7) {
    Write-Warning "⚠️ PowerShell v$psVersion détecté – recommande v7.0 ou plus : choco install powershell-core -y"
}

# 🔎 Vérifie .NET ≥ 4.7.2
$dotnetVersion = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full" -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Release
if ($dotnetVersion -lt 461808) {
    Write-Warning "⚠️ .NET 4.7.2 requis – installe via : choco install dotnetfx --version 4.7.2 -y"
}

# 📁 Arborescence principale
$dossiers = @(
    "Sources", "Models", "ViewModels", "Views",
    "Views\Styles", "Actions", "Localization", "Plugins",
    "Tests", "Libs\MahApps.Metro", "Ressources"
)

foreach ($dossier in $dossiers) {
    New-Item -Path ".\$dossier" -ItemType Directory -Force | Out-Null
}

# 📦 Modules à installer
$modules = @(
    "Pester", "platyPS", "ChocolateyGet", "CredentialManager"
)

foreach ($mod in $modules) {
    if (-not (Get-Module -ListAvailable -Name $mod)) {
        try {
            Install-Module -Name $mod -Scope CurrentUser -Force -AllowClobber
            Write-Host "✅ Module $mod installé"
        } catch {
            Write-Warning "⚠️ Impossible d’installer $mod : $_"
        }
    } else {
        Write-Host "✅ Module $mod déjà présent"
    }
}

# 📘 Création des fichiers markdown de base
@(
    "README_UpdatesFaciles.md",
    "GuideContributeur.md",
    "Accueil_UpdatesFaciles.md",
    "Historique_Modules.md"
) | ForEach-Object {
    if (-not (Test-Path $_)) {
        New-Item -Path $_ -ItemType File -Force | Out-Null
        Add-Content $_ "# $($_.Replace('_', ' ').Replace('.md',''))`n`n📦 À compléter…"
        Write-Host "📘 Fichier $_ créé"
    }
}

# 🧬 Fichiers principaux simulés
@(
    "prefs.json", "logs.txt", "audit.log", "main.ps1", "App.xaml.ps1"
) | ForEach-Object {
    if (-not (Test-Path $_)) {
        New-Item $_ -ItemType File -Force | Out-Null
        Write-Host "📁 Fichier $_ prêt"
    }
}

# 🧩 DLL MahApps.Metro
$dlls = @("MahApps.Metro.dll", "ControlzEx.dll")
foreach ($dll in $dlls) {
    $dest = ".\Libs\MahApps.Metro\$dll"
    if (-not (Test-Path $dest)) {
        Write-Warning "⚠️ Copie manuelle nécessaire : placer $dll dans Libs\MahApps.Metro"
    } else {
        Write-Host "✅ DLL $dll détectée"
    }
}

Write-Host "`n📎 Téléchargement MahApps.Metro conseillé :"
Write-Host "🔗 GitHub : https://github.com/MahApps/MahApps.Metro/releases"
Write-Host "Placez MahApps.Metro.dll et ControlzEx.dll dans /Libs/MahApps.Metro"

Write-Host "`n🎯 Setup terminé – structure du projet prête !`n" -ForegroundColor Cyan