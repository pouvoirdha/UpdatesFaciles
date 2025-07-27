Write-Host "🧪 New-SoftwareApp chargé par $($MyInvocation.InvocationName)"

<#
.SYNOPSIS
Représente un logiciel détecté dans UpdatesFaciles

.DESCRIPTION
Structure typée qui encapsule toutes les propriétés utiles pour l’affichage, les actions et le suivi RGPD/audit.

.EXAMPLE
New-SoftwareApp -Name "Firefox" -Version "118.0" -Publisher "Mozilla" -Source "Installé"
#>

function New-SoftwareApp {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$Name,

        [string]$Version = "",
        [string]$Publisher = "Inconnu",
        [string]$Path = "",

        # ✅ Corrigé : accepter "Inconnu" exactement comme valeur valide
        [ValidateSet("Installé", "Portable", "Raccourci", "Cloud", "Inconnu")]
        [string]$Source = "Inconnu",

        [ValidateSet("À jour", "Mise à jour disponible", "Obsolète", "Inconnu")]
        [string]$State = "Inconnu",

        [bool]$CanInstall = $false,
        [bool]$CanUninstall = $false
    )

    # ✅ Protection : fallback si Source ou State sont vides (évite "" dans ValidateSet)
    if ([string]::IsNullOrWhiteSpace($Source)) {
        Write-Warning "⚠️ Source vide → fallback sur 'Inconnu'"
        $Source = "Inconnu"
    }

    if ([string]::IsNullOrWhiteSpace($State)) {
        Write-Warning "⚠️ State vide → fallback sur 'Inconnu'"
        $State = "Inconnu"
    }

    # 🧪 Log d'appel sans Name (utile seulement si Mandatory était désactivé)
    if (-not $Name) {
        Write-Warning "⚠️ Appel à New-SoftwareApp sans Name. Stack :"
        Get-PSCallStack | ForEach-Object { Write-Host "👉 $_" }
    }

    return [PSCustomObject]@{
        Name         = $Name
        Version      = $Version
        Publisher    = $Publisher
        Path         = $Path
        Source       = $Source
        State        = $State
        CanInstall   = $CanInstall
        CanUninstall = $CanUninstall
    }
}

# 🔒 Bloc test manuel – exécution uniquement en console (pas pendant Pester ou import)
if ($Host.Name -like "*ConsoleHost" -and $MyInvocation.ExpectingInput -eq $false) {
    Write-Host "🧪 Exécution directe détectée → test manuel de New-SoftwareApp"
    try {
        $testApp = New-SoftwareApp -Name "TestSoft" -Version "1.0" -Source "Installé"
        $testApp | Format-List
    } catch {
        Write-Warning "⚠️ Erreur lors du test manuel : $_"
    }
}