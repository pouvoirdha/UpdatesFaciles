. "$PSScriptRoot\Models\SoftwareApp.ps1"

# Exemple fictif pour tests UI :
$apps = @(
    New-SoftwareApp -Name "Firefox" -Version "118.0" -Publisher "Mozilla" -Source "Installé",
    New-SoftwareApp -Name "7-Zip" -Version "22.00" -Publisher "Igor Pavlov" -Source "Portable",
    New-SoftwareApp -Name "Notepad++" -Version "8.5.0" -Publisher "Don Ho" -Source "Raccourci"
)