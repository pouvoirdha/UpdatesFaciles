#Requires -Version 5.1
Import-Module Pester
Import-Module P:\Git\UpdatesFaciles\Sources\SoftwareApp.psm1 -Force
Import-Module P:\Git\UpdatesFaciles\Sources\SoftwareDetection.psm1 -Force

Describe "SoftwareDetection Module Tests" {
    BeforeAll {
        # Mock pour simuler un logiciel dans le registre
        Mock Get-ItemProperty {
            return @(
                [PSCustomObject]@{ DisplayName = "TestApp"; DisplayVersion = "1.0"; Publisher = "TestCorp"; InstallLocation = "C:\Program Files\TestApp"; SystemComponent = 0 }
            )
        } -ModuleName SoftwareDetection -ParameterFilter { $Path -like "*Uninstall\*" }

        # Mock pour simuler un fichier .exe portable
        Mock Get-ChildItem {
            return @(
                [PSCustomObject]@{ FullName = "D:\Portable\TestApp.exe"; BaseName = "TestApp"; DirectoryName = "D:\Portable" }
            )
        } -ModuleName SoftwareDetection -ParameterFilter { $Path -eq "D:\Portable" }

        # Mock pour simuler un raccourci
        Mock Get-ChildItem {
            return @(
                [PSCustomObject]@{ FullName = "C:\Users\Public\Desktop\TestApp.lnk"; BaseName = "TestApp" }
            )
        } -ModuleName SoftwareDetection -ParameterFilter { $Path -like "*Desktop*" }

        Mock New-Object {
            return [PSCustomObject]@{ CreateShortcut = { return [PSCustomObject]@{ TargetPath = "C:\Program Files\TestApp\TestApp.exe" } } }
        } -ModuleName SoftwareDetection -ParameterFilter { $TypeName -eq "WScript.Shell" }

        # Mock pour Get-FileVersionSafely
        Mock Get-FileVersionSafely {
            return @{
                ProductName = "TestApp"
                ProductVersion = "1.0"
                CompanyName = "TestCorp"
            }
        } -ModuleName SoftwareDetection -ParameterFilter { $FilePath -like "*TestApp.exe" }

        # Mock pour New-SoftwareApp pour contrôler les propriétés retournées
        Mock New-SoftwareApp {
            return [PSCustomObject]@{
                Name = $args[1]
                Version = $args[3]
                Publisher = $args[5]
                Path = $args[7]
                Source = $args[9]
                State = $args[11]
            }
        } -ModuleName SoftwareDetection
    }

    Context "Get-InstalledSoftware" {
        It "Détecte les logiciels du registre sans filtre" {
            $result = Get-InstalledSoftware
            $result.Count | Should -BeGreaterThan 0
            $result[0].Name | Should -Be "TestApp"
            $result[0].Source | Should -Be "Installé"
            $result[0].State | Should -Be "Inconnu"
        }

        It "Gère les erreurs sans interrompre" {
            Mock Get-ItemProperty { throw "Erreur registre" } -ModuleName SoftwareDetection -ParameterFilter { $Path -like "*Uninstall\*" }
            $result = Get-InstalledSoftware
            $result | Should -Be @()
        }
    }

    Context "Get-PortableSoftware" {
        It "Détecte les logiciels portables dans un chemin personnalisé" {
            $result = Get-PortableSoftware -CustomPaths @("D:\Portable")
            $result.Count | Should -BeGreaterThan 0
            $result[0].Name | Should -Be "TestApp"
            $result[0].Source | Should -Be "Portable"
            $result[0].State | Should -Be "Inconnu"
        }

        It "Ignore les chemins inexistants" {
            Mock Test-PathSafely { return $false } -ModuleName SoftwareDetection
            $result = Get-PortableSoftware -CustomPaths @("Z:\Inexistant")
            $result | Should -Be @()
        }
    }

    Context "Get-ShortcutSoftware" {
        It "Détecte les logiciels via raccourcis" {
            $result = Get-ShortcutSoftware
            $result.Count | Should -BeGreaterThan 0
            $result[0].Name | Should -Be "TestApp"
            $result[0].Source | Should -Be "Raccourci"
            $result[0].State | Should -Be "Inconnu"
        }

        It "Gère les erreurs de COM sans interrompre" {
            Mock New-Object { throw "Erreur COM" } -ModuleName SoftwareDetection -ParameterFilter { $TypeName -eq "WScript.Shell" }
            $result = Get-ShortcutSoftware
            $result | Should -Be @()
        }
    }

    Context "Invoke-SoftwareDetection" {
        It "Consolide les détections sans erreur" {
            $result = Invoke-SoftwareDetection -IncludeInstalled -IncludePortable -IncludeShortcuts -CustomPortablePaths @("D:\Portable") -DebugMode
            $result.Count | Should -BeGreaterThan 0
            $result | Where-Object { $_.Name -eq "TestApp" } | Should -Not -BeNullOrEmpty
        }

        It "Respecte les options de désactivation" {
            $result = Invoke-SoftwareDetection -IncludeInstalled:$false -IncludePortable:$false -IncludeShortcuts:$false
            $result | Should -Be @()
        }
    }
}