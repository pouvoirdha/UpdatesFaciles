. "$PSScriptRoot\Actions\Get-PortableApps.ps1"

# ✅ Assemblies classiques
Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase
Add-Type -AssemblyName System.Xaml

. "$PSScriptRoot\Models\SoftwareApp.ps1"
. "$PSScriptRoot\Actions\Get-ShortcutApps.ps1"


# ✅ Chargement des DLLs MahApps
[System.Reflection.Assembly]::LoadFrom("$PSScriptRoot\Libs\MahApps.Metro\ControlzEx.dll") | Out-Null
[System.Reflection.Assembly]::LoadFrom("$PSScriptRoot\Libs\MahApps.Metro\MahApps.Metro.dll") | Out-Null
Write-Host "✅ DLLs MahApps.Metro chargées"

# ✅ Logo ASCII
@"
 ___       __         _         __        _         
| _ \___ _/ _|___ _ _| |_ ___  / _|___ __| |___ _ _ 
|   / -_)  _/ -_) '_|  _/ _ \|  _/ -_|_-< / -_) '_|
|_|_\___|_| \___|_|  \__\___/|_| \___/__/_\___|_|  

   Script : App.xaml.ps1
   Projet : UpdatesFaciles
"@ | Write-Host -ForegroundColor Cyan

# ✅ Chargement du XAML
$xamlText = Get-Content "$PSScriptRoot\Views\MainWindow.xaml" -Raw
$reader = [System.Xml.XmlReader]::Create([System.IO.StringReader]::new($xamlText))

try {
    $window = [Windows.Markup.XamlReader]::Load($reader)
} catch {
    Write-Error "❌ Échec du chargement XAML : $_"
    return
}

if (-not $window) {
    Write-Error "❌ L'objet 'window' est nul après chargement XAML."
    return
}

if (-not $window -or $window.GetType().Name -notmatch "Window|MetroWindow") {
    Write-Error "❌ L'objet retourné n'est pas une fenêtre WPF valide."
    return
}

# ✅ Icône manuelle
$iconPath = "$PSScriptRoot\Ressources\icon.ico"
if (-not (Test-Path $iconPath)) {
    Write-Warning "⚠️ Fichier icon.ico introuvable"
}

if (Test-Path $iconPath) {
    try {
        $stream = [System.IO.FileStream]::new($iconPath, 'Open', 'Read')
        $decoder = [System.Windows.Media.Imaging.IconBitmapDecoder]::new(
            $stream,
            [System.Windows.Media.Imaging.BitmapCreateOptions]::PreservePixelFormat,
            [System.Windows.Media.Imaging.BitmapCacheOption]::Default
        )
        $window.Icon = $decoder.Frames[0]
    } catch {
        Write-Warning "⚠️ Icône non chargée : $_"
    }
}

# ✅ Styles MahApps.Metro
$stylePaths = @(
    "Styles/Controls.xaml",
    "Styles/Fonts.xaml",
    "Styles/Colors.xaml",
    "Styles/Accents/Blue.xaml",
    "Styles/Accents/BaseLight.xaml"
)
foreach ($path in $stylePaths) {
    try {
        $uri = "pack://application:,,,/MahApps.Metro;component/$path"
        $dict = New-Object System.Windows.ResourceDictionary
        $dict.Source = $uri
        [System.Windows.Application]::Current.Ressources.MergedDictionaries.Add($dict)
    } catch {
        Write-Warning "⚠️ Style non chargé : $path"
    }
}

# ✅ ViewModel
. "$PSScriptRoot\ViewModels\MainViewModel.ps1"
$vm = New-MainViewModel

# 🧩 Lier les éléments
$grid = $window.FindName("SoftwareGrid")
$grid.ItemsSource = $vm.SoftwareAppList
# 🧩 Préparer les éléments d’interface pour le scan personnalisé
$boxInstalled = $window.FindName("ScanInstalledBox")
$boxPortable  = $window.FindName("ScanPortableBox")
$pathPortable = $window.FindName("PortablePathBox")
$boxShortcuts = $window.FindName("ScanShortcutsBox")

$scanButton = $window.FindName("AnalyzeButton")
$scanButton.Add_Click({
    $apps = @()

    if ($boxInstalled.IsChecked) {
        $apps += Get-InstalledSoftware
        
    }

    if ($boxPortable.IsChecked) {
        $apps += Get-PortableApps -Folder $pathPortable.Text
        $apps += Get-PortableApps -Folder $pathPortable.Text
    }

    if ($boxShortcuts.IsChecked) {
        $apps += Get-ShortcutApps
    }

    if (-not $apps -or $apps.Count -eq 0) {
        [System.Windows.MessageBox]::Show("Aucun logiciel détecté.")
        return
    }

    $vm.SoftwareAppList.Clear()
    foreach ($app in $apps) {
        $vm.SoftwareAppList.Add($app)
    }

    [System.Windows.MessageBox]::Show("📊 ${($apps.Count)} logiciels détectés.")
})

# ▶️ Afficher
$window.ShowDialog() | Out-Null