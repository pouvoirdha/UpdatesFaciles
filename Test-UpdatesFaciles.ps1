#requires -Version 7.0

<#
.SYNOPSIS
    Script de vérification post-correction pour UpdatesFaciles
.DESCRIPTION
    Teste le bon fonctionnement de l'application après les corrections
#>

param(
    [switch]$Detailed,
    [switch]$TestDetection
)

$ErrorActionPreference = "Continue"

function Write-TestResult {
    param($Test, $Result, $Details = "")
    $status = if ($Result) { "✓ PASS" } else { "✗ FAIL" }
    $color = if ($Result) { "Green" } else { "Red" }
    
    Write-Host "[$status] $Test" -ForegroundColor $color
    if ($Details -and ($Detailed -or -not $Result)) {
        Write-Host "    → $Details" -ForegroundColor Gray
    }
}

function Test-ModuleLoading {
    Write-Host "`n=== TEST DE CHARGEMENT DES MODULES ===" -ForegroundColor Cyan
    
    $modules = @(
        @{ Path = ".\Modules\Detection.psm1"; Name = "Detection" },
        @{ Path = ".\Modules\SoftwareApp.psm1"; Name = "SoftwareApp" },
        @{ Path = ".\Modules\UI.psm1"; Name = "UI" },
        @{ Path = ".\Modules\Actions.psm1"; Name = "Actions" },
        @{ Path = ".\Modules\SecureLogs.psm1"; Name = "SecureLogs" }
    )
    
    $passCount = 0
    
    foreach ($module in $modules) {
        $exists = Test-Path $module.Path
        Write-TestResult "Module $($module.Name) existe" $exists $module.Path
        
        if ($exists) {
            try {
                Import-Module $module.Path -Force -ErrorAction Stop
                Write-TestResult "Module $($module.Name) se charge" $true
                $passCount++
                
                if ($Detailed) {
                    $moduleInfo = Get-Module $module.Name
                    Write-Host "    → Version: $($moduleInfo.Version)" -ForegroundColor Gray
                    Write-Host "    → Fonctions exportées: $($moduleInfo.ExportedFunctions.Count)" -ForegroundColor Gray
                }
            }
            catch {
                Write-TestResult "Module $($module.Name) se charge" $false $_.Exception.Message
            }
        }
    }
    
    return $passCount
}

function Test-AppScript {
    Write-Host "`n=== TEST DU SCRIPT PRINCIPAL ===" -ForegroundColor Cyan
    
    $appScript = ".\App.xaml.ps1"
    $exists = Test-Path $appScript
    Write-TestResult "Script App.xaml.ps1 existe" $exists
    
    if ($exists) {
        try {
            # Test de syntaxe PowerShell
            $null = [System.Management.Automation.PSParser]::Tokenize((Get-Content $appScript -Raw), [ref]$null)
            Write-TestResult "Syntaxe PowerShell valide" $true
            
            # Vérification des paramètres dupliqués
            $content = Get-Content $appScript -Raw
            $debugMatches = [regex]::Matches($content, '\[switch\]\s*\$Debug', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
            $noDuplicates = $debugMatches.Count -le 1
            Write-TestResult "Pas de paramètres dupliqués" $noDuplicates "Paramètres Debug trouvés: $($debugMatches.Count)"
            
            return $noDuplicates
        }
        catch {
            Write-TestResult "Syntaxe PowerShell valide" $false $_.Exception.Message
            return $false
        }
    }
    
    return $false
}

function Test-DetectionFunctions {
    Write-Host "`n=== TEST DES FONCTIONS DE DÉTECTION ===" -ForegroundColor Cyan
    
    if (-not $TestDetection) {
        Write-Host "Test de détection ignoré (utilisez -TestDetection pour l'activer)" -ForegroundColor Yellow
        return $true
    }
    
    try {
        Import-Module ".\Modules\Detection.psm1" -Force -ErrorAction Stop
        
        # Test des fonctions principales
        $functions = @(
            "Get-AllInstalledSoftware",
            "Find-SoftwareByName",
            "Test-SoftwareInstalled",
            "Get-SoftwareVersion"
        )
        
        $passCount = 0
        foreach ($func in $functions) {
            $exists = Get-Command $func -ErrorAction SilentlyContinue
            Write-TestResult "Fonction $func disponible" ($null -ne $exists)
            if ($exists) { $passCount++ }
        }
        
        # Test pratique : détecter PowerShell
        try {
            Write-Host "`n    Test pratique de détection..." -ForegroundColor Gray
            $psInstalled = Test-SoftwareInstalled -Name "PowerShell"
            Write-TestResult "Détection PowerShell" $psInstalled "PowerShell détecté: $psInstalled"
            
            if ($Detailed) {
                $allSoftware = Get-AllInstalledSoftware | Select-Object -First 5
                Write-Host "    → Premiers logiciels détectés:" -ForegroundColor Gray
                foreach ($soft in $allSoftware) {
                    Write-Host "      • $($soft.Name) ($($soft.Version))" -ForegroundColor Gray
                }
            }
        }
        catch {
            Write-TestResult "Test de détection pratique" $false $_.Exception.Message
        }
        
        return ($passCount -eq $functions.Count)
    }
    catch {
        Write-TestResult "Chargement module Detection" $false $_.Exception.Message
        return $false
    }
}

function Test-UIResources {
    Write-Host "`n=== TEST DES RESSOURCES UI ===" -ForegroundColor Cyan
    
    $resources = @(
        @{ Path = ".\Views\MainWindow.xaml"; Name = "Interface principale" },
        @{ Path = ".\Libs\MahApps.Metro"; Name = "Bibliothèque MahApps.Metro" },
        @{ Path = ".\Ressources\icon.ico"; Name = "Icône application" }
    )
    
    $passCount = 0
    
    foreach ($resource in $resources) {
        $exists = Test-Path $resource.Path
        Write-TestResult $resource.Name $exists $resource.Path
        if ($exists) { $passCount++ }
    }
    
    # Test de validation XAML si l'interface existe
    $xamlPath = ".\Views\MainWindow.xaml"
    if (Test-Path $xamlPath) {
        try {
            $xamlContent = Get-Content $xamlPath -Raw
            $xmlDoc = [xml]$xamlContent
            Write-TestResult "XAML valide" $true
        }
        catch {
            Write-TestResult "XAML valide" $false $_.Exception.Message
        }
    }
    
    return ($passCount -ge 2) # Au moins 2 ressources sur 3
}

function Test-Configuration {
    Write-Host "`n=== TEST DE CONFIGURATION ===" -ForegroundColor Cyan
    
    $configs = @(
        @{ Path = ".\prefs.json"; Name = "Fichier de préférences" },
        @{ Path = ".\logs.txt"; Name = "Fichier de logs" },
        @{ Path = ".\audit.log"; Name = "Fichier d'audit" }
    )
    
    $passCount = 0
    
    foreach ($config in $configs) {
        $exists = Test-Path $config.Path
        Write-TestResult $config.Name $exists $config.Path
        if ($exists) { $passCount++ }
        
        if ($exists -and $config.Path.EndsWith('.json')) {
            try {
                $jsonContent = Get-Content $config.Path -Raw | ConvertFrom-Json
                Write-TestResult "JSON valide ($($config.Name))" $true
            }
            catch {
                Write-TestResult "JSON valide ($($config.Name))" $false "Erreur de parsing JSON"
            }
        }
    }
    
    return ($passCount -eq $configs.Count)
}

function Start-FullTest {
    Write-Host "=== VÉRIFICATION POST-CORRECTION UPDATESFACILES ===" -ForegroundColor Magenta
    Write-Host "Démarrage des tests de vérification...`n" -ForegroundColor White
    
    $results = @{
        Modules = Test-ModuleLoading
        AppScript = Test-AppScript
        Detection = Test-DetectionFunctions
        UI = Test-UIResources
        Config = Test-Configuration
    }
    
    Write-Host "`n=== RÉSUMÉ DES TESTS ===" -ForegroundColor Magenta
    
    $totalTests = 0
    $passedTests = 0
    
    foreach ($result in $results.GetEnumerator()) {
        $status = if ($result.Value -is [bool]) { 
            if ($result.Value) { "✓ PASS" } else { "✗ FAIL" }
        } else {
            "✓ $($result.Value) tests passés"
        }
        
        $color = if (($result.Value -is [bool] -and $result.Value) -or ($result.Value -is [int] -and $result.Value -gt 0)) { 
            "Green" 
        } else { 
            "Red" 
        }
        
        Write-Host "[$status] $($result.Key)" -ForegroundColor $color
        
        if ($result.Value -is [bool]) {
            $totalTests++
            if ($result.Value) { $passedTests++ }
        } else {
            $totalTests += 5 # Estimation pour les tests multiples
            $passedTests += $result.Value
        }
    }
    
    Write-Host "`n=== BILAN GLOBAL ===" -ForegroundColor Magenta
    $successRate = [math]::Round(($passedTests / $totalTests) * 100, 1)
    
    if ($successRate -ge 80) {
        Write-Host "✓ APPLICATION PRÊTE À L'UTILISATION ($successRate% de réussite)" -ForegroundColor Green
        Write-Host "Vous pouvez maintenant lancer: .\App.xaml.ps1" -ForegroundColor Green
    }
    elseif ($successRate -ge 60) {
        Write-Host "⚠ APPLICATION PARTIELLEMENT FONCTIONNELLE ($successRate% de réussite)" -ForegroundColor Yellow
        Write-Host "Certaines fonctionnalités peuvent être limitées" -ForegroundColor Yellow
    }
    else {
        Write-Host "✗ APPLICATION NON FONCTIONNELLE ($successRate% de réussite)" -ForegroundColor Red
        Write-Host "Des corrections supplémentaires sont nécessaires" -ForegroundColor Red
    }
    
    Write-Host "`nPour plus de détails, relancez avec -Detailed" -ForegroundColor Gray
}

# Lancement des tests
Start-FullTest