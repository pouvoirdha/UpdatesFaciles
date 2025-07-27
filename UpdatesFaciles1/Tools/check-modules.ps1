$journalPath = "$PSScriptRoot\..\Historique_Modules.md"
$content = Get-Content $journalPath -Raw

$modules = @(
    "Structure",
    "Interface graphique",
    "Détection logicielle",
    "Actions & rollback"
)

Write-Host "`n📊 Suivi de validation des modules :`n" -ForegroundColor Cyan

foreach ($module in $modules) {
    if ($content -match "$module.+✅ Oui") {
        Write-Host "✅ Module '$module' validé" -ForegroundColor Green
    } elseif ($content -match "$module.+❌ Non") {
        Write-Warning "❌ Module '$module' à revoir"
    } else {
        Write-Host "⏳ Module '$module' en attente de validation" -ForegroundColor Yellow
    }
}