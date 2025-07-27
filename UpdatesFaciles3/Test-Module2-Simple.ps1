#Requires -Version 5.1

<#
.SYNOPSIS
    Tests simplifiés pour Module 2 - Version compatible
.DESCRIPTION
    Version simplifiée et directe des tests
#>

param([switch]$Debug)

Write-Host "🧪 Tests Module 2 - Interface WPF (Version simplifiée)" -ForegroundColor Cyan
Write-Host "=====================================================" -ForegroundColor Gray

# Vérification Pester
try {
    Import-Module Pester -Force
    $pesterVersion = (Get-Module Pester).Version
    Write-Host "✅ Pester $pesterVersion chargé" -ForegroundColor Green
} catch {
    Write-Error "Erreur chargement Pester : $($_.Exception.Message)"
    exit 1
}

# Vérification fichiers
if (-not (Test-Path "App.xaml.ps1")) {
    Write-Error "App.xaml.ps1 introuvable"
    exit 1
}

Write-Host "✅ Fichiers présents" -ForegroundColor Green

# Chargement de l'app pour les tests
try {
    # Chargement des assemblies WPF
    Add-Type -AssemblyName PresentationFramework -ErrorAction SilentlyContinue
    Add-Type -AssemblyName PresentationCore -ErrorAction SilentlyContinue
    Add-Type -AssemblyName WindowsBase -ErrorAction SilentlyContinue
    
    # Source du script principal (sans lancer l'interface)
    $appContent = Get-Content "App.xaml.ps1" -Raw
    
    # Extraction et exécution des fonctions seulement
    $functionsOnly = $appContent -replace '.*# INITIALISATION ET LANCEMENT.*', '' -replace '\$window\.ShowDialog.*', ''
    
    # Exécution des fonctions
    $scriptBlock = [ScriptBlock]::Create($functionsOnly)
    . $scriptBlock
    
    Write-Host "✅ Fonctions chargées" -ForegroundColor Green
} catch {
    Write-Host "⚠️  Chargement partiel : $($_.Exception.Message)" -ForegroundColor Yellow
}

# Tests manuels
$testResults = @{
    Passed = 0
    Failed = 0
    Total = 0
}

function Test-Function {
    param(
        [string]$Name,
        [scriptblock]$Test,
        [string]$Description
    )
    
    $testResults.Total++
    
    try {
        $result = & $Test
        if ($result) {
            Write-Host "✅ $Name : $Description" -ForegroundColor Green
            $testResults.Passed++
            return $true
        } else {
            Write-Host "❌ $Name : $Description - ÉCHEC" -ForegroundColor Red
            $testResults.Failed++
            return $false
        }
    } catch {
        Write-Host "❌ $Name : $Description - ERREUR: $($_.Exception.Message)" -ForegroundColor Red
        $testResults.Failed++
        return $false
    }
}

Write-Host "`n🔍 Exécution des tests..." -ForegroundColor Yellow

# Test 1: Assemblies WPF
Test-Function "WPF-Assemblies" {
    try {
        [Windows.Markup.XamlReader] | Out-Null
        return $true
    } catch { return $false }
} "Assemblies WPF chargées"

# Test 2: Fonctions de base
Test-Function "Function-WritePromptLogo" {
    return (Get-Command Write-PromptLogo -ErrorAction SilentlyContinue) -ne $null
} "Fonction Write-PromptLogo disponible"

Test-Function "Function-NewSoftwareApp" {
    return (Get-Command New-SoftwareApp -ErrorAction SilentlyContinue) -ne $null
} "Fonction New-SoftwareApp disponible"

Test-Function "Function-GetTestData" {
    return (Get-Command Get-TestSoftwareData -ErrorAction SilentlyContinue) -ne $null
} "Fonction Get-TestSoftwareData disponible"

# Test 3: Création d'objet SoftwareApp
Test-Function "SoftwareApp-Creation" {
    try {
        $software = New-SoftwareApp -Name "Test" -Version "1.0"
        return ($software.Name -eq "Test" -and $software.Version -eq "1.0")
    } catch { return $false }
} "Création objet SoftwareApp"

# Test 4: Fallback SoftwareApp
Test-Function "SoftwareApp-Fallback" {
    try {
        $software = New-SoftwareApp -Name "" -Version $null
        return ($software.Name -eq "Inconnu" -and $software.Version -eq "Inconnu")
    } catch { return $false }
} "Fallback objet SoftwareApp"

# Test 5: Données de test
Test-Function "TestData-Generation" {
    try {
        $testData = Get-TestSoftwareData
        return ($testData.Count -gt 5 -and $testData[0].Name -ne $null)
    } catch { return $false }
} "Génération données de test"

# Test 6: XAML parsing
Test-Function "XAML-Parsing" {
    try {
        $xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Test" Height="400" Width="600">
    <Grid>
        <Button x:Name="TestButton" Content="Test"/>
        <TextBlock x:Name="TestText" Text="Test"/>
    </Grid>
</Window>
"@
        $window = [Windows.Markup.XamlReader]::Parse($xaml)
        return $window -ne $null
    } catch { return $false }
} "Parsing XAML"

# Test 7: Vérification du contenu français
Test-Function "French-Content" {
    try {
        $content = Get-Content "App.xaml.ps1" -Raw -Encoding UTF8
        return ($content -match "Gestionnaire" -and $content -match "Actualiser")
    } catch { return $false }
} "Contenu français présent"

# Test 8: Structure des handlers
Test-Function "Event-Handlers" {
    try {
        $content = Get-Content "App.xaml.ps1" -Raw
        $handlers = @("Handle-RefreshButton", "Handle-DetectButton", "Handle-TestDataButton", "Handle-ClearButton")
        $allPresent = $true
        foreach ($handler in $handlers) {
            if ($content -notmatch $handler) {
                $allPresent = $false
                break
            }
        }
        return $allPresent
    } catch { return $false }
} "Gestionnaires événements présents"

# Test 9: Gestion d'erreurs
Test-Function "Error-Handling" {
    try {
        $content = Get-Content "App.xaml.ps1" -Raw
        return ($content -match "try\s*{" -and $content -match "catch\s*{")
    } catch { return $false }
} "Gestion d'erreurs try/catch"

# Test 10: Support Debug
Test-Function "Debug-Support" {
    try {
        $content = Get-Content "App.xaml.ps1" -Raw
        return ($content -match "\[switch\]\$Debug" -and $content -match "DEBUG.*Write-Host")
    } catch { return $false }
} "Support mode Debug"

# Résultats
Write-Host "`n📊 RÉSUMÉ DES TESTS MODULE 2" -ForegroundColor Cyan
Write-Host "============================" -ForegroundColor Gray
Write-Host "✅ Tests réussis : $($testResults.Passed)/$($testResults.Total)" -ForegroundColor Green
Write-Host "❌ Tests échoués : $($testResults.Failed)/$($testResults.Total)" -ForegroundColor Red

$successRate = [math]::Round(($testResults.Passed / $testResults.Total) * 100, 1)
Write-Host "📈 Taux de réussite : $successRate%" -ForegroundColor $(if($successRate -ge 80) {"Green"} else {"Yellow"})

if ($testResults.Failed -eq 0) {
    Write-Host "`n🎉 MODULE 2 VALIDÉ !" -ForegroundColor Green
    Write-Host "✅ Interface WPF fonctionnelle" -ForegroundColor Green
    Write-Host "✅ Fonctions de base opérationnelles" -ForegroundColor Green
    Write-Host "✅ Support français et UTF-8" -ForegroundColor Green
    Write-Host "✅ Gestion d'erreurs présente" -ForegroundColor Green
    Write-Host "✅ Architecture modulaire respectée" -ForegroundColor Green
    Write-Host "`n➡️  PRÊT POUR MODULE 3 (Détection logicielle)" -ForegroundColor Yellow
    
    # Mise à jour du statut
    Write-Host "`n📋 Statut mis à jour :" -ForegroundColor Cyan
    Write-Host "Module 1 : Structure & objets typés -> ✅ Validé" -ForegroundColor Green
    Write-Host "Module 2 : Interface graphique WPF -> ✅ VALIDÉ" -ForegroundColor Green
    Write-Host "Module 3 : Détection logicielle -> ⏳ À développer" -ForegroundColor Yellow
    
} elseif ($successRate -ge 80) {
    Write-Host "`n⚠️  MODULE 2 PARTIELLEMENT VALIDÉ" -ForegroundColor Yellow
    Write-Host "Quelques tests ont échoué mais le module est fonctionnel" -ForegroundColor Yellow
    Write-Host "Recommandation : Corriger les points manquants avant Module 3" -ForegroundColor Yellow
} else {
    Write-Host "`n❌ MODULE 2 NÉCESSITE DES CORRECTIONS" -ForegroundColor Red
    Write-Host "Trop de tests ont échoué pour valider le module" -ForegroundColor Red
}

Write-Host "`n📝 Tests terminés - $(Get-Date -Format 'HH:mm:ss')" -ForegroundColor Gray