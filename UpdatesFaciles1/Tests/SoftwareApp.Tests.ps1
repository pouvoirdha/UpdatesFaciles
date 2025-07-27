# 📥 Charger la fonction SoftwareApp
. "P:\Portable\PROJETS\1\UpdatesFaciles\Models\SoftwareApp.ps1"

Describe "SoftwareApp" {
    It "Création d’un objet logiciel simple" {
        $app = New-SoftwareApp `
            -Name "TestApp" `
            -Publisher "Moi" `
            -Version "1.0" `
            -Type "Installed" `
            -State "Present" `
            -InstallPath "C:\Apps\TestApp\app.exe" `
            -Source "Registry" `
            -CanInstall $true `
            -CanUninstall $false

        $app.Name | Should -Be "TestApp"
    }
}