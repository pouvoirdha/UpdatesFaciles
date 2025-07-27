function Test-MahAppsAvailability {
    [OutputType([bool])]
    try {
        $null = [MahApps.Metro.Controls.MetroWindow]
        return $true
    } catch {
        Write-Warning "⚠️ MetroWindow non disponible."
        return $false
    }
}

function Update-PromptNotes {
    param (
        [string]$Message,
        [string]$Module = "Non défini"
    )
    $timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    $entry = "`r`n[$timestamp] [$Module] $Message"
    $notesPath = "$PSScriptRoot\..\Notes_Prompt.md"
    Add-Content -Path $notesPath -Value $entry
}

function Write-PromptLogo {
    @"
 ___       __         _         __        _         
| _ \___ _/ _|___ _ _| |_ ___  / _|___ __| |___ _ _ 
|   / -_)  _/ -_) '_|  _/ _ \|  _/ -_|_-< / -_) '_|
|_|_\___|_| \___|_|  \__\___/|_| \___/__/_\___|_|  

   Module IA : PromptHelper.psm1
   Project : UpdatesFaciles
"@ | Write-Host -ForegroundColor Cyan
}