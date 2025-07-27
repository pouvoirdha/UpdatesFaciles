function Get-PortableApps {
    param (
        [string]$Folder = "P:\Portable"
    )
    $apps = @()
    if (-not (Test-Path $Folder)) {
        Write-Warning "📁 Dossier introuvable : $Folder"
        return $apps
    }

    $files = Get-ChildItem -Path $Folder -Recurse -Filter *.exe -ErrorAction SilentlyContinue
    foreach ($file in $files) {
        $apps += New-SoftwareApp -Name $file.BaseName `
                                 -Version "" `
                                 -Publisher "" `
                                 -Path $file.FullName `
                                 -Source "Portable"
    }
    return $apps
}