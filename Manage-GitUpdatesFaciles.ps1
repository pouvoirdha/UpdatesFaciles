# Généré par Grok le 2025-07-28
# Rôle : Automatiser les opérations Git pour UpdatesFaciles
# Utilisation : Exécutez dans PowerShell depuis P:\Git\UpdatesFaciles
cd P:\Git\UpdatesFaciles
P:\Git\PortableGit-2.50.1-64-bit.7z\bin\git.exe add .
P:\Git\PortableGit-2.50.1-64-bit.7z\bin\git.exe commit -m "Mise à jour automatique des fichiers"
P:\Git\PortableGit-2.50.1-64-bit.7z\bin\git.exe push origin main
Write-Host "Succès : Fichiers validés et poussés vers https://github.com/pouvoirdha/UpdatesFaciles"