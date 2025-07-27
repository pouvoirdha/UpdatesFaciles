# PromptHelper.psm1 - Utilitaires pour UpdatesFaciles
function Write-PromptLogo {
    <#
    .SYNOPSIS
        Affiche le logo ASCII d'UpdatesFaciles
    #>
    $logo = @"
    ╔══════════════════════════════════════╗
    ║           UpdatesFaciles             ║
    ║     Assistant de gestion logiciels   ║
    ║              v1.0.0                  ║
    ╚══════════════════════════════════════╝
"@
    Write-Host $logo -ForegroundColor Cyan
}

function Update-PromptNotes {
    <#
    .SYNOPSIS
        Journalise les changements dans le projet
    #>
    param(
        [string]$Message,
        [string]$Module,
        [string]$FilePath = ".\logs.txt"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Module] $Message"
    Add-Content -Path $FilePath -Value $logEntry -Encoding UTF8
}

function Test-MahAppsAvailability {
    <#
    .SYNOPSIS
        Vérifie la disponibilité de MahApps.Metro
    #>
    $mahAppsPath = ".\Libs\MahApps.Metro\MahApps.Metro.dll"
    return (Test-Path $mahAppsPath)
}

Export-ModuleMember -Function Write-PromptLogo, Update-PromptNotes, Test-MahAppsAvailability
