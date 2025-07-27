<#
.SYNOPSIS
Diagnostic du projet UpdatesFaciles

.DESCRIPTION
Teste l’environnement complet : dossiers, modules, objets, DLL, tests unitaires.

.EXAMPLE
.\Test-UpdatesFaciles.ps1
#>

Write-Host "`n🧪 Démarrage du test UpdatesFaciles..." -ForegroundColor Cyan

# ✅ Dossiers du projet
$dossiers = @("Sources", "Models", "ViewModels", "Views", "Actions", "Tests", "Plugins", "Libs\MahApps.Metro", "Ressources")
$dossiersOk = 0
foreach ($dossier in $dossiers) {
    if (Test-Path ".\$dossier") {
        Write-Host "📁 $dossier : OK"
        $dossiersOk++
    } else {
        Write-Warning "📁 $dossier : Manquant"
    }
}

# ✅ Modules PowerShell
$modules = @("Pester", "platyPS", "ChocolateyGet", "CredentialManager")
$modulesOk = 0
foreach ($mod in $modules) {
    if (Get-Module -ListAvailable -Name $mod) {
        Write-Host "📦 Module $mod : OK"
        $modulesOk++
    } else {
        Write-Warning "📦 Module $mod : Manquant"
    }
}

# ✅ PackageManagement version bloquée ?
$pkg = Get-Module -ListAvailable -Name PackageManagement
if ($pkg -and $pkg.Version -eq "1.4.8.1") {
    Write-Warning "⚠️ PackageManagement 1.4.8.1 verrouillé – ferme tous les PowerShell avant correction"
} else {
    Write-Host "✅ PackageManagement : Version $($pkg.Version)"
}

# ✅ DLL MahApps.Metro présentes ?
$dlls = @("MahApps.Metro.dll", "ControlzEx.dll")
foreach ($dll in $dlls) {
    if (Test-Path ".\Libs\MahApps.Metro\$dll") {
        Write-Host "🧩 DLL $dll : Présente"
    } else {
        Write-Warning "🧩 DLL manquante : $dll"
    }
}

# ✅ Fonction SoftwareApp
try {
    . ".\Models\SoftwareApp.ps1"
    if (Get-Command -Name New-SoftwareApp -ErrorAction SilentlyContinue) {
        $testApp = New-SoftwareApp -Name "DiagTest"
        if ($testApp.Name -eq "DiagTest") {
            Write-Host "🧩 SoftwareApp.ps1 : Chargé et fonctionnel"
        } else {
            Write-Warning "🧩 SoftwareApp : Création échouée (structure invalide)"
        }
    } else {
        Write-Warning "🧩 Fonction New-SoftwareApp introuvable après chargement"
    }
} catch {
    Write-Warning "❌ Erreur lors du test SoftwareApp : $_"
}

# ✅ Test Pester
Write-Host "`n📣 Lancement des tests unitaires Pester..."
try {
    $result = Invoke-Pester -Path ".\Tests\SoftwareApp.Tests.ps1" -Output Detailed -PassThru
    $ok = $result.PassedCount
    $fail = $result.FailedCount
    Write-Host "`n✅ Tests Pester terminés : $ok OK / $fail erreurs"
} catch {
    Write-Warning "⚠️ Erreur Pester : $_"
}

# ✅ Résumé final
Write-Host "`n🎯 Résumé du test UpdatesFaciles"
Write-Host "📁 Dossiers valides : $dossiersOk / $($dossiers.Count)"
Write-Host "📦 Modules détectés : $modulesOk / $($modules.Count)"
Write-Host "`n✅ Diagnostic terminé." -ForegroundColor Green