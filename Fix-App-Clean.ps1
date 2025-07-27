#requires -Version 7.0

Write-Host "=== CORRECTION UPDATESFACILES ===" -ForegroundColor Cyan

function Create-FixedApp {
    $appPath = ".\App.xaml.ps1"
    
    # Backup
    if (Test-Path $appPath) {
        $backup = "App.xaml.ps1.backup-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
        Copy-Item $appPath $backup -Force
        Write-Host "Backup cree: $backup" -ForegroundColor Green
    }
    
    $script = @'
#requires -Version 7.0

param(
    [switch]$Debug,
    [switch]$NoLogo,
    [string]$LogPath = ".\logs.txt"
)

$ErrorActionPreference = "Stop"

if (-not $NoLogo) {
    Clear-Host
    Write-Host "    ╔══════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "    ║           UpdatesFaciles             ║" -ForegroundColor Cyan  
    Write-Host "    ║     Assistant de gestion logiciels   ║" -ForegroundColor Cyan
    Write-Host "    ║            v1.0.3 (fixed)           ║" -ForegroundColor Cyan
    Write-Host "    ╚══════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
}

function Write-AppLog {
    param(
        [Parameter(Mandatory)]
        [string]$Message,
        [ValidateSet('INFO', 'WARNING', 'ERROR', 'SUCCESS', 'DEBUG')]
        [string]$Level = 'INFO'
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    
    $display = switch ($Level) {
        'SUCCESS' { @{ Color = 'Green'; Prefix = '[OK]' } }
        'ERROR' { @{ Color = 'Red'; Prefix = '[ERR]' } }
        'WARNING' { @{ Color = 'Yellow'; Prefix = '[WARN]' } }
        'DEBUG' { @{ Color = 'Gray'; Prefix = '[DBG]' } }
        default { @{ Color = 'White'; Prefix = '[INFO]' } }
    }
    
    if ($Debug -or $Level -ne 'DEBUG') {
        Write-Host "$($display.Prefix) $Message" -ForegroundColor $display.Color
    }
    
    try {
        $logEntry = "[$timestamp] [$Level] $Message"
        Add-Content -Path $LogPath -Value $logEntry -Encoding UTF8 -ErrorAction SilentlyContinue
    }
    catch {
        # Ignore log errors
    }
}

Write-AppLog "Starting UpdatesFaciles application..." -Level INFO

# Load WPF assemblies
Write-AppLog "Loading WPF assemblies..." -Level INFO

$assemblies = @('PresentationFramework', 'PresentationCore', 'WindowsBase', 'System.Xaml')
foreach ($assembly in $assemblies) {
    try {
        Add-Type -AssemblyName $assembly -ErrorAction Stop
        Write-AppLog "Assembly $assembly loaded" -Level SUCCESS
    }
    catch {
        Write-AppLog "Failed to load assembly $assembly : $_" -Level ERROR
        exit 1
    }
}

# Check Detection module
$detectionAvailable = $false
if (Test-Path ".\Modules\Detection.psm1") {
    try {
        Import-Module ".\Modules\Detection.psm1" -Force -ErrorAction Stop
        $detectionAvailable = $true
        Write-AppLog "Detection module loaded" -Level SUCCESS
    }
    catch {
        Write-AppLog "Detection module failed to load: $_" -Level WARNING
    }
} else {
    Write-AppLog "Detection.psm1 not found" -Level WARNING
}

# XAML Interface
$xaml = @'
<Window x:Class="UpdatesFaciles.MainWindow"
        xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="UpdatesFaciles - Software Manager" 
        Height="600" Width="900"
        WindowStartupLocation="CenterScreen"
        MinHeight="450" MinWidth="650">
    
    <Grid Margin="10">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>
        
        <!-- Header -->
        <Border Grid.Row="0" Background="#2c3e50" Padding="15,10" Margin="0,0,0,10">
            <Grid>
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="Auto"/>
                </Grid.ColumnDefinitions>
                
                <TextBlock Grid.Column="0" Text="UpdatesFaciles - Installed Software Manager" 
                          FontSize="16" FontWeight="Bold" Foreground="White" 
                          VerticalAlignment="Center"/>
                
                <Button Grid.Column="1" Name="btnRefresh" Content="Refresh" 
                       Background="#3498db" Foreground="White" BorderThickness="0"
                       Padding="15,5" FontWeight="SemiBold"/>
            </Grid>
        </Border>
        
        <!-- Main Content -->
        <Grid Grid.Row="1">
            <Grid.RowDefinitions>
                <RowDefinition Height="Auto"/>
                <RowDefinition Height="Auto"/>
                <RowDefinition Height="*"/>
            </Grid.RowDefinitions>
            
            <!-- Info -->
            <TextBlock Grid.Row="0" Name="txtInfo" 
                      Text="Initializing..." 
                      Margin="5,0,5,10" FontStyle="Italic" 
                      Foreground="#666" FontSize="12"/>
            
            <!-- Toolbar -->
            <StackPanel Grid.Row="1" Orientation="Horizontal" Margin="5,0,5,10">
                <Button Name="btnDetect" Content="Detect Software" 
                       Background="#27ae60" Foreground="White" 
                       BorderThickness="0" Padding="12,6" Margin="0,0,5,0"/>
                <Button Name="btnTest" Content="Load Test Data" 
                       Background="#f39c12" Foreground="White" 
                       BorderThickness="0" Padding="12,6" Margin="0,0,5,0"/>
                <Button Name="btnClear" Content="Clear List" 
                       Background="#e74c3c" Foreground="White" 
                       BorderThickness="0" Padding="12,6" Margin="0,0,15,0"/>
                <TextBox Name="txtSearch" Width="200" Height="26" 
                        VerticalContentAlignment="Center" 
                        Text="Search software..."/>
            </StackPanel>
            
            <!-- Software DataGrid -->
            <DataGrid Grid.Row="2" Name="dgSoftware" 
                     AutoGenerateColumns="False"
                     CanUserAddRows="False" 
                     CanUserDeleteRows="False"
                     CanUserResizeRows="False"
                     GridLinesVisibility="Horizontal"
                     HeadersVisibility="Column"
                     AlternatingRowBackground="#f8f9fa"
                     Margin="5">
                <DataGrid.Columns>
                    <DataGridTextColumn Header="Software Name" 
                                      Binding="{Binding Name}" 
                                      Width="*" MinWidth="200"/>
                    <DataGridTextColumn Header="Version" 
                                      Binding="{Binding Version}" 
                                      Width="120"/>
                    <DataGridTextColumn Header="Publisher" 
                                      Binding="{Binding Publisher}" 
                                      Width="150"/>
                    <DataGridTextColumn Header="Source" 
                                      Binding="{Binding Source}" 
                                      Width="90"/>
                </DataGrid.Columns>
            </DataGrid>
        </Grid>
        
        <!-- Status Bar -->
        <Border Grid.Row="2" Background="#ecf0f1" Padding="10,5" Margin="0,10,0,0">
            <Grid>
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="Auto"/>
                </Grid.ColumnDefinitions>
                
                <TextBlock Grid.Column="0" Name="txtStatus" Text="Ready" 
                          FontWeight="SemiBold" VerticalAlignment="Center"/>
                <TextBlock Grid.Column="1" Name="txtTime" Text="" 
                          FontSize="11" VerticalAlignment="Center"/>
            </Grid>
        </Border>
    </Grid>
</Window>
'@

# Load XAML
Write-AppLog "Loading XAML interface..." -Level DEBUG

try {
    [xml]$xamlDoc = $xaml
    $reader = New-Object System.Xml.XmlNodeReader $xamlDoc
    $window = [Windows.Markup.XamlReader]::Load($reader)
    Write-AppLog "XAML interface loaded successfully" -Level SUCCESS
}
catch {
    Write-AppLog "CRITICAL ERROR loading XAML: $_" -Level ERROR
    Read-Host "Press Enter to exit"
    exit 1
}

# Get controls
Write-AppLog "Getting UI controls..." -Level DEBUG

$script:UIControls = @{}
$controlNames = @('dgSoftware', 'txtInfo', 'txtStatus', 'txtTime', 'txtSearch', 'btnRefresh', 'btnDetect', 'btnTest', 'btnClear')

$foundCount = 0
foreach ($name in $controlNames) {
    try {
        $control = $window.FindName($name)
        if ($control) {
            $script:UIControls[$name] = $control
            $foundCount++
            Write-AppLog "Control '$name' found: $($control.GetType().Name)" -Level DEBUG
        } else {
            Write-AppLog "Control '$name' not found in XAML" -Level WARNING
        }
    }
    catch {
        Write-AppLog "Error getting control '$name': $_" -Level WARNING
    }
}

Write-AppLog "Found $foundCount out of $($controlNames.Count) controls" -Level INFO

# Status update function
function Update-Status {
    param([string]$Message)
    try {
        if ($script:UIControls.ContainsKey('txtStatus') -and $script:UIControls['txtStatus']) {
            $script:UIControls['txtStatus'].Text = $Message
        }
        Write-AppLog $Message -Level INFO
    }
    catch {
        Write-AppLog "Error updating status: $_" -Level DEBUG
    }
}

# Test data function
function Get-TestData {
    return @(
        [PSCustomObject]@{ Name = "Google Chrome"; Version = "120.0.6099.129"; Publisher = "Google LLC"; Source = "Test" },
        [PSCustomObject]@{ Name = "Microsoft Edge"; Version = "120.0.2210.89"; Publisher = "Microsoft Corporation"; Source = "Test" },
        [PSCustomObject]@{ Name = "Mozilla Firefox"; Version = "121.0"; Publisher = "Mozilla Foundation"; Source = "Test" },
        [PSCustomObject]@{ Name = "VLC Media Player"; Version = "3.0.20"; Publisher = "VideoLAN"; Source = "Test" },
        [PSCustomObject]@{ Name = "7-Zip"; Version = "23.01"; Publisher = "Igor Pavlov"; Source = "Test" },
        [PSCustomObject]@{ Name = "PowerShell 7"; Version = "7.4.1"; Publisher = "Microsoft Corporation"; Source = "Test" },
        [PSCustomObject]@{ Name = "Visual Studio Code"; Version = "1.85.2"; Publisher = "Microsoft Corporation"; Source = "Test" },
        [PSCustomObject]@{ Name = "Notepad++"; Version = "8.6.2"; Publisher = "Don Ho"; Source = "Test" },
        [PSCustomObject]@{ Name = "Adobe Acrobat Reader"; Version = "23.008.20470"; Publisher = "Adobe Systems"; Source = "Test" },
        [PSCustomObject]@{ Name = "WinRAR"; Version = "6.24"; Publisher = "win.rar GmbH"; Source = "Test" }
    )
}

# Load software data function
function Load-SoftwareList {
    param([switch]$UseTestData)
    
    Update-Status "Loading software data..."
    
    try {
        # Check DataGrid exists
        if (-not $script:UIControls.ContainsKey('dgSoftware')) {
            throw "DataGrid 'dgSoftware' not found"
        }
        
        $dataGrid = $script:UIControls['dgSoftware']
        
        # Verify it's a DataGrid
        if ($dataGrid.GetType().Name -ne 'DataGrid') {
            throw "Control is not a DataGrid (type: $($dataGrid.GetType().Name))"
        }
        
        # Get data
        if ($UseTestData -or -not $detectionAvailable) {
            Write-AppLog "Using test data" -Level INFO
            $data = Get-TestData
            $dataType = "test data"
        } else {
            Write-AppLog "Attempting real software detection..." -Level INFO
            try {
                $data = Get-AllInstalledSoftware -UseCache
                $dataType = "detected software"
            }
            catch {
                Write-AppLog "Detection failed, using test data: $_" -Level WARNING
                $data = Get-TestData
                $dataType = "test data (detection failed)"
            }
        }
        
        # Validate data
        if (-not $data -or $data.Count -eq 0) {
            Write-AppLog "No data available" -Level WARNING
            $data = @()
        }
        
        # Set DataGrid source
        $dataGrid.ItemsSource = $data
        
        # Update info
        $count = $data.Count
        if ($script:UIControls.ContainsKey('txtInfo') -and $script:UIControls['txtInfo']) {
            $script:UIControls['txtInfo'].Text = "$count items from $dataType"
        }
        
        Update-Status "Successfully loaded $count items"
        Write-AppLog "DataGrid updated with $count items" -Level SUCCESS
        
        return $true
        
    }
    catch {
        $errorMsg = "Error loading data: $_"
        Update-Status $errorMsg
        Write-AppLog $errorMsg -Level ERROR
        
        # Debug info
        if ($Debug) {
            Write-AppLog "DEBUG - Available controls: $($script:UIControls.Keys -join ', ')" -Level DEBUG
            if ($script:UIControls.ContainsKey('dgSoftware')) {
                $grid = $script:UIControls['dgSoftware']
                Write-AppLog "DEBUG - DataGrid type: $($grid.GetType().FullName)" -Level DEBUG
            }
        }
        
        return $false
    }
}

# Clear data function
function Clear-Data {
    try {
        if ($script:UIControls.ContainsKey('dgSoftware')) {
            $script:UIControls['dgSoftware'].ItemsSource = $null
            if ($script:UIControls.ContainsKey('txtInfo')) {
                $script:UIControls['txtInfo'].Text = "List cleared"
            }
            Update-Status "List cleared"
        }
    }
    catch {
        Write-AppLog "Error clearing data: $_" -Level ERROR
    }
}

# Setup event handlers
Write-AppLog "Setting up event handlers..." -Level DEBUG

# Refresh button
if ($script:UIControls.ContainsKey('btnRefresh')) {
    $script:UIControls['btnRefresh'].Add_Click({ Load-SoftwareList })
    Write-AppLog "btnRefresh event configured" -Level DEBUG
}

# Detect button
if ($script:UIControls.ContainsKey('btnDetect')) {
    $script:UIControls['btnDetect'].Add_Click({ Load-SoftwareList -UseTestData:$false })
    Write-AppLog "btnDetect event configured" -Level DEBUG
}

# Test button
if ($script:UIControls.ContainsKey('btnTest')) {
    $script:UIControls['btnTest'].Add_Click({ Load-SoftwareList -UseTestData })
    Write-AppLog "btnTest event configured" -Level DEBUG
}

# Clear button
if ($script:UIControls.ContainsKey('btnClear')) {
    $script:UIControls['btnClear'].Add_Click({ Clear-Data })
    Write-AppLog "btnClear event configured" -Level DEBUG
}

# Time timer
if ($script:UIControls.ContainsKey('txtTime')) {
    $timer = New-Object System.Windows.Threading.DispatcherTimer
    $timer.Interval = [TimeSpan]::FromSeconds(1)
    $timer.Add_Tick({
        try {
            $script:UIControls['txtTime'].Text = Get-Date -Format "HH:mm:ss"
        }
        catch {
            # Ignore timer errors
        }
    })
    $timer.Start()
    Write-AppLog "Time timer configured" -Level DEBUG
}

# Initial load
Write-AppLog "Performing initial data load..." -Level INFO
$initialLoad = Load-SoftwareList -UseTestData

# Window loaded event
$window.add_Loaded({
    if ($initialLoad) {
        Update-Status "Application ready - Data loaded"
    } else {
        Update-Status "Application ready - Initial load failed"
    }
    Write-AppLog "Interface fully initialized" -Level SUCCESS
})

# Show window
Write-AppLog "Displaying main window..." -Level INFO

try {
    if (-not $window) {
        throw "Window object not initialized"
    }
    
    Update-Status "Starting user interface..."
    
    $result = $window.ShowDialog()
    
    Write-AppLog "Window closed normally (result: $result)" -Level INFO
    
}
catch {
    Write-AppLog "FATAL ERROR displaying window: $_" -Level ERROR
    Write-AppLog "Exception type: $($_.Exception.GetType().FullName)" -Level ERROR
    
    if ($_.ScriptStackTrace) {
        Write-AppLog "Stack trace: $($_.ScriptStackTrace)" -Level ERROR
    }
    
    Write-Host "`nA critical error occurred." -ForegroundColor Red
    Write-Host "Check log file: $LogPath" -ForegroundColor Yellow
    Read-Host "Press Enter to exit"
    exit 1
}

Write-AppLog "UpdatesFaciles closed normally" -Level SUCCESS
'@

    Set-Content -Path $appPath -Value $script -Encoding UTF8
    Write-Host "App.xaml.ps1 fixed successfully" -ForegroundColor Green
    return $true
}

# Execute
Write-Host "Creating fixed version of App.xaml.ps1..." -ForegroundColor Yellow

if (Create-FixedApp) {
    Write-Host ""
    Write-Host "=== CORRECTION COMPLETE ===" -ForegroundColor Green
    Write-Host ""
    Write-Host "Changes made:" -ForegroundColor Cyan
    Write-Host "• Clean XAML interface without special characters" -ForegroundColor White
    Write-Host "• Secure control retrieval with error handling" -ForegroundColor White  
    Write-Host "• Complete error management" -ForegroundColor White
    Write-Host "• Integrated test data" -ForegroundColor White
    Write-Host "• Detailed logging for debugging" -ForegroundColor White
    Write-Host "• English interface to avoid encoding issues" -ForegroundColor White
    Write-Host ""
    Write-Host "TEST NOW:" -ForegroundColor Green
    Write-Host ".\App.xaml.ps1 -Debug" -ForegroundColor Green
    Write-Host ""
    Write-Host "The application should now work without errors." -ForegroundColor White
} else {
    Write-Host "Failed to create fixed version" -ForegroundColor Red
}