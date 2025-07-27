#Requires -Version 5.1

<#
.SYNOPSIS
    Lance les tests Pester pour le Module 2
.DESCRIPTION
    Script de lancement des tests avec vérifications préalables
.NOTES
    Fichier : Run-Module2Tests.ps1
#>

param(
    [switch]$Detailed,
    [switch]$PassThru
)

Write-Host "🧪 Lancement des tests Module 2 - Interface WPF" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Gray

# Vérification de Pester
$pesterModule = Get-Module Pester -ListAvailable | Sort-Object Version -Descending | Select-Object -First 1
if (-not $pesterModule) {
    Write-Error "Pester non installé. Installation : Install-Module Pester -Force"
    exit 1
}

if ($pesterModule.Version -lt [version]"5.7.1") {
    Write-Warning "Pester version $($pesterModule.Version) détectée. Version >= 5.7.1 recommandée."
}

Write-Host "✅ Pester $($pesterModule.Version) détecté" -ForegroundColor Green

# Vérification de la structure
$testPath = "Tests/Module2-Interface.Tests.ps1"
if (-not (Test-Path $testPath)) {
    Write-Error "Fichier de tests introuvable : $testPath"
    exit 1
}

$appPath = "App.xaml.ps1"
if (-not (Test-Path $appPath)) {
    Write-Error "Application introuvable : $appPath"
    exit 1
}

Write-Host "✅ Fichiers requis présents" -ForegroundColor Green

# Import Pester (nécessaire pour certaines versions)
Import-Module Pester -Force

# Lancement des tests
try {
    Write-Host "🚀 Exécution des tests..." -ForegroundColor Yellow
    
    # Configuration simplifiée compatible
    $pesterParams = @{
        Path = $testPath  
        PassThru = $true
    }
    
    if ($Detailed) {
        $pesterParams.Verbose = $true
    }
    
    $result = Invoke-Pester @pesterParams
    
    # Résumé
    Write-Host "`n📊 RÉSUMÉ DES TESTS MODULE 2" -ForegroundColor Cyan
    Write-Host "============================" -ForegroundColor Gray
    Write-Host "✅ Tests réussis    : $($result.PassedCount)" -ForegroundColor Green
    Write-Host "❌ Tests échoués    : $($result.FailedCount)" -ForegroundColor Red
    Write-Host "⏭️  Tests ignorés    : $($result.SkippedCount)" -ForegroundColor Yellow
    Write-Host "⏱️  Durée totale    : $([math]::Round($result.Duration.TotalSeconds, 2))s" -ForegroundColor Gray
    
    if ($result.FailedCount -eq 0) {
        Write-Host "`n🎉 MODULE 2 VALIDÉ !" -ForegroundColor Green
        Write-Host "➡️  Prêt pour le Module 3 (Détection logicielle)" -ForegroundColor Yellow
        
        # Mise à jour du statut dans le prompt (simulation)
        Write-Host "`n📋 Mise à jour du statut :" -ForegroundColor Cyan
        Write-Host "Module 2 : Interface graphique WPF -> ✅ VALIDÉ" -ForegroundColor Green
    } else {
        Write-Host "`n⚠️  TESTS ÉCHOUÉS - Vérifiez les erreurs ci-dessus" -ForegroundColor Red
        Write-Host "Module 2 nécessite des corrections avant validation" -ForegroundColor Yellow
    }
    
    if ($PassThru) {
        return $result
    }
    
} catch {
    Write-Error "Erreur lors de l'exécution des tests : $($_.Exception.Message)"
    Write-Host $_.ScriptStackTrace -ForegroundColor Red
    exit 1
}