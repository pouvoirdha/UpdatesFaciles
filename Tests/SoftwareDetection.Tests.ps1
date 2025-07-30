# Généré par Grok le 2025-07-28
# Rôle : Tests unitaires pour SoftwareDetection.psm1 (Module 3)
# Chemin : P:\Git\UpdatesFaciles\Tests\SoftwareDetection.Tests.ps1
# Respecte UpdatesFaciles_Prompt7.txt : tests automatisés, silencieux, reproductibles

Describe "Get-InstalledSoftware" {
    BeforeAll {
        Import-Module P:\Git\UpdatesFaciles\Sources\SoftwareDetection.psm1 -Force
        # Simuler New-SoftwareApp
        function New-SoftwareApp {
            param ($Name, $Version, $Publisher, $Source, $InstallLocation, $UninstallString, $CanInstall, $CanUninstall)
            [PSCustomObject]@{
                Name = $Name
                Version = $Version
                Publisher = $Publisher
                Source = $Source
                InstallLocation = $InstallLocation
                UninstallString = $UninstallString
                CanInstall = $CanInstall
                CanUninstall = $CanUninstall
            }
        }
    }

    It "Détecte les logiciels du registre sans filtre" {
        $result = Get-InstalledSoftware -Source Registry
        $result | Should -Not -BeNullOrEmpty
        $result | ForEach-Object {
            $_ | Should -BeOfType PSCustomObject
            $_.Source | Should -Be "Registry"
        }
    }

    It "Filtre les logiciels par nom" {
        $result = Get-InstalledSoftware -Filter "Microsoft" -Source Registry
        $result | ForEach-Object {
            $_.Name | Should -Match "Microsoft"
        }
    }

    It "Détecte les logiciels portables" {
        $result = Get-InstalledSoftware -Source Portable -PortablePaths "$env:TEMP"
        $result | ForEach-Object {
            $_.Source | Should -Be "Portable"
            $_.CanInstall | Should -Be $false
            $_.CanUninstall | Should -Be $false
        }
    }

    It "Gère les erreurs sans interrompre" {
        $result = Get-InstalledSoftware -Source Registry -ErrorAction SilentlyContinue
        $result | Should -Not -BeNull
    }
}