#requires -Version 7.0

<#
.SYNOPSIS
    Correction des références WPF dans App.xaml.ps1
.DESCRIPTION
    Corrige les problèmes de chargement des assemblies WPF
#>

# Fonction pour corriger le fichier App.xaml.ps1
function Fix-WPFReferences {
    $appScriptPath = ".\App.xaml.ps1"
    
    if (-not (Test-Path $appScriptPath)) {
        Write-Host "Fichier App.xaml.ps1 non trouvé!" -ForegroundColor Red
        return $false
    }
    
    Write-Host "Correction des références WPF..." -ForegroundColor Yellow
    
    try {
        $content = Get-Content $appScriptPath -Raw
        
        # Nouveau contenu avec les bonnes références WPF
        $correctedContent = $content -replace 'Add-Type -TypeDefinition @"[\s\S]*?"@', @'
# Chargement des assemblies WPF nécessaires
Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore  
Add-Type -AssemblyName WindowsBase
Add-Type -AssemblyName System.Xaml

# Vérification que les assemblies sont chargées
$wpfAssemblies = @(
    'PresentationFramework',
    'PresentationCore', 
    'WindowsBase',
    'System.Xaml'
)

foreach ($assembly in $wpfAssemblies) {
    try {
        [System.Reflection.Assembly]::LoadWithPartialName($assembly) | Out-Null
        if ($Debug) { Write-Host "✓ Assembly $assembly chargé" -ForegroundColor Green }
    }
    catch {
        Write-Host "✗ Erreur lors du chargement de $assembly : $_" -ForegroundColor Red
        exit 1
    }
}
'@
        
        # Sauvegarder une copie de sauvegarde
        Copy-Item $appScriptPath "$appScriptPath.backup" -Force
        
        # Écrire le contenu corrigé
        Set-Content -Path $appScriptPath -Value $correctedContent -Encoding UTF8
        
        Write-Host "✓ Références WPF corrigées avec succès" -ForegroundColor Green
        Write-Host "✓ Sauvegarde créée: App.xaml.ps1.backup" -ForegroundColor Green
        
        return $true
    }
    catch {
        Write-Host "✗ Erreur lors de la correction: $_" -ForegroundColor Red
        return $false
    }
}

# Version alternative du script App.xaml.ps1 complet et corrigé
function Create-CorrectedAppScript {
    $appScriptPath = ".\App.xaml.ps1"
    
    # Sauvegarder l'ancien fichier
    if (Test-Path $appScriptPath) {
        Copy-Item $appScriptPath "$appScriptPath.old" -Force
        Write-Host "✓ Ancien script sauvegardé: App.xaml.ps1.old" -ForegroundColor Green
    }
    
    $correctedScript = @'
#requires -Version 7.0

<#
.SYNOPSIS
    UpdatesFaciles - Assistant de gestion des logiciels
.DESCRIPTION
    Interface graphique WPF pour la gestion et la mise à jour des logiciels installés
.VERSION
    1.0.0
.AUTHOR
    UpdatesFaciles Team
#>

param(
    [switch]$Debug,
    [switch]$NoLogo,
    [string]$LogPath = ".\logs.txt"
)

$ErrorActionPreference = "Stop"

# Affichage du logo si demandé
if (-not $NoLogo) {
    Clear-Host
    Write-Host "    ╔══════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "    ║           UpdatesFaciles             ║" -ForegroundColor Cyan  
    Write-Host "    ║     Assistant de gestion logiciels   ║" -ForegroundColor Cyan
    Write-Host "    ║              v1.0.0                  ║" -ForegroundColor Cyan
    Write-Host "    ╚══════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
}

# Fonction de logging
function Write-Log {
    param(
        [Parameter(Mandatory)]
        [string]$Message,
        [ValidateSet('INFO', 'WARNING', 'ERROR', 'DEBUG')]
        [string]$Level = 'INFO'
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    
    if ($Debug -or $Level -ne 'DEBUG') {
        $color = switch ($Level) {
            'INFO' { 'White' }
            'WARNING' { 'Yellow' }
            'ERROR' { 'Red' }
            'DEBUG' { 'Gray' }
        }
        Write-Host $logEntry -ForegroundColor $color
    }
    
    try {
        Add-Content -Path $LogPath -Value $logEntry -Encoding UTF8 -ErrorAction SilentlyContinue
    }
    catch {
        # Ignore les erreurs de log pour éviter les blocages
    }
}

# Chargement des assemblies WPF
Write-Log "Chargement des assemblies WPF..." -Level DEBUG

try {
    Add-Type -AssemblyName PresentationFramework
    Add-Type -AssemblyName PresentationCore  
    Add-Type -AssemblyName WindowsBase
    Add-Type -AssemblyName System.Xaml
    
    Write-Log "✓ Assemblies WPF chargées avec succès" -Level DEBUG
}
catch {
    Write-Log "✗ Erreur lors du chargement des assemblies WPF: $_" -Level ERROR
    exit 1
}

# Chargement des modules
Write-Log "Chargement des modules UpdatesFaciles..." -Level DEBUG

$modules = @(
    ".\Modules\Detection.psm1"
)

foreach ($module in $modules) {
    if (Test-Path $module) {
        try {
            Import-Module $module -Force -ErrorAction Stop
            Write-Log "✓ Module $module chargé" -Level DEBUG
        }
        catch {
            Write-Log "⚠ Erreur lors du chargement de $module : $_" -Level WARNING
        }
    }
    else {
        Write-Log "⚠ Module $module non trouvé" -Level WARNING
    }
}

# Définition de l'interface XAML
$xaml = @'
<Window x:Class="UpdatesFaciles.MainWindow"
        xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="UpdatesFaciles - Assistant de gestion logiciels" 
        Height="700" Width="1000"
        WindowStartupLocation="CenterScreen"
        MinHeight="500" MinWidth="800">
    
    <Window.Resources>
        <Style x:Key="ModernButtonStyle" TargetType="Button">
            <Setter Property="Background" Value="#3498db"/>
            <Setter Property="Foreground" Value="White"/>
            <Setter Property="BorderThickness" Value="0"/>
            <Setter Property="Padding" Value="15,8"/>
            <Setter Property="Margin" Value="5"/>
            <Setter Property="FontWeight" Value="SemiBold"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Style.Triggers>
                <Trigger Property="IsMouseOver" Value="True">
                    <Setter Property="Background" Value="#2980b9"/>
                </Trigger>
                <Trigger Property="IsPressed" Value="True">
                    <Setter Property="Background" Value="#1f618d"/>
                </Trigger>
            </Style.Triggers>
        </Style>
        
        <Style x:Key="HeaderStyle" TargetType="TextBlock">
            <Setter Property="FontSize" Value="18"/>
            <Setter Property="FontWeight" Value="Bold"/>
            <Setter Property="Foreground" Value="#2c3e50"/>
            <Setter Property="Margin" Value="0,0,0,15"/>
        </Style>
    </Window.Resources>
    
    <Grid>
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>
        
        <!-- Header -->
        <Border Grid.Row="0" Background="#34495e" Padding="20,15">
            <Grid>
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="Auto"/>
                </Grid.ColumnDefinitions>
                
                <StackPanel Grid.Column="0" Orientation="Horizontal">
                    <TextBlock Text="🔧" FontSize="24" Margin="0,0,10,0" VerticalAlignment="Center"/>
                    <TextBlock Text="UpdatesFaciles" FontSize="24" FontWeight="Bold" 
                              Foreground="White" VerticalAlignment="Center"/>
                    <TextBlock Text="v1.0.0" FontSize="12" Foreground="#bdc3c7" 
                              Margin="10,0,0,0" VerticalAlignment="Bottom"/>
                </StackPanel>
                
                <StackPanel Grid.Column="1" Orientation="Horizontal">
                    <Button Name="btnRefreshAll" Content="🔄 Actualiser" 
                           Style="{StaticResource ModernButtonStyle}" Background="#27ae60"/>
                    <Button Name="btnSettings" Content="⚙️ Paramètres" 
                           Style="{StaticResource ModernButtonStyle}" Background="#95a5a6"/>
                </StackPanel>
            </Grid>
        </Border>
        
        <!-- Main Content -->
        <TabControl Grid.Row="1" Margin="10" Name="mainTabControl">
            <!-- Onglet Logiciels installés -->
            <TabItem Header="📦 Logiciels installés">
                <Grid>
                    <Grid.RowDefinitions>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="*"/>
                    </Grid.RowDefinitions>
                    
                    <!-- Titre et statistiques -->
                    <StackPanel Grid.Row="0" Margin="10">
                        <TextBlock Text="Logiciels installés sur votre système" 
                                  Style="{StaticResource HeaderStyle}"/>
                        <TextBlock Name="txtSoftwareStats" Text="Chargement..." 
                                  FontStyle="Italic" Foreground="#7f8c8d"/>
                    </StackPanel>
                    
                    <!-- Barre d'outils -->
                    <StackPanel Grid.Row="1" Orientation="Horizontal" Margin="10,0,10,10">
                        <Button Name="btnDetectSoftware" Content="🔍 Détecter" 
                               Style="{StaticResource ModernButtonStyle}"/>
                        <Button Name="btnCheckUpdates" Content="⬆️ Vérifier les mises à jour" 
                               Style="{StaticResource ModernButtonStyle}" Background="#e67e22"/>
                        <Button Name="btnExportList" Content="💾 Exporter" 
                               Style="{StaticResource ModernButtonStyle}" Background="#8e44ad"/>
                        
                        <!-- Barre de recherche -->
                        <TextBox Name="txtSearch" Width="200" Height="30" Margin="20,5,5,5"
                                VerticalContentAlignment="Center" 
                                Text="Rechercher un logiciel..."/>
                        <Button Name="btnSearch" Content="🔍" 
                               Style="{StaticResource ModernButtonStyle}" Background="#16a085"/>
                    </StackPanel>
                    
                    <!-- Liste des logiciels -->
                    <DataGrid Grid.Row="2" Name="dgSoftware" 
                             AutoGenerateColumns="False" 
                             CanUserAddRows="False" 
                             CanUserDeleteRows="False"
                             CanUserResizeRows="False"
                             GridLinesVisibility="Horizontal"
                             AlternatingRowBackground="#f8f9fa"
                             Margin="10">
                        <DataGrid.Columns>
                            <DataGridTextColumn Header="Nom" Binding="{Binding Name}" Width="*" MinWidth="200"/>
                            <DataGridTextColumn Header="Version" Binding="{Binding Version}" Width="120"/>
                            <DataGridTextColumn Header="Éditeur" Binding="{Binding Publisher}" Width="150"/>
                            <DataGridTextColumn Header="Source" Binding="{Binding Source}" Width="100"/>
                            <DataGridTextColumn Header="Architecture" Binding="{Binding Architecture}" Width="80"/>
                        </DataGrid.Columns>
                    </DataGrid>
                </Grid>
            </TabItem>
            
            <!-- Onglet Actions -->
            <TabItem Header="⚡ Actions">
                <ScrollViewer Margin="10">
                    <StackPanel>
                        <TextBlock Text="Actions disponibles" Style="{StaticResource HeaderStyle}"/>
                        
                        <!-- Gestionnaires de paquets -->
                        <GroupBox Header="Gestionnaires de paquets" Margin="0,10,0,20" Padding="15">
                            <StackPanel>
                                <Button Name="btnInstallChocolatey" Content="📦 Installer Chocolatey" 
                                       Style="{StaticResource ModernButtonStyle}" 
                                       HorizontalAlignment="Left" Background="#d35400"/>
                                <Button Name="btnInstallWinget" Content="🏪 Installer Winget" 
                                       Style="{StaticResource ModernButtonStyle}" 
                                       HorizontalAlignment="Left" Background="#2ecc71"/>
                                <Button Name="btnUpdatePackages" Content="⬆️ Mettre à jour tous les paquets" 
                                       Style="{StaticResource ModernButtonStyle}" 
                                       HorizontalAlignment="Left" Background="#e74c3c"/>
                            </StackPanel>
                        </GroupBox>
                        
                        <!-- Outils système -->
                        <GroupBox Header="Outils système" Margin="0,0,0,20" Padding="15">
                            <StackPanel>
                                <Button Name="btnSystemInfo" Content="ℹ️ Informations système" 
                                       Style="{StaticResource ModernButtonStyle}" 
                                       HorizontalAlignment="Left" Background="#34495e"/>
                                <Button Name="btnCleanTemp" Content="🧹 Nettoyer les fichiers temporaires" 
                                       Style="{StaticResource ModernButtonStyle}" 
                                       HorizontalAlignment="Left" Background="#f39c12"/>
                                <Button Name="btnRegistryCheck" Content="🔧 Vérifier le registre" 
                                       Style="{StaticResource ModernButtonStyle}" 
                                       HorizontalAlignment="Left" Background="#9b59b6"/>
                            </StackPanel>
                        </GroupBox>
                    </StackPanel>
                </ScrollViewer>
            </TabItem>
            
            <!-- Onglet Logs -->
            <TabItem Header="📋 Logs">
                <Grid Margin="10">
                    <Grid.RowDefinitions>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="*"/>
                        <RowDefinition Height="Auto"/>
                    </Grid.RowDefinitions>
                    
                    <TextBlock Grid.Row="0" Text="Journal d'activité" Style="{StaticResource HeaderStyle}"/>
                    
                    <TextBox Grid.Row="1" Name="txtLogs" 
                            IsReadOnly="True" 
                            VerticalScrollBarVisibility="Auto"
                            HorizontalScrollBarVisibility="Auto"
                            FontFamily="Consolas"
                            FontSize="11"
                            Background="#2c3e50"
                            Foreground="#ecf0f1"
                            Padding="10"/>
                    
                    <StackPanel Grid.Row="2" Orientation="Horizontal" Margin="0,10,0,0">
                        <Button Name="btnClearLogs" Content="🗑️ Effacer" 
                               Style="{StaticResource ModernButtonStyle}" Background="#e74c3c"/>
                        <Button Name="btnSaveLogs" Content="💾 Sauvegarder" 
                               Style="{StaticResource ModernButtonStyle}" Background="#27ae60"/>
                        <Button Name="btnRefreshLogs" Content="🔄 Actualiser" 
                               Style="{StaticResource ModernButtonStyle}"/>
                    </StackPanel>
                </Grid>
            </TabItem>
        </TabControl>
        
        <!-- Status Bar -->
        <StatusBar Grid.Row="2" Background="#ecf0f1" Height="30">
            <StatusBarItem>
                <TextBlock Name="txtStatus" Text="Prêt" FontWeight="SemiBold"/>
            </StatusBarItem>
            <Separator/>
            <StatusBarItem>
                <TextBlock Name="txtDateTime" Text=""/>
            </StatusBarItem>
            <StatusBarItem HorizontalAlignment="Right">
                <ProgressBar Name="progressBar" Width="200" Height="15" Visibility="Collapsed"/>
            </StatusBarItem>
        </StatusBar>
    </Grid>
</Window>
'@

# Conversion XAML vers objet WPF
Write-Log "Chargement de l'interface graphique..." -Level DEBUG

try {
    [xml]$xamlDoc = $xaml
    $reader = New-Object System.Xml.XmlNodeReader $xamlDoc
    $window = [Windows.Markup.XamlReader]::Load($reader)
    
    Write-Log "✓ Interface XAML chargée avec succès" -Level DEBUG
}
catch {
    Write-Log "✗ Erreur lors du chargement XAML: $_" -Level ERROR
    exit 1
}

# Récupération des contrôles
$controls = @{}
$xamlDoc.SelectNodes("//*[@Name]") | ForEach-Object {
    $controls[$_.Name] = $window.FindName($_.Name)
}

Write-Log "✓ $($controls.Count) contrôles trouvés" -Level DEBUG

# Fonction pour mettre à jour le statut
function Update-Status {
    param([string]$Message)
    if ($controls.txtStatus) {
        $controls.txtStatus.Text = $Message
        Write-Log $Message -Level INFO
    }
}

# Fonction pour charger les logiciels
function Load-SoftwareList {
    Update-Status "Détection des logiciels en cours..."
    
    try {
        if (Get-Command Get-AllInstalledSoftware -ErrorAction SilentlyContinue) {
            $software = Get-AllInstalledSoftware -UseCache
            $controls.dgSoftware.ItemsSource = $software
            $controls.txtSoftwareStats.Text = "$($software.Count) logiciels détectés"
            Update-Status "✓ $($software.Count) logiciels chargés"
        }
        else {
            Update-Status "⚠ Module de détection non disponible"
            $controls.txtSoftwareStats.Text = "Module de détection requis"
        }
    }
    catch {
        Update-Status "✗ Erreur lors de la détection: $_"
        Write-Log "Erreur détection logiciels: $_" -Level ERROR
    }
}

# Gestionnaires d'événements
if ($controls.btnDetectSoftware) {
    $controls.btnDetectSoftware.Add_Click({ Load-SoftwareList })
}

if ($controls.btnRefreshAll) {
    $controls.btnRefreshAll.Add_Click({ Load-SoftwareList })
}

if ($controls.txtDateTime) {
    # Timer pour l'heure
    $timer = New-Object System.Windows.Threading.DispatcherTimer
    $timer.Interval = [TimeSpan]::FromSeconds(1)
    $timer.Add_Tick({
        $controls.txtDateTime.Text = Get-Date -Format "dd/MM/yyyy HH:mm:ss"
    })
    $timer.Start()
}

# Chargement initial
Load-SoftwareList

# Affichage de la fenêtre
Write-Log "Affichage de l'interface utilisateur..." -Level DEBUG
Update-Status "Application initialisée"

try {
    $window.ShowDialog() | Out-Null
}
catch {
    Write-Log "✗ Erreur lors de l'affichage: $_" -Level ERROR
    exit 1
}

Write-Log "Application fermée" -Level INFO
'@

    Set-Content -Path $appScriptPath -Value $correctedScript -Encoding UTF8
    Write-Host "✓ Script App.xaml.ps1 complètement reconstruit" -ForegroundColor Green
}

# Menu principal
Write-Host "=== CORRECTION DES RÉFÉRENCES WPF ===" -ForegroundColor Cyan
Write-Host "1. Corriger les références uniquement" -ForegroundColor White
Write-Host "2. Recréer complètement le script App.xaml.ps1" -ForegroundColor White
Write-Host "3. Annuler" -ForegroundColor White

$choice = Read-Host "`nVotre choix (1-3)"

switch ($choice) {
    "1" {
        Fix-WPFReferences
    }
    "2" {
        Create-CorrectedAppScript
    }
    "3" {
        Write-Host "Opération annulée" -ForegroundColor Yellow
        exit
    }
    default {
        Write-Host "Choix invalide, création du script complet par défaut" -ForegroundColor Yellow
        Create-CorrectedAppScript
    }
}

Write-Host "`n=== INSTRUCTIONS ===" -ForegroundColor Cyan
Write-Host "1. Testez maintenant avec : .\App.xaml.ps1 -Debug" -ForegroundColor Green
Write-Host "2. Si le problème persiste, vérifiez que .NET est installé" -ForegroundColor Yellow
Write-Host "3. En cas d'autres erreurs, montrez-moi le message complet" -ForegroundColor Yellow