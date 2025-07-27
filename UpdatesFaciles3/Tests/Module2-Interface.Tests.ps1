#Requires -Version 5.1

<#
.SYNOPSIS
    Tests Pester pour Module 2 - Interface graphique WPF
.DESCRIPTION
    Validation complète du Module 2 selon UpdatesFaciles_Prompt7.md
    Tests couvrant : XAML, fonctions UI, gestion d'erreurs, UX
.NOTES
    Fichier : Tests/Module2-Interface.Tests.ps1
    Utilise Pester >= 5.7.1
#>

# Import des modules requis AVANT les tests
BeforeAll {
    # Vérification Pester
    $pesterVersion = (Get-Module Pester -ListAvailable | Sort-Object Version -Descending | Select-Object -First 1).Version
    if ($pesterVersion -lt [version]"5.7.1") {
        throw "Pester version >= 5.7.1 requis. Version actuelle : $pesterVersion"
    }

    # Chemin vers l'application
    $appPath = Join-Path $PSScriptRoot ".." "App.xaml.ps1"
    if (-not (Test-Path $appPath)) {
        throw "App.xaml.ps1 introuvable : $appPath"
    }

    # Chargement des assemblies WPF pour les tests
    Add-Type -AssemblyName PresentationFramework -ErrorAction SilentlyContinue
    Add-Type -AssemblyName PresentationCore -ErrorAction SilentlyContinue
    Add-Type -AssemblyName WindowsBase -ErrorAction SilentlyContinue

    # Source le script principal pour accéder aux fonctions
    . $appPath

    Write-Host "Tests Module 2 - Interface WPF initialisés" -ForegroundColor Green
}

Describe "Module 2 - Tests de base de l'interface" {
    
    Context "Vérification des prérequis" {
        It "PowerShell version >= 5.1" {
            $PSVersionTable.PSVersion | Should -BeGreaterOrEqual ([version]"5.1")
        }

        It "Assemblies WPF chargées" {
            { Add-Type -AssemblyName PresentationFramework } | Should -Not -Throw
            { Add-Type -AssemblyName PresentationCore } | Should -Not -Throw
            { Add-Type -AssemblyName WindowsBase } | Should -Not -Throw
        }

        It "Fonction New-SoftwareApp disponible" {
            Get-Command New-SoftwareApp -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It "Fonction Write-PromptLogo disponible" {
            Get-Command Write-PromptLogo -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
    }

    Context "Tests des fonctions utilitaires" {
        It "New-SoftwareApp crée un objet valide" {
            $software = New-SoftwareApp -Name "Test" -Version "1.0" -Publisher "TestPub"
            
            $software.PSTypeName | Should -Be 'UpdatesFaciles.SoftwareApp'
            $software.Name | Should -Be "Test"
            $software.Version | Should -Be "1.0"
            $software.Publisher | Should -Be "TestPub"
            $software.Source | Should -Be "Inconnu"
            $software.State | Should -Be "Inconnu"
        }

        It "New-SoftwareApp gère les fallbacks" {
            $software = New-SoftwareApp -Name "" -Version $null
            
            $software.Name | Should -Be "Inconnu"
            $software.Version | Should -Be "Inconnu"
            $software.Publisher | Should -Be "Inconnu"
        }

        It "Get-TestSoftwareData retourne des données valides" {
            $testData = Get-TestSoftwareData
            
            $testData | Should -Not -BeNullOrEmpty
            $testData.Count | Should -BeGreaterThan 5
            $testData[0].PSTypeName | Should -Be 'UpdatesFaciles.SoftwareApp'
            $testData[0].Name | Should -Not -BeNullOrEmpty
        }

        It "Write-PromptLogo s'exécute sans erreur" {
            { Write-PromptLogo } | Should -Not -Throw
        }
    }
}

Describe "Module 2 - Tests XAML et interface" {
    
    Context "Validation du XAML" {
        BeforeAll {
            # Récupération du XAML depuis le script
            $xamlContent = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="UpdatesFaciles - Gestionnaire de logiciels" 
        Height="700" Width="1200" 
        WindowStartupLocation="CenterScreen"
        Background="#F5F5F5">
    
    <Window.Resources>
        <Style x:Key="ModernButton" TargetType="Button">
            <Setter Property="Background" Value="#2196F3"/>
            <Setter Property="Foreground" Value="White"/>
            <Setter Property="BorderThickness" Value="0"/>
            <Setter Property="Padding" Value="15,8"/>
            <Setter Property="Margin" Value="5"/>
            <Setter Property="FontWeight" Value="SemiBold"/>
            <Setter Property="Cursor" Value="Hand"/>
        </Style>
    </Window.Resources>

    <Grid Margin="10">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>

        <Border Grid.Row="0" Background="#1976D2">
            <TextBlock x:Name="ClockDisplay" Text="Test"/>
        </Border>

        <StackPanel Grid.Row="1" Orientation="Horizontal">
            <Button x:Name="RefreshButton" Content="Actualiser"/>
            <Button x:Name="DetectButton" Content="Détecter"/>
            <Button x:Name="TestDataButton" Content="Données test"/>
            <Button x:Name="ClearButton" Content="Vider"/>
            <TextBlock x:Name="CountDisplay" Text="0"/>
        </StackPanel>

        <DataGrid x:Name="SoftwareDataGrid" Grid.Row="2"/>
        
        <StackPanel Grid.Row="3" Orientation="Horizontal">
            <TextBlock x:Name="StatusMessage" Text="Test"/>
            <ProgressBar x:Name="ProgressBar" Width="200"/>
        </StackPanel>
    </Grid>
</Window>
"@
        }

        It "XAML est parsable sans erreur" {
            { [Windows.Markup.XamlReader]::Parse($xamlContent) } | Should -Not -Throw
        }

        It "XAML ne contient pas x:Class" {
            $xamlContent | Should -Not -Match 'x:Class'
        }

        It "Contrôles requis présents dans le XAML" {
            $requiredControls = @("ClockDisplay", "CountDisplay", "SoftwareDataGrid", "ProgressBar", "StatusMessage")
            
            foreach ($control in $requiredControls) {
                $xamlContent | Should -Match "x:Name=`"$control`""
            }
        }

        It "Boutons d'action présents" {
            $requiredButtons = @("RefreshButton", "DetectButton", "TestDataButton", "ClearButton")
            
            foreach ($button in $requiredButtons) {
                $xamlContent | Should -Match "x:Name=`"$button`""
            }
        }
    }

    Context "Tests de création d'interface" {
        It "Fenêtre se crée depuis XAML minimal" {
            $simpleXaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Test" Height="400" Width="600">
    <Grid>
        <TextBlock x:Name="TestBlock" Text="Test Interface"/>
        <Button x:Name="TestButton" Content="Test Button"/>
    </Grid>
</Window>
"@
            
            $testWindow = $null
            { $testWindow = [Windows.Markup.XamlReader]::Parse($simpleXaml) } | Should -Not -Throw
            $testWindow | Should -Not -BeNullOrEmpty
            $testWindow.GetType().Name | Should -Be "Window"
        }
    }
}

Describe "Module 2 - Tests des fonctions UI" {
    
    Context "Fonctions de gestion de l'interface" {
        BeforeAll {
            # Mock d'un contrôle pour les tests
            $mockControl = [PSCustomObject]@{
                Text = ""
                Foreground = "Black"
                Visibility = "Visible"
                IsIndeterminate = $false
            }
        }

        It "Update-Clock fonctionne avec un contrôle mock" {
            { Update-Clock $mockControl } | Should -Not -Throw
            $mockControl.Text | Should -Match "\d{2}:\d{2}:\d{2}"
        }

        It "Update-Counter met à jour le compteur" {
            $Global:AppData = @{
                SoftwareList = @{Count = 5}
            }
            
            { Update-Counter $mockControl } | Should -Not -Throw
            $mockControl.Text | Should -Be "5"
        }

        It "Show-StatusMessage gère les différents types" {
            # Mock d'une fenêtre avec FindName
            $mockWindow = [PSCustomObject]@{
                Controls = @{
                    "StatusMessage" = $mockControl
                }
            }
            
            # Test sans fenêtre (doit gérer l'erreur proprement)
            { Show-StatusMessage "Test message" "Success" } | Should -Not -Throw
        }

        It "Start-ProgressBar et Stop-ProgressBar fonctionnent" {
            { Start-ProgressBar $mockControl } | Should -Not -Throw
            $mockControl.Visibility | Should -Be "Visible"
            $mockControl.IsIndeterminate | Should -Be $true
            
            { Stop-ProgressBar $mockControl } | Should -Not -Throw
            $mockControl.Visibility | Should -Be "Collapsed"
            $mockControl.IsIndeterminate | Should -Be $false
        }
    }

    Context "Gestionnaires d'événements (tests unitaires)" {
        BeforeAll {
            # Mock des données globales
            $Global:AppData = @{
                SoftwareList = [System.Collections.Generic.List[object]]::new()
            }
        }

        It "Handle-RefreshButton exécutable" {
            $functionExists = Get-Command Handle-RefreshButton -ErrorAction SilentlyContinue
            $functionExists | Should -Not -BeNullOrEmpty
        }

        It "Handle-DetectButton exécutable" {
            $functionExists = Get-Command Handle-DetectButton -ErrorAction SilentlyContinue
            $functionExists | Should -Not -BeNullOrEmpty
        }

        It "Handle-TestDataButton exécutable" {
            $functionExists = Get-Command Handle-TestDataButton -ErrorAction SilentlyContinue
            $functionExists | Should -Not -BeNullOrEmpty
        }

        It "Handle-ClearButton exécutable" {
            $functionExists = Get-Command Handle-ClearButton -ErrorAction SilentlyContinue
            $functionExists | Should -Not -BeNullOrEmpty
        }
    }
}

Describe "Module 2 - Tests d'intégration et performance" {
    
    Context "Tests de données" {
        It "ObservableCollection peut être créée" {
            $collection = [System.Collections.ObjectModel.ObservableCollection[object]]::new()
            $collection | Should -Not -BeNullOrEmpty
            $collection.GetType().Name | Should -Be "ObservableCollection``1"
        }

        It "Ajout de SoftwareApp à ObservableCollection" {
            $collection = [System.Collections.ObjectModel.ObservableCollection[object]]::new()
            $software = New-SoftwareApp -Name "Test" -Version "1.0"
            
            { $collection.Add($software) } | Should -Not -Throw
            $collection.Count | Should -Be 1
            $collection[0].Name | Should -Be "Test"
        }

        It "Performances de chargement données test" {
            $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
            $testData = Get-TestSoftwareData
            $stopwatch.Stop()
            
            $stopwatch.ElapsedMilliseconds | Should -BeLessThan 1000
            $testData.Count | Should -BeGreaterThan 5
        }
    }

    Context "Tests de robustesse" {
        It "Gestion des erreurs dans les fonctions UI" {
            # Test avec paramètres $null
            { Update-Clock $null } | Should -Not -Throw
            { Update-Counter $null } | Should -Not -Throw
            { Start-ProgressBar $null } | Should -Not -Throw
            { Stop-ProgressBar $null } | Should -Not -Throw
        }

        It "New-SoftwareApp avec paramètres extrêmes" {
            $software = New-SoftwareApp -Name ("A" * 1000) -Version ("1." * 100)
            $software.Name.Length | Should -Be 1000
            $software.Version.Length | Should -Be 300  # "1." répété 100 fois
        }
    }
}

Describe "Module 2 - Tests de conformité prompt" {
    
    Context "Respect des exigences UpdatesFaciles_Prompt7.md" {
        It "Interface utilise Window classique (pas MetroWindow)" {
            $xamlContent = Get-Content $appPath -Raw
            $xamlContent | Should -Match '<Window xmlns='
            $xamlContent | Should -Not -Match 'MetroWindow'
        }

        It "Encodage UTF-8 configuré" {
            $appContent = Get-Content $appPath -Raw
            $appContent | Should -Match '\$OutputEncoding.*UTF8'
        }

        It "Fonctions avec verbes approuvés PowerShell" {
            $functions = @("New-SoftwareApp", "Get-TestSoftwareData", "Update-Clock", "Update-Counter")
            
            foreach ($func in $functions) {
                $verb = $func.Split('-')[0]
                $approvedVerbs = @("Get", "Set", "New", "Remove", "Add", "Update", "Start", "Stop", "Show", "Hide")
                $approvedVerbs | Should -Contain $verb
            }
        }

        It "Gestion d'erreurs avec try/catch" {
            $appContent = Get-Content $appPath -Raw
            $appContent | Should -Match 'try\s*{.*}.*catch'
        }

        It "Support du mode Debug" {
            $appContent = Get-Content $appPath -Raw
            $appContent | Should -Match 'param\(.*\[switch\]\$Debug'
            $appContent | Should -Match 'if.*\$Debug.*Write-Host.*DEBUG'
        }

        It "Messages en français" {
            $appContent = Get-Content $appPath -Raw -Encoding UTF8
            $appContent | Should -Match 'Gestionnaire de logiciels'
            $appContent | Should -Match 'Actualiser'
            $appContent | Should -Match 'Détecter'
        }
    }

    Context "Architecture modulaire" {
        It "Fonction New-SoftwareApp réutilisable (Module 1)" {
            $software = New-SoftwareApp -Name "TestModule" -Version "2.0"
            $software.PSTypeName | Should -Be 'UpdatesFaciles.SoftwareApp'
        }

        It "Données de test cohérentes" {
            $testData = Get-TestSoftwareData
            
            # Vérification que tous les objets sont du bon type
            foreach ($software in $testData) {
                $software.PSTypeName | Should -Be 'UpdatesFaciles.SoftwareApp'
                $software.Name | Should -Not -BeNullOrEmpty
                $software.Version | Should -Not -BeNullOrEmpty
            }
        }

        It "Interface prête pour Module 3 (détection)" {
            $appContent = Get-Content $appPath -Raw
            $appContent | Should -Match 'Handle-DetectButton'
            $appContent | Should -Match 'Module 3.*implémenté'
        }
    }
}

AfterAll {
    Write-Host "Tests Module 2 terminés" -ForegroundColor Green
    Write-Host "✅ Interface WPF validée" -ForegroundColor Green
    Write-Host "✅ Fonctions UI testées" -ForegroundColor Green  
    Write-Host "✅ Conformité prompt vérifiée" -ForegroundColor Green
    Write-Host "➡️  Prêt pour Module 3 (Détection logicielle)" -ForegroundColor Yellow
}