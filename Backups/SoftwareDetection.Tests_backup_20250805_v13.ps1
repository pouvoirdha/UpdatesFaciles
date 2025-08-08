#Requires -Version 5.1
Import-Module Pester
Import-Module P:\Git\UpdatesFaciles\Sources\SoftwareApp.psm1 -Force
Import-Module P:\Git\UpdatesFaciles\Sources\SoftwareDetection.psm1 -Force

Describe "SoftwareDetection Module Tests" {
    BeforeAll {
        # Mock pour Get-ItemProperty (registre, limité à un seul chemin)
        Mock Get-ItemProperty {
            Write-Host "Mock Get-ItemProperty appelé pour Path: $Path"
            return @(
                [PSCustomObject]@{
                    DisplayName = "TestApp"
                    DisplayVersion = "1.0"
                    Publisher = "TestCorp"
                    InstallLocation = "C:\Program Files\TestApp"
                    SystemComponent = 0
                }
            )
        } -ModuleName SoftwareDetection -ParameterFilter { $Path -eq "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*" }

        # Mock par défaut pour Get-ItemProperty
        Mock Get-ItemProperty {
            Write-Host "Mock par défaut Get-ItemProperty appelé pour Path: $Path"
            return @()
        } -ModuleName SoftwareDetection

        # Mock pour Get-ChildItem (portables)
        Mock Get-ChildItem {
            Write-Host "Mock Get-ChildItem (portables) appelé pour Path: $Path"
            return @(
                [PSCustomObject]@{
                    FullName = "D:\Portable\TestApp.exe"
                    Name = "TestApp.exe"
                    BaseName = "TestApp"
                    DirectoryName = "D:\Portable"
                    Extension = ".exe"
                    PSPath = "Microsoft.PowerShell.Core\FileSystem::D:\Portable\TestApp.exe"
                    PSParentPath = "Microsoft.PowerShell.Core\FileSystem::D:\Portable"
                    PSDrive = [PSCustomObject]@{ Name = "D"; Provider = "FileSystem" }
                    PSProvider = [PSCustomObject]@{ Name = "FileSystem" }
                }
            )
        } -ModuleName SoftwareDetection -ParameterFilter { $Path -eq "D:\Portable" }

        # Mock pour Get-ChildItem (raccourcis)
        Mock Get-ChildItem {
            Write-Host "Mock Get-ChildItem (raccourcis) appelé pour Path: $Path"
            return @(
                [PSCustomObject]@{
                    FullName = "C:\Users\Public\Desktop\TestApp.lnk"
                    Name = "TestApp.lnk"
                    BaseName = "TestApp"
                    Extension = ".lnk"
                    PSPath = "Microsoft.PowerShell.Core\FileSystem::C:\Users\Public\Desktop\TestApp.lnk"
                    PSParentPath = "Microsoft.PowerShell.Core\FileSystem::C:\Users\Public\Desktop"
                    PSDrive = [PSCustomObject]@{ Name = "C"; Provider = "FileSystem" }
                    PSProvider = [PSCustomObject]@{ Name = "FileSystem" }
                }
            )
        } -ModuleName SoftwareDetection -ParameterFilter { 
            $Path -in @(
                "C:\ProgramData\Microsoft\Windows\Start Menu\Programs",
                "C:\Users\DERFB\Desktop",
                "C:\Users\DERFB\AppData\Roaming\Microsoft\Windows\Start Menu\Programs"
            )
        }

        # Mock pour WScript.Shell
        Mock New-Object {
            Write-Host "Mock New-Object appelé pour TypeName: $TypeName"
            return [PSCustomObject]@{
                CreateShortcut = {
                    param($Path)
                    Write-Host "Mock CreateShortcut appelé pour Path: $Path"
                    return [PSCustomObject]@{
                        TargetPath = "C:\Program Files\TestApp\TestApp.exe"
                        Arguments = ""
                        Description = "TestApp Shortcut"
                    }
                }
            }
        } -ModuleName SoftwareDetection -ParameterFilter { $TypeName -eq "WScript.Shell" }

        # Mock pour Get-FileVersionSafely
        Mock Get-FileVersionSafely {
            Write-Host "Mock Get-FileVersionSafely appelé pour FilePath: $FilePath"
            return @{
                ProductName = "TestApp"
                ProductVersion = "1.0"
                CompanyName = "TestCorp"
            }
        } -ModuleName SoftwareDetection -ParameterFilter { $FilePath -like "*TestApp.exe" }

        # Mock pour Test-PathSafely
        Mock Test-PathSafely {
            Write-Host "Mock Test-PathSafely appelé pour Path: $Path"
            return $true
        } -ModuleName SoftwareDetection -ParameterFilter { $Path -like "*TestApp*" }

        Mock Test-PathSafely {
            Write-Host "Mock Test-PathSafely appelé pour Path: $Path"
            return $false
        } -ModuleName SoftwareDetection -ParameterFilter { $Path -eq "Z:\Inexistant" }

        # Mock pour New-SoftwareApp
        Mock New-SoftwareApp {
            param(
                [string]$Name,
                [string]$Version,
                [string]$Publisher,
                [string]$Path,
                [string]$Source,
                [string]$State
            )
            Write-Host "Mock New-SoftwareApp appelé pour Name: $Name, Source: $Source"
            return [PSCustomObject]@{
                Name = $Name
                Version = $Version
                Publisher = $Publisher
                Path = $Path
                Source = $Source
                State = $State
            }
        } -ModuleName SoftwareDetection

        # Mock pour Remove-DuplicateSoftware
        Mock Remove-DuplicateSoftware {
            param(
                [Parameter(Mandatory=$false)]
                [AllowNull()]
                [AllowEmptyCollection()]
                [array]$SoftwareList
            )
            Write-Host "Mock Remove-DuplicateSoftware appelé avec SoftwareList: $($SoftwareList | ConvertTo-Json -Depth 2)"
            if ($null -eq $SoftwareList -or $SoftwareList.Length -eq 0) {
                Write-Host "Remove-DuplicateSoftware: Liste vide, retourne @()"
                return @()
            }
            # Simuler un dédoublonnage simple
            $unique = @{}
            foreach ($item in $SoftwareList) {
                if ($item -and $item.Name) {
                    $key = "$($item.Name)-$($item.Version)-$($item.Source)"
                    $unique[$key] = $item
                }
            }
            return $unique.Values
        } -ModuleName SoftwareDetection
    }

    Context "Get-InstalledSoftware" {
        It "Détecte les logiciels du registre sans filtre" {
            $result = Get-InstalledSoftware
            Write-Host "Get-InstalledSoftware résultat: $($result | ConvertTo-Json -Depth 2)"
            $result.Count | Should -Be 1
            $result[0].Name | Should -Be "TestApp"
            $result[0].Version | Should -Be "1.0"
            $result[0].Publisher | Should -Be "TestCorp"
            $result[0].Source | Should -Be "Installé"
            $result[0].State | Should -Be "Inconnu"
        }

        It "Gère les erreurs sans interrompre" {
            Mock Get-ItemProperty { throw "Erreur registre" } -ModuleName SoftwareDetection -ParameterFilter { $Path -like "*Uninstall*" }
            $result = Get-InstalledSoftware
            $result | Should -Be @()
        }
    }

    Context "Get-PortableSoftware" {
        It "Détecte les logiciels portables dans un chemin personnalisé" {
            $result = Get-PortableSoftware -CustomPaths @("D:\Portable")
            $result.Count | Should -Be 1
            $result[0].Name | Should -Be "TestApp"
            $result[0].Version | Should -Be "1.0"
            $result[0].Publisher | Should -Be "TestCorp"
            $result[0].Source | Should -Be "Portable"
            $result[0].State | Should -Be "Inconnu"
        }

        It "Ignore les chemins inexistants" {
            $result = Get-PortableSoftware -CustomPaths @("Z:\Inexistant")
            $result | Should -Be @()
        }
    }

    Context "Get-ShortcutSoftware" {
        It "Détecte les logiciels via raccourcis" {
            $result = Get-ShortcutSoftware
            Write-Host "Get-ShortcutSoftware résultat: $($result | ConvertTo-Json -Depth 2)"
            $result.Count | Should -Be 1
            $result[0].Name | Should -Be "TestApp"
            $result[0].Version | Should -Be "1.0"
            $result[0].Publisher | Should -Be "TestCorp"
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
            Write-Host "Invoke-SoftwareDetection résultat: $($result | ConvertTo-Json -Depth 2)"
            $result.Count | Should -BeGreaterThan 0
            $result | Where-Object { $_.Name -eq "TestApp" } | Should -Not -BeNullOrEmpty
        }

        It "Respecte les options de désactivation" {
            $result = Invoke-SoftwareDetection -IncludeInstalled:$false -IncludePortable:$false -IncludeShortcuts:$false
            $result | Should -Be @()
        }
    }
}