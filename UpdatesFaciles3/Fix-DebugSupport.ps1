# Vérification rapide du support Debug
# Fichier : UpdatesFaciles/Fix-DebugSupport.ps1

$content = Get-Content "App.xaml.ps1" -Raw

Write-Host "🔍 Vérification du support Debug..." -ForegroundColor Cyan

# Test 1: Paramètre Debug
if ($content -match "\[switch\]\$Debug") {
    Write-Host "✅ Paramètre [switch]`$Debug trouvé" -ForegroundColor Green
} else {
    Write-Host "❌ Paramètre [switch]`$Debug manquant" -ForegroundColor Red
}

# Test 2: Utilisation Debug
$debugMatches = [regex]::Matches($content, "if.*\$Debug.*Write-Host", [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
Write-Host "🔍 Nombre d'utilisations Debug trouvées : $($debugMatches.Count)" -ForegroundColor Yellow

if ($debugMatches.Count -gt 0) {
    Write-Host "✅ Support Debug opérationnel" -ForegroundColor Green
    foreach ($match in $debugMatches[0..2]) {  # Afficher les 3 premiers
        $line = $content.Substring(0, $match.Index).Split("`n").Count
        Write-Host "   Ligne ~$line : $($match.Value)" -ForegroundColor Gray
    }
} else {
    Write-Host "❌ Aucune utilisation de Debug trouvée" -ForegroundColor Red
}

# Test alternatif plus permissif
$debugAlternative = [regex]::Matches($content, "\$Debug.*Write-Host.*DEBUG", [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
Write-Host "🔍 Test alternatif Debug : $($debugAlternative.Count) matches" -ForegroundColor Yellow

if ($debugAlternative.Count -gt 0) {
    Write-Host "✅ Support Debug confirmé (regex alternative)" -ForegroundColor Green
} else {
    Write-Host "❌ Support Debug non détecté" -ForegroundColor Red
}