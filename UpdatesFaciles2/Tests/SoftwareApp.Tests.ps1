

Import-Module "$PSScriptRoot\..\Modules\SoftwareApp\SoftwareApp.psm1" -Force

Write-Host "🧪 Fichier SoftwareApp.Tests.ps1 chargé jusqu'ici"

# Charger le script cible
. "$PSScriptRoot\..\Models\SoftwareApp.ps1"

Write-Host "➡️ Début execution SoftwareApp.Tests.ps1"
Write-Host "🧪 Début des tests"

# 👇 Déclarer les jeux de données EN DEHORS du bloc Describe
$sources = @("Installé", "Portable", "Raccourci", "Cloud", "Inconnu")
$states  = @("À jour", "Mise à jour disponible", "Obsolète", "Inconnu")

Describe "New-SoftwareApp" {

    It "should create a valid SoftwareApp with full parameters" {
        $app = New-SoftwareApp -Name "TestApp" -Version "1.0" -Publisher "CopilotSoft" -Path "C:\TestApp" `
            -Source "Portable" -State "À jour" -CanInstall $true -CanUninstall $true

        $app.Name        | Should -Be "TestApp"
        $app.Source      | Should -Be "Portable"
        $app.State       | Should -Be "À jour"
        $app.CanInstall  | Should -BeTrue
        $app.CanUninstall| Should -BeTrue
    }

    It "should fallback to default Source and State when omitted" {
        $app = New-SoftwareApp -Name "FallbackApp"
        $app.Source | Should -Be "Inconnu"
        $app.State  | Should -Be "Inconnu"
    }

    It "should fallback to 'Inconnu' when empty strings are passed" {
        $app = New-SoftwareApp -Name "EmptyApp" -Source "" -State ""
        $app.Source | Should -Be "Inconnu"
        $app.State  | Should -Be "Inconnu"
    }

    It "should throw when Source is invalid" {
        { New-SoftwareApp -Name "InvalidApp" -Source "LogicielInexistant" } | Should -Throw
    }

    It "should throw when State is invalid" {
        { New-SoftwareApp -Name "InvalidApp2" -State "ÉtatImpossible" } | Should -Throw
    }

}