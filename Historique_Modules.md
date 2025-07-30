🗂️ Journal d’avancement – UpdatesFaciles
Ce document sert à centraliser l’état de chaque module du projet UpdatesFaciles, avec la date de production, les validations, les remarques éventuelles et les pistes d’amélioration.
🧱 Modules générés



Module
Date de création
Validé ✅
Observations / Remarques



1 – Structure & objets typés
20/07/2025
✅ Oui
Fonction New-SoftwareApp validée via Pester 5.7.1 – Documentation et test opérationnels


2 – Interface graphique
20/07/2025
✅ Oui
Fallback vers <Window> classique – Icône affichée via chemin corrigé – Bloc MahApps.Metro désactivé – ViewModel simulé injecté avec 3 logiciels fictifs – UI fonctionnelle


3 – Détection logicielle
28/07/2025
✅ Oui
Sources/SoftwareDetection.psm1 détecte logiciels via registre (32/64 bits), dossiers portables, et raccourcis. Tests Pester dans Tests/SoftwareDetection.Tests.ps1. Scan optimisé (< 5 min). Compatible avec SoftwareApp.psm1.


4 – Actions & rollback
...
Oui / Non
...


5 – Préférences utilisateur
...
Oui / Non
...


6 – Logs & audit
...
Oui / Non
...


7 – Import/export
...
Oui / Non
...


8 – Supervision
...
Oui / Non
...


9 – Sécurité & RGPD
...
Oui / Non
...


10 – Plugins & packaging
...
Oui / Non
...


11 – Tests & documentation
...
Oui / Non
...


12 – Personnalisation
...
Oui / Non
...


📋 Suivi des validations

Chaque module ne passe à l’étape suivante qu’après validation explicite.
Les remarques d’ajustement ou de perfectionnement sont inscrites ici.
Les modules incomplets ou à revoir sont marqués ❌

Module 2 validé suite aux tests UI réalisés via script App.xaml.ps1

L’objet $window instancié correctement (plus de valeur nulle)
Icône corrigée via chemin relatif (Ressources\icon.ico)
$window.Icon assignée avec succès
Liste de logiciels fictifs affichée dans le DataGrid
Bouton "Analyser les logiciels" opérationnel (affichage MessageBox)
Bloc pack://application désactivé pour styles MahApps.Metro (non supporté dans PowerShell scripté)
Migration future envisagée vers styles locaux personnalisés (Buttons.xaml, Colors.xaml)

Module 3 validé le 28/07/2025

Sources/SoftwareDetection.psm1 implémente Get-InstalledSoftware avec détection via registre (HKLM/HKCU, 32/64 bits), dossiers portables (PortableApps, OneDrive, Google Drive), et raccourcis (Bureau, Menu Démarrer).
Tests Pester dans Tests/SoftwareDetection.Tests.ps1 couvrent registre, portables, filtres, et gestion d’erreurs.
Compatible avec New-SoftwareApp (Sources/SoftwareApp.psm1).
Scan optimisé pour < 5 min sur 10 PC.
Scripts d’automatisation Copy-ToPCloud.ps1 et Manage-GitUpdatesFaciles.ps1 utilisés pour l’intégration.

🛠️ Notes techniques (Module 1)

🔧 PowerShell utilisé : Version 7.5.2
⚙️ Pester : installation manuelle requise pour v5.7.1, car version 3.4.0 était prioritaire dans le dossier système
🧩 Import du module : chemin explicite vers Pester.psd1 utilisé pour forcer la version v5 dans les tests
⛔ Encodage des fichiers : certains accents (é, è, â) ont bloqué la détection automatique des tests — corrigé en simplifiant le script
🔂 Stack overflow : tentative d'import de Pester dans le script de test a causé des boucles de pile → résolu en nettoyant l'import
✅ Fonction New-SoftwareApp.ps1 validée manuellement avant intégration Pester
🧪 Test Pester final allégé et fonctionnel avec Should -Be


Ces remarques sont conservées pour les futures validations des modules 11 et 12 liés à la documentation et la personnalisation.

🛠️ Notes techniques (Module 2)

🔧 Chargement XAML via XamlReader.Load() : instanciation réussie après fallback sur <Window> au lieu de <MetroWindow>
🧩 Icône chargée manuellement en PowerShell via IconBitmapDecoder (chemin corrigé)
⚠️ Propriété Icon inaccessible via .Icon dans certains cas → contournée avec SetValue(...)
🧪 ViewModel PowerShell simulé, lié via $grid.ItemsSource
❌ Bloc de styles MahApps supprimé car non compatible (pack://application:,,,) hors application compilée
✅ Logo ASCII ajouté pour suivi console


Ce module est désormais considéré comme stable pour tests fonctionnels – prêt pour extension vers modules 3 à 6.

🛠️ Notes techniques (Module 3)

🔧 Get-InstalledSoftware utilise Get-ItemProperty pour le registre, Get-ChildItem pour les portables/raccourcis, et New-SoftwareApp pour les objets.
🧪 Tests Pester vérifient la détection, le filtrage, et la gestion d’erreurs.
⚙️ Modules requis (PromptHelper, CredentialManager) validés via Get-Module -ListAvailable.
✅ Scan optimisé pour faible CPU/mémoire, compatible avec 10 PC en < 5 min.
📋 Documentation intégrée dans README_UpdatesFaciles.md et ici.

🔧 Prochaines étapes

Passer au Module 4 (Actions/rollback) avec génération de Sources/UpdateProvider.psm1.
Vérifier l’intégration de SoftwareDetection.psm1 dans main.ps1 ou App.xaml.ps1.


Ce journal peut être mis à jour manuellement ou automatiquement selon le système CI utilisé.Il peut aussi être affiché dans une UI interne pour faciliter le suivi par l’équipe projet.

📦 Fichiers associés

README technique
Guide contributeur
Page d’accueil
UpdatesFaciles_Prompt7.txt
