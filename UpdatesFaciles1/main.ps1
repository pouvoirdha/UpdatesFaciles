# 📦 Assemblies classiques WPF
Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase
Add-Type -AssemblyName System.Xaml

# 🔍 Chargement MahApps.Metro
$mahappsPath   = "$PSScriptRoot\Libs\MahApps.Metro\MahApps.Metro.dll"
$controlzExPath = "$PSScriptRoot\Libs\MahApps.Metro\ControlzEx.dll"

# ✅ Test et chargement via Assembly.LoadFrom
if ((Test-Path $mahappsPath) -and (Test-Path $controlzExPath)) {
    [System.Reflection.Assembly]::LoadFrom($controlzExPath) | Out-Null
    [System.Reflection.Assembly]::LoadFrom($mahappsPath) | Out-Null
    Write-Host "✅ DLLs MahApps.Metro chargées avec succès"
} else {
    Write-Warning "⚠️ DLLs manquantes : vérifie Libs\MahApps.Metro"
}

# 📥 Chargement du XAML
[xml]$xaml = Get-Content "$PSScriptRoot\Views\MainWindow.xaml"
$reader = New-Object System.Xml.XmlNodeReader $xaml

try {
    $window = [Windows.Markup.XamlReader]::Load($reader)
    if (-not $window) { throw "Window null" }

    Write-Host "✅ Fenêtre XAML chargée"
} catch {
    Write-Error "❌ Échec du chargement de MetroWindow. Repli sur Window natif..."
    [xml]$fallbackXaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="UpdatesFaciles - Fallback" Width="600" Height="300"
        WindowStartupLocation="CenterScreen">
    <Grid>
        <TextBlock Text="Échec MahApps.Metro. Fenêtre simplifiée." 
                   HorizontalAlignment="Center" VerticalAlignment="Center"
                   FontSize="20" Foreground="Red"/>
    </Grid>
</Window>
"@
    $reader = New-Object System.Xml.XmlNodeReader $fallbackXaml
    $window = [Windows.Markup.XamlReader]::Load($reader)
}

# 🧩 Actions si fenêtre chargée
if ($window) {
    # 🧠 Charger le ViewModel
    . "$PSScriptRoot\ViewModels\MainViewModel.ps1"

    # 🔘 Bouton
    $analyzeButton = $window.FindName("AnalyzeButton")
    if ($analyzeButton) {
        $analyzeButton.Add_Click({
            Write-Host "🛠️ Analyse à $(Get-Date -Format 'HH:mm:ss')"
            [System.Windows.MessageBox]::Show("Analyse en cours...")
        })
    }

    # 📋 Grid
    $grid = $window.FindName("SoftwareGrid")
    if ($grid) {
        $vm = New-MainViewModel
        $grid.ItemsSource = $vm.SoftwareAppList
    }

    # 🪟 Affichage
    $window.ShowDialog() | Out-Null
} else {
    Write-Error "❌ Impossible d'afficher la fenêtre. Script interrompu."
}