Write-Host "📦 Module SoftwareApp.psm1 chargé par $($MyInvocation.InvocationName)"

function New-SoftwareApp {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$Name,

        [string]$Version = "",
        [string]$Publisher = "Inconnu",
        [string]$Path = "",

        [string]$Source = "Inconnu",
        [string]$State  = "Inconnu",

        [bool]$CanInstall = $false,
        [bool]$CanUninstall = $false
    )

    # 🔄 Fallback manuel
    if ([string]::IsNullOrWhiteSpace($Source)) { $Source = "Inconnu" }
    if ([string]::IsNullOrWhiteSpace($State))  { $State  = "Inconnu" }

    # ✅ Validation manuelle
    $validSources = @("Installé", "Portable", "Raccourci", "Cloud", "Inconnu")
    $validStates  = @("À jour", "Mise à jour disponible", "Obsolète", "Inconnu")

    if ($Source -notin $validSources) {
        throw "❌ Source '$Source' invalide. Valeurs autorisées : $($validSources -join ', ')"
    }
    if ($State -notin $validStates) {
        throw "❌ State '$State' invalide. Valeurs autorisées : $($validStates -join ', ')"
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

Export-ModuleMember -Function New-SoftwareApp