# Généré par Grok le 2025-07-27
# Rôle : Copier un fichier généré dans le dossier pCloud
# Utilisation : Modifiez $content et $destinationPath, exécutez dans PowerShell
$content = @"
# Généré par l’IA
function Get-InstalledSoftware {
    [CmdletBinding()]
    param ()
    try {
        $regPath = "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*"
        $items = Get-ItemProperty -Path $regPath -ErrorAction SilentlyContinue
        $items | ForEach-Object {
            New-SoftwareApp -Name $_.DisplayName -Version $_.DisplayVersion -Publisher $_.Publisher -Source "Registry"
        }
    } catch {
        Write-Error "Erreur de détection : $_"
    }
}
"@
$destinationPath = "P:\UpdatesFaciles\Sources\SoftwareDetection.psm1"
New-Item -Path $destinationPath -ItemType File -Force
$content | Out-File -FilePath $destinationPath -Encoding UTF8
Write-Host "Succès : Fichier copié dans $destinationPath"
Write-Host "Prochaines étapes : Vérifiez dans pCloud et partagez le lien si nécessaire."