function Get-InstalledSoftware {
    $paths = @(
        "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*"
    )

    $apps = @()

    foreach ($path in $paths) {
        $items = Get-ItemProperty -Path $path -ErrorAction SilentlyContinue
        foreach ($item in $items) {
            if ($item.DisplayName) {
                $apps += New-SoftwareApp -Name $item.DisplayName `
                                         -Version $item.DisplayVersion `
                                         -Publisher ($item.Publisher ?? "Inconnu") `
                                         -Path ($item.InstallLocation ?? "") `
                                         -Source "Installé"
            }
        }
    }

    return $apps
}