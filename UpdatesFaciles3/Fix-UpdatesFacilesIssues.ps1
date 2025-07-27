#requires -Version 7.0

<#
.SYNOPSIS
    Script de correction automatique des problèmes UpdatesFaciles
.DESCRIPTION
    Corrige automatiquement les problèmes détectés par le diagnostic
#>

param(
    [switch]$WhatIf,
    [switch]$Verbose
)

$ErrorActionPreference = "Stop"

function Write-Status {
    param($Message, $Type = "INFO")
    $color = switch ($Type) {
        "SUCCESS" { "Green" }
        "WARNING" { "Yellow" } 
        "ERROR" { "Red" }
        default { "White" }
    }
    Write-Host "[$Type] $Message" -ForegroundColor $color
}

function Fix-DetectionModule {
    <#
    .SYNOPSIS
        Crée le module Detection.psm1 s'il est manquant
    #>
    $modulePath = ".\Modules\Detection.psm1"
    
    if (-not (Test-Path $modulePath)) {
        Write-Status "Création du module Detection.psm1..." "WARNING"
        
        if (-not $WhatIf) {
            # Créer le dossier Modules s'il n'existe pas
            $moduleDir = Split-Path $modulePath -Parent
            if (-not (Test-Path $moduleDir)) {
                New-Item -Path $moduleDir -ItemType Directory -Force | Out-Null
            }
            
            # Le contenu du module est trop long pour être inclus ici
            # L'utilisateur doit utiliser le module fourni séparément
            Write-Status "⚠ Veuillez créer le fichier Detection.psm1 avec le contenu fourni" "WARNING"
            return $false
        }
        else {
            Write-Status "WHATIF: Créerait le module Detection.psm1" "INFO"
        }
    }
    else {
        Write-Status "Module Detection.psm1 déjà présent" "SUCCESS"
    }
    
    return $true
}

function Fix-AppXamlScript {
    <#
    .SYNOPSIS
        Corrige les erreurs de paramètres dupliqués dans App.xaml.ps1
    #>
    $appScriptPath = ".\App.xaml.ps1"
    
    if (Test-Path $appScriptPath) {
        Write-Status "Vérification du script App.xaml.ps1..." "INFO"
        
        try {
            $content = Get-Content $appScriptPath -Raw
            
            # Rechercher les paramètres dupliqués
            $paramPattern = 'param\s*\(([\s\S]*?)\)'
            if ($content -match $paramPattern) {
                $paramBlock = $matches[1]
                
                # Vérifier s'il y a des paramètres Debug dupliqués
                $debugParams = [regex]::Matches($paramBlock, '\[switch\]\s*\$Debug', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
                
                if ($debugParams.Count -gt 1) {
                    Write-Status "Paramètre Debug dupliqué détecté" "WARNING"
                    
                    if (-not $WhatIf) {
                        # Supprimer les doublons
                        $newParamBlock = $paramBlock
                        for ($i = 1; $i -lt $debugParams.Count; $i++) {
                            $newParamBlock = $newParamBlock.Remove($debugParams[$i].Index, $debugParams[$i].Length)
                        }
                        
                        $newContent = $content -replace [regex]::Escape($paramBlock), $newParamBlock
                        Set-Content -Path $appScriptPath -Value $newContent -Encoding UTF8
                        
                        Write-Status "Paramètres dupliqués corrigés dans App.xaml.ps1" "SUCCESS"
                    }
                    else {
                        Write-Status "WHATIF: Supprimerait les paramètres Debug dupliqués" "INFO"
                    }
                }
                else {
                    Write-Status "Aucun paramètre dupliqué trouvé" "SUCCESS"
                }
            }
        }
        catch {
            Write-Status "Erreur lors de la vérification de App.xaml.ps1: $_" "ERROR"
            return $false
        }
    }
    else {
        Write-Status "Fichier App.xaml.ps1 non trouvé" "WARNING"
        return $false
    }
    
    return $true
}

function Fix-UIResources {
    <#
    .SYNOPSIS
        Crée les ressources UI manquantes
    #>
    $resourcesPath = ".\Views\MainWindow.xaml"
    
    if (-not (Test-Path $resourcesPath)) {
        Write-Status "Création de l'interface principale manquante..." "WARNING"
        
        if (-not $WhatIf) {
            $viewsDir = Split-Path $resourcesPath -Parent
            if (-not (Test-Path $viewsDir)) {
                New-Item -Path $viewsDir -ItemType Directory -Force | Out-Null
            }
            
            # Interface XAML basique
            $xamlContent = @'
<Window x:Class="UpdatesFaciles.MainWindow"
        xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        xmlns:mah="http://metro.mahapps.com/winfx/xaml/controls"
        Title="UpdatesFaciles" Height="600" Width="800"
        WindowStartupLocation="CenterScreen">
    
    <Grid>
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>
        
        <!-- Header -->
        <Border Grid.Row="0" Background="#2D3748" Padding="20,10">
            <TextBlock Text="UpdatesFaciles" FontSize="24" FontWeight="Bold" 
                      Foreground="White" HorizontalAlignment="Center"/>
        </Border>
        
        <!-- Main Content -->
        <TabControl Grid.Row="1" Margin="10">
            <TabItem Header="Logiciels installés">
                <Grid>
                    <Grid.RowDefinitions>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="*"/>
                    </Grid.RowDefinitions>
                    
                    <StackPanel Grid.Row="0" Orientation="Horizontal" Margin="5">
                        <Button Name="btnRefresh" Content="Actualiser" Padding="10,5" Margin="5"/>
                        <Button Name="btnCheckUpdates" Content="Vérifier les mises à jour" Padding="10,5" Margin="5"/>
                    </StackPanel>
                    
                    <DataGrid Grid.Row="1" Name="dgSoftware" AutoGenerateColumns="False" 
                             CanUserAddRows="False" Margin="5">
                        <DataGrid.Columns>
                            <DataGridTextColumn Header="Nom" Binding="{Binding Name}" Width="*"/>
                            <DataGridTextColumn Header="Version" Binding="{Binding Version}" Width="100"/>
                            <DataGridTextColumn Header="Éditeur" Binding="{Binding Publisher}" Width="150"/>
                            <DataGridTextColumn Header="Source" Binding="{Binding Source}" Width="80"/>
                        </DataGrid.Columns>
                    </DataGrid>
                </Grid>
            </TabItem>
            
            <TabItem Header="Actions">
                <ScrollViewer>
                    <StackPanel Margin="10">
                        <TextBlock Text="Actions disponibles:" FontWeight="Bold" Margin="0,0,0,10"/>
                        <Button Name="btnInstallChocolatey" Content="Installer Chocolatey" 
                               Padding="10,5" Margin="5" HorizontalAlignment="Left"/>
                        <Button Name="btnInstallWinget" Content="Installer Winget" 
                               Padding="10,5" Margin="5" HorizontalAlignment="Left"/>
                        <Button Name="btnSystemInfo" Content="Informations système" 
                               Padding="10,5" Margin="5" HorizontalAlignment="Left"/>
                    </StackPanel>
                </ScrollViewer>
            </TabItem>
        </TabControl>
        
        <!-- Status Bar -->
        <StatusBar Grid.Row="2">
            <StatusBarItem>
                <TextBlock Name="txtStatus" Text="Prêt"/>
            </StatusBarItem>
        </StatusBar>
    </Grid>
</Window>
'@
            
            Set-Content -Path $resourcesPath -Value $xamlContent -Encoding UTF8
            Write-Status "Interface principale créée" "SUCCESS"
        }
        else {
            Write-Status "WHATIF: Créerait l'interface principale" "INFO"
        }
    }
    else {
        Write-Status "Interface principale déjà présente" "SUCCESS"
    }
    
    return $true
}

function Fix-ModuleStructure {
    <#
    .SYNOPSIS
        Crée la structure de modules manquante
    #>
    $modules = @{
        "SoftwareApp.psm1" = "Module principal de gestion des applications"
        "UI.psm1" = "Module de gestion de l'interface utilisateur"
        "Actions.psm1" = "Module des actions logicielles"
        "SecureLogs.psm1" = "Module de logs sécurisés"
    }
    
    foreach ($module in $modules.GetEnumerator()) {
        $modulePath = ".\Modules\$($module.Key)"
        
        if (-not (Test-Path $modulePath)) {
            Write-Status "Création du module $($module.Key)..." "WARNING"
            
            if (-not $WhatIf) {
                $moduleContent = @"
#requires -Version 7.0

<#
.SYNOPSIS
    $($module.Value)
.DESCRIPTION
    Module UpdatesFaciles - $($module.Value)
.VERSION
    1.0.0
#>

# Module de base - À implémenter
Write-Host "Module $($module.Key) chargé" -ForegroundColor Green

Export-ModuleMember -Function @()
"@
                Set-Content -Path $modulePath -Value $moduleContent -Encoding UTF8
                Write-Status "Module $($module.Key) créé" "SUCCESS"
            }
            else {
                Write-Status "WHATIF: Créerait le module $($module.Key)" "INFO"
            }
        }
    }
    
    return $true
}

# Fonction principale
function Start-Fixes {
    Write-Status "=== CORRECTION AUTOMATIQUE DES PROBLÈMES ===" "INFO"
    
    if ($WhatIf) {
        Write-Status "Mode WHATIF activé - Aucune modification ne sera effectuée" "WARNING"
    }
    
    $fixes = @(
        @{ Name = "Module Detection"; Function = { Fix-DetectionModule } },
        @{ Name = "Script App.xaml"; Function = { Fix-AppXamlScript } },
        @{ Name = "Ressources UI"; Function = { Fix-UIResources } },
        @{ Name = "Structure modules"; Function = { Fix-ModuleStructure } }
    )
    
    $successCount = 0
    
    foreach ($fix in $fixes) {
        Write-Status "Traitement: $($fix.Name)" "INFO"
        try {
            if (& $fix.Function) {
                $successCount++
            }
        }
        catch {
            Write-Status "Erreur lors de la correction de $($fix.Name): $_" "ERROR"
        }
        Write-Host ""
    }
    
    Write-Status "=== RÉSUMÉ ===" "INFO"
    Write-Status "$successCount/$($fixes.Count) corrections effectuées avec succès" "SUCCESS"
    
    if (-not $WhatIf) {
        Write-Status "Relancez le diagnostic pour vérifier les corrections" "INFO"
    }
}

# Lancement du script
Start-Fixes