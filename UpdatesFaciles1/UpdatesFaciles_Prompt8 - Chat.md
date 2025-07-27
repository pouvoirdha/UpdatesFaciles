# Objectifs et Structure Générale

## Instructions de Transition

Si l’IA a déjà travaillé sur une version précédente du prompt pour UpdatesFaciles, elle doit :
- Vérifier les artefacts existants (scripts, documentation, tests) et les adapter aux nouvelles exigences (ex. : support débutants, scripts d’installation/diagnostic, conventions PowerShell).
- Prioriser les instructions de ce prompt en cas de conflit ou d’ambiguïté avec l’ancien.
- Signaler tout conflit potentiel (ex. : module existant non conforme) dans ses réponses.

## Diagnostic Intelligent

- **Test-UpdatesFaciles.ps1** :
  - Inclure une auto-vérification des erreurs courantes (modules bloqués, DLL manquantes, prompts interactifs) et proposer une correction ou guidance directement dans l’affichage.
- **Tests Unitaires** :
  - S’assurer que tous les paramètres obligatoires sont passés explicitement.
  - Éviter les appels interactifs en encadrant les tests avec des blocs et variables locales.
  - Vérifier que tous les blocs Describe et It sont correctement fermés.
  - Assurer que les cmdlets personnalisées ne déclenchent pas d’interaction manuelle.
  - Maintenir l’exécution silencieuse, reproductible, et utilisable en CI.
- **Appels aux cmdlets personnalisées** :
  - Encapsuler tout dans des blocs try/catch.
  - Vérifier leur disponibilité avec Get-Command pour éviter les invites interactives liées aux paramètres obligatoires non résolus.
- **Blocs de test manuel** :
  - Encapsuler par une condition InvocationName + ExpectingInput pour éviter toute exécution pendant les tests unitaires ou l’importation d’un module.

## Validation et Documentation

- **Validation manuelle** :
  - Utiliser $validSources / $validStates en tableau plutôt que ValidateSet pour permettre les fallbacks souples tout en gardant la robustesse.
- **Documentation intégrée** :
  - Utiliser Write-Host au chargement pour traçabilité.
  - Préparer l’ajout de Get-Help et .EXAMPLE dans les versions futures.

# RÉSUMÉ EXPRESS – Corrections PowerShell/Batch & WPF

## Fonctions PowerShell
- Toujours définir ou importer les fonctions (ex : Write-PromptLogo) avant de les utiliser.
- Si une fonction d’un autre script est appelée, charger le module .psm1 avant (Import-Module).

## Export-ModuleMember
- À utiliser seulement dans un module .psm1 (jamais dans un .ps1).
- En cas d’erreur, supprimer la ligne ou renommer le fichier en .psm1.

## Paramètres en Double
- Dans un param() ou une fonction, utiliser un même nom de paramètre qu’une seule fois (typiquement $Debug).

## Diagramme Diagnostic
- Projet globalement correct.
- Exception fréquente : ressources UI manquantes (Views\MainWindow.xaml, Ressources, DLL MahApps.Metro).
- Lancer le script avec -FixIssues pour tenter l’auto-réparation, sinon remettre les fichiers/dossiers manuellement.

## XAML + PowerShell
- Supprimer l’attribut x:Class du XAML.
- Corriger les chemins « pack://... » vers des chemins réels si pas de compilation .NET.
- Un seul x:Name par contrôle dans le XAML.
- Tous les événements mentionnés dans le XAML doivent avoir une fonction correspondante dans le script PowerShell.

## Bonnes Pratiques
- Charger modules/fonctions avant leur première utilisation.
- Utiliser .psm1 + Export-ModuleMember pour les partages.
- Pas besoin d’Export-ModuleMember pour les scripts .ps1 purs.
- Toujours vérifier la présence physique des fichiers (xaml, icônes, DLL, etc.).
- Préciser le chemin pour chaque fichier. Si de nouveaux dossiers doivent être créés, les ajouter explicitement pour faire évoluer le script d’installation.
