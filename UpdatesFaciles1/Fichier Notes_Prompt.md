Notes_Prompt.md – Évolution du prompt UpdatesFaciles
Ce fichier regroupe les ajustements, améliorations et consignes ajoutées au prompt principal au fil du projet. Il permet d’adapter le comportement du copilote IA en fonction des erreurs rencontrées, des modules validés et des besoins techniques.

✅ Module 1 – Structure & objets typés
🔧 Problèmes rencontrés
- Conflit entre Pester v3.4.0 (système) et v5.7.1 (utilisateur)
- Encodage des fichiers avec accents empêchant la détection des tests
- Import manuel de Pester causant des boucles de pile
- Fonction non reconnue dans les tests sans dot-sourcing explicite
🧠 Ajustements du prompt
- Ajouter une vérification automatique de la version de Pester
- Proposer des scripts de test allégés en cas d’échec
- Éviter l’import de Pester dans les fichiers .Tests.ps1
- Documenter les erreurs connues dans les notes techniques

📦 Module 2 – Interface WPF
🔧 Problèmes rencontrés
- Type MetroWindow non reconnu sans assembly MahApps.Metro chargé
- MetroWindow échoue à l’instanciation via XamlReader.Load() dans PowerShell
- DataContext inaccessible si l’objet $window est null
- Icône non affichée à cause d’un chemin incorrect (Resources au lieu de Ressources)
- Styles MahApps.Metro non chargés via pack://application dans environnement scripté
✅ Éléments fonctionnels validés
- Fallback vers <Window> classique dans le XAML
- Icône affichée correctement via $window.SetValue(...)
- ViewModel simulé injecté avec 3 logiciels fictifs
- Bouton « Analyser les logiciels » fonctionnel avec MessageBox
- Chargement des DLLs MahApps.Metro via Assembly.LoadFrom
🔧 Améliorations proposées automatiquement
- Ajout d’un DataGrid avec SoftwareApp simulés
- Icône ajoutée avec chemin relatif corrigé
- ViewModel généré en PowerShell et injecté dans ItemsSource
- Action bouton liée à boîte MessageBox + console
- Logo ASCII intégré dans le script principal

🧠 Résilience du Module 2 – UI WPF
- Ajout automatique d’un mécanisme de fallback si MetroWindow échoue
- Log clair si un composant XAML est introuvable
- Suggestion pour enrichir App.xaml.ps1 avec un test de compatibilité MetroWindow
- Bloc de chargement des styles MahApps désactivé ou remplacé par styles locaux

📌 Consignes IA à intégrer
- Toujours vérifier la présence des modules nécessaires avant utilisation
- Préférer des scripts compatibles avec PowerShell ≥ 7.0
- Intégrer des commandes commentées et pédagogiques pour chaque installation
- Proposer une correction autonome ou une modification du prompt en cas d’erreur
- Documenter les ajustements dans ce fichier à chaque module validé
- Après toute création UI, proposer automatiquement les améliorations usuelles (journalisation, affichage en tableau, intégration style/theme)

🧠 Notes techniques – MahApps.Metro dans PowerShell scripté
- MahApps.Metro chargé avec succès via Assembly.LoadFrom
- Type MetroWindow instanciable uniquement dans applications WPF compilées
- Repli automatique vers Window classique si constructeur échoue
- Les styles MahApps.Metro nécessitent souvent un Application.Current.Resources
- Suggestion : migration vers une App.xaml et infrastructure MVVM complète au module 3

🚨 Cas critique : échec XAML MahApps.Metro avec MetroWindow
- MetroWindow échoue à l’instanciation sans App.xaml compilé
- XamlReader.Load() ne suffit pas pour MahApps.Metro dans PowerShell
- Suggestion : fallback vers Window + styles manuels
- Actions : injecter les ResourceDictionary MahApps dynamiquement
- Consigne IA : toujours tester MetroWindow avec un plan B disponible
