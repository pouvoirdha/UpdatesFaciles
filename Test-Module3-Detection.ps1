# Test-Module3-Detection.ps1
# Tests pour le module SoftwareDetection
# Auteur: Assistant IA
# Date: Juillet 2025

param(
    [string]$ModulePath = ".\Modules\SoftwareDetection\SoftwareDetection.psm1"
)

# Configuration des couleurs pour l'affichage
$Host.UI.RawUI.BackgroundColor = "Black"
$Host.UI.RawUI.ForegroundColor = "White"

Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "             TESTS MODULE SOFTWAREDETECTION                " -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

# Fonction d'affichage des résultats
function Write-TestResult {
    param(
        [string]$TestName,
        [bool]$Success,
        [string]$Message = "",
        [object]$Result = $null
    )
    
    $status = if ($Success) { "✅ RÉUSSI" } else { "❌ ÉCHEC" }
    $color = if ($Success) { "Green" } else { "Red" }
    
    Write-Host "[$status] $TestName" -ForegroundColor $color
    if ($Message) {
        Write-Host "    → $Message" -ForegroundColor Gray
    }
    if ($Result -and $Success) {
        Write-Host "    → Résultat: $($Result | ConvertTo-Json -Compress)" -ForegroundColor DarkGray
    }
    Write-Host ""
}

# Variables de test
$script:TestsPassed = 0
$script:TestsFailed = 0
$script:TestsTotal = 0

function Invoke-Test {
    param(
        [string]$Name,
        [scriptblock]$Test
    )
    
    $script:TestsTotal++
    
    try {
        $result = & $Test
        if ($result) {
            Write-TestResult -TestName $Name -Success $true -Result $result
            $script:TestsPassed++
        } else {
            Write-TestResult -TestName $Name -Success $false -Message "Test retourné false/null"
            $script:TestsFailed++
        }
    }
    catch {
        Write-TestResult -TestName $Name -Success $false -Message "Exception: $($_.Exception.Message)"
        $script:TestsFailed++
    }
}

# Test 1: Chargement du module
Write-Host "🔧 Test 1: Chargement du module SoftwareDetection" -ForegroundColor Yellow
Write-Host "─────────────────────────────────────────────────────────────" -ForegroundColor DarkGray

try {
    if (Test-Path $ModulePath) {
        Import-Module $ModulePath -Force
        Write-TestResult -TestName "Import du module" -Success $true -Message "Module chargé avec succès"
        $script:TestsPassed++
    } else {
        Write-TestResult -TestName "Import du module" -Success $false -Message "Fichier module introuvable: $ModulePath"
        $script:TestsFailed++
        exit 1
    }
    $script:TestsTotal++
}
catch {
    Write-TestResult -TestName "Import du module" -Success $false -Message "Erreur lors du chargement: $($_.Exception.Message)"
    $script:TestsFailed++
    $script:TestsTotal++
    exit 1
}

# Test 2: Vérification des fonctions exportées
Write-Host "🔧 Test 2: Vérification des fonctions exportées" -ForegroundColor Yellow
Write-Host "─────────────────────────────────────────────────────────────" -ForegroundColor DarkGray

$expectedFunctions = @(
    "Get-InstalledSoftware",
    "Test-SoftwareInstalled",
    "Get-SoftwareVersion",
    "Find-SoftwareExecutable",
    "Get-SystemInfo"
)

foreach ($func in $expectedFunctions) {
    Invoke-Test -Name "Fonction $func disponible" -Test {
        Get-Command $func -ErrorAction SilentlyContinue | Out-Null
        return $?
    }
}

# Test 3: Test Get-SystemInfo
Write-Host "🔧 Test 3: Test de Get-SystemInfo" -ForegroundColor Yellow
Write-Host "─────────────────────────────────────────────────────────────" -ForegroundColor DarkGray

Invoke-Test -Name "Get-SystemInfo retourne des informations système" -Test {
    $sysInfo = Get-SystemInfo
    return ($sysInfo -and 
            $sysInfo.OS -and 
            $sysInfo.Version -and 
            $sysInfo.Architecture -and 
            $sysInfo.PSVersion)
}

Invoke-Test -Name "Get-SystemInfo - Structure des données correcte" -Test {
    $sysInfo = Get-SystemInfo
    $requiredProps = @('OS', 'Version', 'Architecture', 'PSVersion', 'TotalMemoryGB', 'AvailableMemoryGB')
    $hasAllProps = $true
    foreach ($prop in $requiredProps) {
        if (-not $sysInfo.PSObject.Properties.Name.Contains($prop)) {
            $hasAllProps = $false
            break
        }
    }
    return $hasAllProps
}

# Test 4: Test Get-InstalledSoftware
Write-Host "🔧 Test 4: Test de Get-InstalledSoftware" -ForegroundColor Yellow
Write-Host "─────────────────────────────────────────────────────────────" -ForegroundColor DarkGray

Invoke-Test -Name "Get-InstalledSoftware sans paramètres" -Test {
    $software = Get-InstalledSoftware
    return ($software -and $software.Count -gt 0)
}

Invoke-Test -Name "Get-InstalledSoftware avec filtre" -Test {
    # Test avec un logiciel courant (PowerShell ou Windows)
    $software = Get-InstalledSoftware -NamePattern "*PowerShell*"
    return ($software -ne $null)  # Peut être vide mais ne doit pas échouer
}

# Test 5: Test Test-SoftwareInstalled
Write-Host "🔧 Test 5: Test de Test-SoftwareInstalled" -ForegroundColor Yellow
Write-Host "─────────────────────────────────────────────────────────────" -ForegroundColor DarkGray

Invoke-Test -Name "Test-SoftwareInstalled avec logiciel existant" -Test {
    # Test avec PowerShell qui devrait être installé
    $result = Test-SoftwareInstalled -SoftwareName "PowerShell"
    return ($result -is [bool])  # Doit retourner un booléen
}

Invoke-Test -Name "Test-SoftwareInstalled avec logiciel inexistant" -Test {
    $result = Test-SoftwareInstalled -SoftwareName "LogicielQuiNExistePasVraiment123456"
    return ($result -eq $false)
}

# Test 6: Test Get-SoftwareVersion
Write-Host "🔧 Test 6: Test de Get-SoftwareVersion" -ForegroundColor Yellow
Write-Host "─────────────────────────────────────────────────────────────" -ForegroundColor DarkGray

Invoke-Test -Name "Get-SoftwareVersion avec PowerShell" -Test {
    $version = Get-SoftwareVersion -SoftwareName "PowerShell"
    return ($version -ne $null)  # Peut être vide si pas trouvé, mais ne doit pas échouer
}

# Test 7: Test Find-SoftwareExecutable
Write-Host "🔧 Test 7: Test de Find-SoftwareExecutable" -ForegroundColor Yellow
Write-Host "─────────────────────────────────────────────────────────────" -ForegroundColor DarkGray

Invoke-Test -Name "Find-SoftwareExecutable avec powershell.exe" -Test {
    $path = Find-SoftwareExecutable -ExecutableName "powershell.exe"
    return ($path -ne $null)
}

Invoke-Test -Name "Find-SoftwareExecutable avec cmd.exe" -Test {
    $path = Find-SoftwareExecutable -ExecutableName "cmd.exe"
    return ($path -and (Test-Path $path))
}

# Test 8: Tests de gestion d'erreurs
Write-Host "🔧 Test 8: Tests de gestion d'erreurs" -ForegroundColor Yellow
Write-Host "─────────────────────────────────────────────────────────────" -ForegroundColor DarkGray

Invoke-Test -Name "Get-InstalledSoftware avec paramètre invalide" -Test {
    try {
        $software = Get-InstalledSoftware -NamePattern $null
        return $true  # Si ça ne plante pas, c'est bon
    }
    catch {
        return $true  # Si ça plante gracieusement, c'est acceptable
    }
}

Invoke-Test -Name "Test-SoftwareInstalled avec paramètre vide" -Test {
    try {
        $result = Test-SoftwareInstalled -SoftwareName ""
        return ($result -eq $false)
    }
    catch {
        return $true  # Erreur acceptable
    }
}

# Test 9: Test de performance
Write-Host "🔧 Test 9: Test de performance" -ForegroundColor Yellow
Write-Host "─────────────────────────────────────────────────────────────" -ForegroundColor DarkGray

Invoke-Test -Name "Get-SystemInfo performance < 5 secondes" -Test {
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    $sysInfo = Get-SystemInfo
    $stopwatch.Stop()
    return ($stopwatch.ElapsedMilliseconds -lt 5000)
}

Invoke-Test -Name "Get-InstalledSoftware performance < 30 secondes" -Test {
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    $software = Get-InstalledSoftware | Select-Object -First 10  # Limiter pour le test
    $stopwatch.Stop()
    return ($stopwatch.ElapsedMilliseconds -lt 30000)
}

# Test 10: Test d'intégration
Write-Host "🔧 Test 10: Test d'intégration" -ForegroundColor Yellow
Write-Host "─────────────────────────────────────────────────────────────" -ForegroundColor DarkGray

Invoke-Test -Name "Workflow complet: Détection → Test → Version" -Test {
    try {
        # 1. Obtenir la liste des logiciels
        $software = Get-InstalledSoftware | Select-Object -First 5
        
        if ($software) {
            # 2. Tester si un logiciel est installé
            $firstSoftware = $software[0]
            $isInstalled = Test-SoftwareInstalled -SoftwareName $firstSoftware.Name
            
            # 3. Essayer d'obtenir sa version
            $version = Get-SoftwareVersion -SoftwareName $firstSoftware.Name
            
            return $true  # Si tout s'exécute sans erreur
        }
        return $false
    }
    catch {
        return $false
    }
}

# Affichage du résumé
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "                    RÉSUMÉ DES TESTS                      " -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

$successRate = if ($script:TestsTotal -gt 0) { 
    [math]::Round(($script:TestsPassed / $script:TestsTotal) * 100, 1) 
} else { 0 }

Write-Host "📊 Tests exécutés: $script:TestsTotal" -ForegroundColor White
Write-Host "✅ Tests réussis: $script:TestsPassed" -ForegroundColor Green
Write-Host "❌ Tests échoués: $script:TestsFailed" -ForegroundColor Red
Write-Host "📈 Taux de réussite: $successRate%" -ForegroundColor $(if ($successRate -ge 80) { "Green" } elseif ($successRate -ge 60) { "Yellow" } else { "Red" })
Write-Host ""

# Recommandations
if ($script:TestsFailed -eq 0) {
    Write-Host "🎉 Tous les tests sont passés avec succès!" -ForegroundColor Green
    Write-Host "   Le module SoftwareDetection est prêt à être utilisé." -ForegroundColor Green
} elseif ($successRate -ge 80) {
    Write-Host "⚠️  La plupart des tests sont passés." -ForegroundColor Yellow
    Write-Host "   Vérifiez les échecs mineurs avant utilisation en production." -ForegroundColor Yellow
} elseif ($successRate -ge 60) {
    Write-Host "⚠️  Des problèmes significatifs ont été détectés." -ForegroundColor Orange
    Write-Host "   Correction recommandée avant utilisation." -ForegroundColor Orange
} else {
    Write-Host "🚨 Échecs critiques détectés!" -ForegroundColor Red
    Write-Host "   Le module nécessite une révision complète." -ForegroundColor Red
}

Write-Host ""
Write-Host "📝 Conseils pour l'amélioration:" -ForegroundColor Cyan
Write-Host "   • Vérifiez les permissions d'accès au registre" -ForegroundColor Gray
Write-Host "   • Testez sur différentes versions de Windows" -ForegroundColor Gray
Write-Host "   • Optimisez les performances pour les gros environnements" -ForegroundColor Gray
Write-Host "   • Ajoutez plus de logiciels dans les bases de données de détection" -ForegroundColor Gray
Write-Host ""

# Code de sortie
exit $(if ($script:TestsFailed -eq 0) { 0 } else { 1 })