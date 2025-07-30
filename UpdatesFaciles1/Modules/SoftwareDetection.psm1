# Généré par Grok le 2025-07-28
# Rôle : Module de détection des logiciels pour UpdatesFaciles (Module 3)
# Chemin : P:\Git\UpdatesFaciles\Sources\SoftwareDetection.psm1
# Respecte UpdatesFaciles_Prompt7.txt : détection registre, portables, raccourcis, scan < 5 min

# Vérifier les modules requis
$requiredModules = @("PromptHelper", "CredentialManager")
foreach ($module in $requiredModules) {
    if (-not (Get-Module -ListAvailable -Name $module)) {
        Write-Error "Module $module requis. Installez via 'Install-Module $module -Scope CurrentUser -Force'."
        return
    }
}

function Get-InstalledSoftware {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]$Filter,
        [Parameter()]
        [ValidateSet("Registry", "Portable", "Shortcut", "All")]
        [string]$Source = "All",
        [Parameter()]
        [string[]]$PortablePaths = @("$env:USERPROFILE\PortableApps", "$env:USERPROFILE\OneDrive", "$env:USERPROFILE\Google Drive")
    )
    try {
        $softwareList = @()
        
        # Détection via registre
        if ($Source -eq "Registry" -or $Source -eq "All") {
            $regPaths = @(
                "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*",
                "HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*",
                "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*"
            )
            foreach ($path in $regPaths) {
                $items = Get-ItemProperty -Path $path -ErrorAction SilentlyContinue
                if ($Filter) {
                    $items = $items | Where-Object { $_.DisplayName -like "*$Filter*" }
                }
                $softwareList += $items | ForEach-Object {
                    New-SoftwareApp -Name $_.DisplayName `
                                  -Version $_.DisplayVersion `
                                  -Publisher $_.Publisher `
                                  -Source "Registry" `
                                  -InstallLocation $_.InstallLocation `
                                  -UninstallString $_.UninstallString `
                                  -CanInstall $true `
                                  -CanUninstall $true
                }
            }
        }

        # Détection des logiciels portables
        if ($Source -eq "Portable" -or $Source -eq "All") {
            foreach ($path in $PortablePaths) {
                if (Test-Path $path) {
                    Get-ChildItem -Path $path -Recurse -Include *.exe | ForEach-Object {
                        $fileInfo = Get-Item $_.FullName
                        $version = [System.Diagnostics.FileVersionInfo]::GetVersionInfo($fileInfo.FullName).FileVersion
                        $publisher = [System.Diagnostics.FileVersionInfo]::GetVersionInfo($fileInfo.FullName).CompanyName
                        if ($Filter -and $fileInfo.Name -notlike "*$Filter*") { return }
                        $softwareList += New-SoftwareApp -Name $fileInfo.BaseName `
                                                       -Version ($version ?? "Inconnu") `
                                                       -Publisher ($publisher ?? "Inconnu") `
                                                       -Source "Portable" `
                                                       -InstallLocation $fileInfo.DirectoryName `
                                                       -CanInstall $false `
                                                       -CanUninstall $false
                    }
                }
            }
        }

        # Détection des raccourcis
        if ($Source -eq "Shortcut" -or $Source -eq "All") {
            $shortcutPaths = @(
                "$env:USERPROFILE\Desktop",
                "$env:APPDATA\Microsoft\Windows\Start Menu\Programs"
            )
            foreach ($path in $shortcutPaths) {
                if (Test-Path $path) {
                    Get-ChildItem -Path $path -Recurse -Include *.lnk | ForEach-Object {
                        $shell = New-Object -ComObject WScript.Shell
                        $shortcut = $shell.CreateShortcut($_.FullName)
                        $targetPath = $shortcut.TargetPath
                        if (Test-Path $targetPath) {
                            $fileInfo = Get-Item $targetPath
                            $version = [System.Diagnostics.FileVersionInfo]::GetVersionInfo($fileInfo.FullName).FileVersion
                            $publisher = [System.Diagnostics.FileVersionInfo]::GetVersionInfo($fileInfo.FullName).CompanyName
                            if ($Filter -and $shortcut.Name -notlike "*$Filter*") { return }
                            $softwareList += New-SoftwareApp -Name $shortcut.Name `
                                                           -Version ($version ?? "Inconnu") `
                                                           -Publisher ($publisher ?? "Inconnu") `
                                                           -Source "Shortcut" `
                                                           -InstallLocation $fileInfo.DirectoryName `
                                                           -CanInstall $false `
                                                           -CanUninstall $false
                        }
                    }
                }
            }
        }

        return $softwareList | Where-Object { $_ } | Sort-Object Name -Unique
    } catch {
        Write-Error "Erreur lors de la détection des logiciels : $_"
        return $null
    }
}

Export-ModuleMember -Function Get-InstalledSoftware