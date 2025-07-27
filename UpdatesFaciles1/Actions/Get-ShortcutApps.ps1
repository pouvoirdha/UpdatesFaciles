function Get-ShortcutApps {
    $shortcutApps = @()

    $shortcutPaths = @(
        "$env:USERPROFILE\Desktop",
        "$env:APPDATA\Microsoft\Windows\Start Menu\Programs"
    )

    foreach ($folder in $shortcutPaths) {
        if (-not (Test-Path $folder)) { continue }

        $shortcuts = Get-ChildItem -Path $folder -Recurse -Filter *.lnk -ErrorAction SilentlyContinue
        $shell = New-Object -ComObject WScript.Shell

        foreach ($shortcut in $shortcuts) {
            try {
                $target = $shell.CreateShortcut($shortcut.FullName).TargetPath
                if ($target -and (Test-Path $target) -and ($target.EndsWith(".exe"))) {
                    $app = New-SoftwareApp -Name (Split-Path $target -LeafBase) -Version "" -Source "Raccourci" -Path $target
                    $shortcutApps += $app
                }
            } catch {
                Write-Warning "⚠️ Raccourci illisible : $($_.Exception.Message)"
            }
        }
    }

    return $shortcutApps
}