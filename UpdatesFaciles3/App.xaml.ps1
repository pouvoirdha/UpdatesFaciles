#Requires -Version 5.1
<#
.SYNOPSIS
    UpdatesFaciles - Interface principale (Version française corrigée)
.DESCRIPTION
    Application WPF pour gestion des logiciels - Module 2
    Corrections appliquées du résumé express :
    - Suppression x:Class du XAML
    - Encodage UTF-8 sans BOM
    - Chargement modules AVANT utilisation
    - Gestion erreurs propre
.PARAMETER Debug
    Active le mode debug avec logs détaillés
.EXAMPLE
    .\App.xaml.ps1 -Debug
#>

param(
    [switch]$Debug
)

# =============================================================================
# INITIALISATION ET MODULES
# =============================================================================

# Définir l'encodage UTF-8 pour la console
$OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# Variables globales
$Global:AppData = @{
    SoftwareList = [System.Collections.ObjectModel.ObservableCollection[object]]::new()
    LastUpdate = Get-Date
    IsLoading = $false
}

# Fonction Write-PromptLogo (définie AVANT utilisation)
function Write-PromptLogo {
    Write-Host @"
╔══════════════════════════════════════════════════════════════════╗
║                          UPDATESFACILES                         ║
║                    Gestionnaire de logiciels                    ║
║                        Version 2.0 - Module 2                   ║
╚══════════════════════════════════════════════════════════════════╝
"@ -ForegroundColor Cyan
}

# Fonction de création d'objet SoftwareApp (Module 1 intégré)
function New-SoftwareApp {
    [CmdletBinding()]
    param(
        [string]$Name = "Inconnu",
        [string]$Version = "Inconnu", 
        [string]$Publisher = "Inconnu",
        [string]$InstallLocation = "Inconnu",
        [string]$Source = "Inconnu",
        [string]$State = "Inconnu"
    )
    
    # Validation avec fallback
    $validSources = @("Installé", "Portable", "Cloud", "Raccourci", "Inconnu")
    $validStates = @("À jour", "Mise à jour disponible", "Obsolète", "Erreur", "Inconnu")
    
    if ($Source -notin $validSources) { $Source = "Inconnu" }
    if ($State -notin $validStates) { $State = "Inconnu" }
    
    return [PSCustomObject]@{
        PSTypeName = 'UpdatesFaciles.SoftwareApp'
        Name = if ([string]::IsNullOrWhiteSpace($Name)) { "Inconnu" } else { $Name }
        Version = if ([string]::IsNullOrWhiteSpace($Version)) { "Inconnu" } else { $Version }
        Publisher = if ([string]::IsNullOrWhiteSpace($Publisher)) { "Inconnu" } else { $Publisher }
        InstallLocation = if ([string]::IsNullOrWhiteSpace($InstallLocation)) { "Inconnu" } else { $InstallLocation }
        Source = $Source
        State = $State
        LastCheck = Get-Date
    }
}

# Fonction de chargement des données de test
function Get-TestSoftwareData {
    return @(
        (New-SoftwareApp -Name "Mozilla Firefox" -Version "118.0.1" -Publisher "Mozilla Foundation" -Source "Installé" -State "À jour" -InstallLocation "C:\Program Files\Mozilla Firefox"),
        (New-SoftwareApp -Name "Google Chrome" -Version "117.0.5938.149" -Publisher "Google LLC" -Source "Installé" -State "Mise à jour disponible" -InstallLocation "C:\Program Files\Google\Chrome"),
        (New-SoftwareApp -Name "7-Zip" -Version "23.01" -Publisher "Igor Pavlov" -Source "Installé" -State "À jour" -InstallLocation "C:\Program Files\7-Zip"),
        (New-SoftwareApp -Name "Notepad++" -Version "8.5.7" -Publisher "Don Ho" -Source "Installé" -State "À jour" -InstallLocation "C:\Program Files\Notepad++"),
        (New-SoftwareApp -Name "VLC Media Player" -Version "3.0.18" -Publisher "VideoLAN" -Source "Installé" -State "Mise à jour disponible" -InstallLocation "C:\Program Files\VideoLAN\VLC"),
        (New-SoftwareApp -Name "WinRAR" -Version "6.23" -Publisher "win.rar GmbH" -Source "Installé" -State "Obsolète" -InstallLocation "C:\Program Files\WinRAR"),
        (New-SoftwareApp -Name "Visual Studio Code" -Version "1.83.1" -Publisher "Microsoft Corporation" -Source "Installé" -State "À jour" -InstallLocation "C:\Users\AppData\Local\Programs\Microsoft VS Code"),
        (New-SoftwareApp -Name "Adobe Reader DC" -Version "2023.006.20360" -Publisher "Adobe Inc." -Source "Installé" -State "Mise à jour disponible" -InstallLocation "C:\Program Files\Adobe\Acrobat DC"),
        (New-SoftwareApp -Name "Paint.NET" -Version "5.0.10" -Publisher "Rick Brewster" -Source "Installé" -State "À jour" -InstallLocation "C:\Program Files\paint.net"),
        (New-SoftwareApp -Name "Spotify" -Version "1.2.22.982" -Publisher "Spotify AB" -Source "Installé" -State "À jour" -InstallLocation "C:\Users\AppData\Roaming\Spotify")
    )
}

# =============================================================================
# DÉFINITION XAML CORRIGÉE
# =============================================================================

$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="UpdatesFaciles - Gestionnaire de logiciels" 
        Height="700" Width="1200" 
        WindowStartupLocation="CenterScreen"
        Background="#F5F5F5">
    
    <Window.Resources>
        <!-- Styles pour les boutons -->
        <Style x:Key="ModernButton" TargetType="Button">
            <Setter Property="Background" Value="#2196F3"/>
            <Setter Property="Foreground" Value="White"/>
            <Setter Property="BorderThickness" Value="0"/>
            <Setter Property="Padding" Value="15,8"/>
            <Setter Property="Margin" Value="5"/>
            <Setter Property="FontWeight" Value="SemiBold"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Style.Triggers>
                <Trigger Property="IsMouseOver" Value="True">
                    <Setter Property="Background" Value="#1976D2"/>
                </Trigger>
            </Style.Triggers>
        </Style>
        
        <!-- Style pour les boutons d'action -->
        <Style x:Key="ActionButton" TargetType="Button" BasedOn="{StaticResource ModernButton}">
            <Setter Property="Background" Value="#4CAF50"/>
            <Style.Triggers>
                <Trigger Property="IsMouseOver" Value="True">
                    <Setter Property="Background" Value="#45A049"/>
                </Trigger>
            </Style.Triggers>
        </Style>
        
        <!-- Style pour le bouton de suppression -->
        <Style x:Key="DeleteButton" TargetType="Button" BasedOn="{StaticResource ModernButton}">
            <Setter Property="Background" Value="#F44336"/>
            <Style.Triggers>
                <Trigger Property="IsMouseOver" Value="True">
                    <Setter Property="Background" Value="#D32F2F"/>
                </Trigger>
            </Style.Triggers>
        </Style>
    </Window.Resources>

    <Grid Margin="10">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>

        <!-- Header -->
        <Border Grid.Row="0" Background="#1976D2" CornerRadius="5" Padding="15" Margin="0,0,0,10">
            <Grid>
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="Auto"/>
                </Grid.ColumnDefinitions>
                
                <StackPanel Grid.Column="0" Orientation="Vertical">
                    <TextBlock Text="UpdatesFaciles" FontSize="24" FontWeight="Bold" Foreground="White"/>
                    <TextBlock Text="Gestionnaire de logiciels - Module 2" FontSize="14" Foreground="#E3F2FD"/>
                </StackPanel>
                
                <StackPanel Grid.Column="1" Orientation="Vertical" HorizontalAlignment="Right">
                    <TextBlock x:Name="ClockDisplay" FontSize="12" Foreground="#E3F2FD" HorizontalAlignment="Right"/>
                    <TextBlock x:Name="StatusDisplay" Text="Prêt" FontSize="12" Foreground="#E3F2FD" HorizontalAlignment="Right"/>
                </StackPanel>
            </Grid>
        </Border>

        <!-- Barre d'outils -->
        <Border Grid.Row="1" Background="White" CornerRadius="5" Padding="10" Margin="0,0,0,10" 
                BorderBrush="#E0E0E0" BorderThickness="1">
            <Grid>
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="Auto"/>
                </Grid.ColumnDefinitions>
                
                <!-- Boutons d'action -->
                <StackPanel Grid.Column="0" Orientation="Horizontal">
                    <Button x:Name="RefreshButton" Content="🔄 Actualiser" Style="{StaticResource ModernButton}"/>
                    <Button x:Name="DetectButton" Content="🔍 Détecter" Style="{StaticResource ActionButton}"/>
                    <Button x:Name="TestDataButton" Content="📊 Données de test" Style="{StaticResource ModernButton}"/>
                    <Button x:Name="ClearButton" Content="🗑️ Vider" Style="{StaticResource DeleteButton}"/>
                </StackPanel>
                
                <!-- Informations -->
                <StackPanel Grid.Column="1" Orientation="Horizontal" VerticalAlignment="Center">
                    <TextBlock Text="Logiciels détectés : " VerticalAlignment="Center" Margin="0,0,5,0"/>
                    <TextBlock x:Name="CountDisplay" Text="0" FontWeight="Bold" VerticalAlignment="Center" 
                               Foreground="#1976D2"/>
                </StackPanel>
            </Grid>
        </Border>

        <!-- Tableau principal -->
        <Border Grid.Row="2" Background="White" CornerRadius="5" BorderBrush="#E0E0E0" BorderThickness="1">
            <DataGrid x:Name="SoftwareDataGrid" 
                      AutoGenerateColumns="False"
                      CanUserAddRows="False"
                      CanUserDeleteRows="False"
                      GridLinesVisibility="Horizontal"
                      HeadersVisibility="Column"
                      SelectionMode="Extended"
                      AlternatingRowBackground="#F9F9F9"
                      RowBackground="White">
                
                <DataGrid.Columns>
                    <DataGridTextColumn Header="Nom" Binding="{Binding Name}" Width="200" IsReadOnly="True"/>
                    <DataGridTextColumn Header="Version" Binding="{Binding Version}" Width="100" IsReadOnly="True"/>
                    <DataGridTextColumn Header="Éditeur" Binding="{Binding Publisher}" Width="150" IsReadOnly="True"/>
                    <DataGridTextColumn Header="Source" Binding="{Binding Source}" Width="100" IsReadOnly="True"/>
                    <DataGridTextColumn Header="État" Binding="{Binding State}" Width="150" IsReadOnly="True"/>
                    <DataGridTextColumn Header="Emplacement" Binding="{Binding InstallLocation}" Width="*" IsReadOnly="True"/>
                </DataGrid.Columns>
            </DataGrid>
        </Border>

        <!-- Barre de statut -->
        <Border Grid.Row="3" Background="#F5F5F5" CornerRadius="5" Padding="10" Margin="0,10,0,0">
            <Grid>
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="Auto"/>
                </Grid.ColumnDefinitions>
                
                <TextBlock x:Name="StatusMessage" Text="Application initialisée - Cliquez sur 'Données de test' pour commencer"
                           VerticalAlignment="Center" FontStyle="Italic" Foreground="#666"/>
                
                <ProgressBar x:Name="ProgressBar" Grid.Column="1" Width="200" Height="20" 
                            Visibility="Collapsed" Margin="10,0,0,0"/>
            </Grid>
        </Border>
    </Grid>
</Window>
"@

# =============================================================================
# FONCTIONS DE L'INTERFACE
# =============================================================================

function Update-Clock {
    param($ClockControl)
    try {
        $ClockControl.Text = (Get-Date).ToString("HH:mm:ss - dd/MM/yyyy")
    }
    catch {
        Write-Warning "Erreur mise à jour horloge : $($_.Exception.Message)"
    }
}

function Update-Counter {
    param($CountControl)
    try {
        $CountControl.Text = $Global:AppData.SoftwareList.Count.ToString()
    }
    catch {
        Write-Warning "Erreur mise à jour compteur : $($_.Exception.Message)"
    }
}

function Show-StatusMessage {
    param(
        [string]$Message,
        [string]$Type = "Info"
    )
    
    try {
        $window.FindName("StatusMessage").Text = "$Message - $(Get-Date -Format 'HH:mm:ss')"
        
        # Couleurs selon le type
        switch ($Type) {
            "Success" { $window.FindName("StatusMessage").Foreground = "Green" }
            "Warning" { $window.FindName("StatusMessage").Foreground = "Orange" }
            "Error" { $window.FindName("StatusMessage").Foreground = "Red" }
            default { $window.FindName("StatusMessage").Foreground = "#666" }
        }
    }
    catch {
        Write-Warning "Erreur affichage message : $($_.Exception.Message)"
    }
}

function Start-ProgressBar {
    param($ProgressControl)
    try {
        $ProgressControl.Visibility = "Visible"
        $ProgressControl.IsIndeterminate = $true
    }
    catch {
        Write-Warning "Erreur démarrage barre de progression : $($_.Exception.Message)"
    }
}

function Stop-ProgressBar {
    param($ProgressControl)
    try {
        $ProgressControl.Visibility = "Collapsed"
        $ProgressControl.IsIndeterminate = $false
    }
    catch {
        Write-Warning "Erreur arrêt barre de progression : $($_.Exception.Message)"
    }
}

# =============================================================================
# GESTIONNAIRES D'ÉVÉNEMENTS
# =============================================================================

function Handle-RefreshButton {
    try {
        Show-StatusMessage "Actualisation en cours..." "Info"
        Start-ProgressBar $window.FindName("ProgressBar")
        
        # Simulation d'actualisation
        Start-Sleep -Milliseconds 500
        
        $window.FindName("SoftwareDataGrid").Items.Refresh()
        Update-Counter $window.FindName("CountDisplay")
        
        Stop-ProgressBar $window.FindName("ProgressBar")
        Show-StatusMessage "Liste actualisée avec succès" "Success"
        
        if ($Debug) {
            Write-Host "[DEBUG] Actualisation terminée - $($Global:AppData.SoftwareList.Count) éléments" -ForegroundColor Green
        }
    }
    catch {
        Stop-ProgressBar $window.FindName("ProgressBar")
        Show-StatusMessage "Erreur lors de l'actualisation" "Error"
        Write-Error "Erreur Handle-RefreshButton : $($_.Exception.Message)"
    }
}

function Handle-DetectButton {
    try {
        Show-StatusMessage "Détection des logiciels en cours..." "Info"
        Start-ProgressBar $window.FindName("ProgressBar")
        
        # Simulation de détection (Module 3 à venir)
        Start-Sleep -Milliseconds 1500
        
        # Pour l'instant, on charge les données de test
        $testData = Get-TestSoftwareData
        $Global:AppData.SoftwareList.Clear()
        
        foreach ($software in $testData) {
            $Global:AppData.SoftwareList.Add($software)
        }
        
        $window.FindName("SoftwareDataGrid").ItemsSource = $Global:AppData.SoftwareList
        Update-Counter $window.FindName("CountDisplay")
        
        Stop-ProgressBar $window.FindName("ProgressBar")
        Show-StatusMessage "Détection terminée - $($Global:AppData.SoftwareList.Count) logiciels trouvés" "Success"
        
        if ($Debug) {
            Write-Host "[DEBUG] Détection simulée - Module 3 sera implémenté prochainement" -ForegroundColor Yellow
        }
    }
    catch {
        Stop-ProgressBar $window.FindName("ProgressBar")
        Show-StatusMessage "Erreur lors de la détection" "Error"
        Write-Error "Erreur Handle-DetectButton : $($_.Exception.Message)"
    }
}

function Handle-TestDataButton {
    try {
        Show-StatusMessage "Chargement des données de test..." "Info"
        Start-ProgressBar $window.FindName("ProgressBar")
        
        $testData = Get-TestSoftwareData
        $Global:AppData.SoftwareList.Clear()
        
        foreach ($software in $testData) {
            $Global:AppData.SoftwareList.Add($software)
        }
        
        $window.FindName("SoftwareDataGrid").ItemsSource = $Global:AppData.SoftwareList
        Update-Counter $window.FindName("CountDisplay")
        
        Stop-ProgressBar $window.FindName("ProgressBar")
        Show-StatusMessage "Données de test chargées avec succès" "Success"
        
        if ($Debug) {
            Write-Host "[DEBUG] $($Global:AppData.SoftwareList.Count) logiciels de test chargés" -ForegroundColor Green
        }
    }
    catch {
        Stop-ProgressBar $window.FindName("ProgressBar")
        Show-StatusMessage "Erreur chargement données de test" "Error"
        Write-Error "Erreur Handle-TestDataButton : $($_.Exception.Message)"
    }
}

function Handle-ClearButton {
    try {
        $result = [System.Windows.MessageBox]::Show(
            "Êtes-vous sûr de vouloir vider la liste ?",
            "Confirmation",
            [System.Windows.MessageBoxButton]::YesNo,
            [System.Windows.MessageBoxImage]::Question
        )
        
        if ($result -eq [System.Windows.MessageBoxResult]::Yes) {
            $Global:AppData.SoftwareList.Clear()
            Update-Counter $window.FindName("CountDisplay")
            Show-StatusMessage "Liste vidée" "Info"
            
            if ($Debug) {
                Write-Host "[DEBUG] Liste vidée par l'utilisateur" -ForegroundColor Yellow
            }
        }
    }
    catch {
        Show-StatusMessage "Erreur lors du vidage" "Error"
        Write-Error "Erreur Handle-ClearButton : $($_.Exception.Message)"
    }
}

# =============================================================================
# INITIALISATION ET LANCEMENT
# =============================================================================

try {
    # Affichage du logo
    Write-PromptLogo
    
    if ($Debug) {
        Write-Host "[DEBUG] Mode debug activé" -ForegroundColor Cyan
        Write-Host "[DEBUG] Chargement de l'interface WPF..." -ForegroundColor Cyan
    }

    # Chargement des assemblies WPF
    Add-Type -AssemblyName PresentationFramework
    Add-Type -AssemblyName PresentationCore
    Add-Type -AssemblyName WindowsBase

    # Création de la fenêtre depuis le XAML
    $window = [Windows.Markup.XamlReader]::Parse($xaml)

    # Vérification des contrôles
    $requiredControls = @("ClockDisplay", "StatusDisplay", "CountDisplay", "SoftwareDataGrid", "ProgressBar", "StatusMessage")
    foreach ($controlName in $requiredControls) {
        $control = $window.FindName($controlName)
        if (-not $control) {
            throw "Contrôle manquant : $controlName"
        }
    }

    # Configuration de la grille de données
    $window.FindName("SoftwareDataGrid").ItemsSource = $Global:AppData.SoftwareList

    # Association des événements
    $window.FindName("RefreshButton").Add_Click({ Handle-RefreshButton })
    $window.FindName("DetectButton").Add_Click({ Handle-DetectButton })
    $window.FindName("TestDataButton").Add_Click({ Handle-TestDataButton })
    $window.FindName("ClearButton").Add_Click({ Handle-ClearButton })

    # Timer pour l'horloge
    $clockTimer = New-Object System.Windows.Threading.DispatcherTimer
    $clockTimer.Interval = [TimeSpan]::FromSeconds(1)
    $clockTimer.Add_Tick({
        Update-Clock $window.FindName("ClockDisplay")
    })
    $clockTimer.Start()

    # Initialisation des affichages
    Update-Clock $window.FindName("ClockDisplay")
    Update-Counter $window.FindName("CountDisplay")
    $window.FindName("StatusDisplay").Text = "Prêt"

    # Gestion de la fermeture
    $window.Add_Closing({
        try {
            $clockTimer.Stop()
            if ($Debug) {
                Write-Host "[DEBUG] Application fermée proprement" -ForegroundColor Green
            }
        }
        catch {
            Write-Warning "Erreur lors de la fermeture : $($_.Exception.Message)"
        }
    })

    if ($Debug) {
        Write-Host "[DEBUG] Interface initialisée avec succès" -ForegroundColor Green
        Write-Host "[DEBUG] Cliquez sur 'Données de test' pour voir des exemples" -ForegroundColor Green
    }

    # Lancement de l'application
    $window.ShowDialog() | Out-Null

}
catch {
    Write-Error "Erreur critique dans l'application : $($_.Exception.Message)"
    Write-Host "Stack trace :" -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor Red
    
    # Tentative d'affichage d'une fenêtre d'erreur simple
    try {
        [System.Windows.MessageBox]::Show(
            "Erreur critique : $($_.Exception.Message)",
            "UpdatesFaciles - Erreur",
            [System.Windows.MessageBoxButton]::OK,
            [System.Windows.MessageBoxImage]::Error
        )
    }
    catch {
        Write-Host "Impossible d'afficher la fenêtre d'erreur" -ForegroundColor Red
    }
}