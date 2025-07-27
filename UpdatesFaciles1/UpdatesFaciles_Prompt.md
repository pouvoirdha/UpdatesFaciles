🎯 Objectif du projet
Développer, avec l’assistance d’un copilote IA PowerShell, un assistant modulaire de gestion de logiciels (installés, portables, cloud, raccourcis), destiné aux techniciens IT, y compris ceux ne maîtrisant pas le développement. L’outil doit être :

Considère que je suis débutant en PowerShell. Pour chaque suggestion, explique ce qu’il faut installer, vérifie la présence des modules et donne les commandes. Ajoute uniquement des scripts commentés et faciles à recopier. Rappelle-moi le rôle de chaque module, et résume les dépendances et commandes d’installation à la fin de chaque réponse

- Modulaire : chaque fonctionnalité est indépendante et réutilisable
- Documenté : génération automatique des guides utilisateur et développeur
- Sécurisé : respect des normes SI, logs chiffrés, audit, RGPD, gestion des droits
- Accessible : conforme WCAG 2.1, multilingue, clavier, contrastes, lisibilité
- Extensible : architecture ouverte, plugins, personnalisation, API locale
- Testé : chaque module inclut des scénarios reproductibles et validation utilisateur
- Intégrable : compatible CI/CD, supervision, configuration centralisée

⚙️ Règles IA – Consignes d’interprétation
- Inspirations professionnelles : base-toi sur les meilleures pratiques PowerShell pro
- Priorisation fonctionnelle : privilégie les fonctions polyvalentes, adaptables
- Réutilisabilité : fonctions indépendantes et transférables
- Fusion intelligente : harmonise les redondances entre scripts
- Modularité stricte : 1 module = 1 responsabilité
- Documentation automatique : commentaires + génération platyPS
- Réutilisation des modules existants : Chocolatey, PSWindowsUpdate, etc.
- Interaction guidée : validation explicite à chaque étape
- Après toute création UI, proposer automatiquement les améliorations usuelles (journalisation, affichage en tableau, intégration style/theme)

📁 Arborescence du projet
/GestionnaireLogicielsIT/
├── Sources/
├── Models/
├── ViewModels/
├── Views/
├── Actions/
├── Localization/
├── Plugins/
├── Tests/
├── prefs.json
├── logs.txt
├── audit.log
└── main.ps1

🧰 Modèle MVVM
- Model : `[PSCustomObject]`, JSON Schema
- ViewModel : logique métier PowerShell
- View : XAML stylisé MahApps / MaterialDesign

🧩 Objets à créer
- SoftwareApp
- UserPrefs
- LogEntry
- AuditRecord
- Dependency

Chaque classe inclut :
- Structure typée
- Exemple JSON
- JSON Schema
- Mini-guide
- Test Pester

📦 Packaging
- Manifestes PowerShell
- Utilisation de Plaster pour squelettes
- Doc générée via platyPS

🧭 Workflow séquentiel
1. Rappel de l’objectif métier/SI
2. Production complète
3. Intégration au projet
4. Attente de validation explicite

📌 Check-list pour chaque module
| Élément              | Contenu attendu                            |
|----------------------|---------------------------------------------|
| Code complet         | PowerShell/XAML commenté, modulaire         |
| Objets typés         | Classe PowerShell + JSON Schema             |
| Scénario d’usage     | Flux utilisateur complet                    |
| Doc utilisateur      | Markdown + affichable in-app                |
| Doc développeur      | Guide technique, conventions                |
| Tests unitaires      | Pester, mocks, cas typiques                 |
| Dépendances          | Modules requis, erreurs gérées              |
| Sécurité & RGPD      | Signature, droits, secrets, audit           |
| Intégration          | Instructions pour relier aux autres modules |

🧰 Outils standards
- PowerShell 7.x & 5.1+
- .NET ≥ 4.7.2 + WPF
- Plaster, platyPS, Pester v5
- ScriptAnalyzer, PSKoans
- MahApps / MaterialDesign
- JSON Schema
- Import-LocalizedData (.psd1)

Modules à générer :
1. Structure & objets
2. Interface graphique
3. Détection logicielle
4. Actions / rollback
5. Préférences utilisateur
6. Logs & audit
7. Import/export
8. Supervision
9. Sécurité & RGPD
10. Plugins / packaging
11. Tests & documentation
12. Personnalisation

Chaque module inclut :
- Code + UI si applicable
- Objets + JSON Schema
- Doc utilisateur et dev
- Tests unitaires
- Intégration projet
- Validation manuelle

🎬 Commande initiale de lancement
Copilot, commence par générer :
1. La structure du projet (`/GestionnaireLogicielsIT`)
2. L’objet logiciel `[PSCustomObject] SoftwareApp`
3. Le JSON Schema associé
4. La documentation utilisateur/dev
5. Un test Pester basique
6. Les instructions d’intégration à `main.ps1`
Attends ma validation avant de poursuivre.

🧠 Consigne IA complémentaire
> Utilise les standards PowerShell et modules pro existants.
> Réutilise les solutions connues.
> Structure, documente, teste chaque élément.
> Propose des workflows clairs. Valide chaque bloc.

📎 Fragmentation
- Réponses en blocs numérotés si volumineuses
- Résumé + regroupement à la fin
- Indication du point d’intégration

🏷️ Nom de projet
Nom : UpdatesFaciles

🧾 Résumé des rôles de modules
| Module | Fonction |
|--------|----------|
| 1      | Initialise structure et objets |
| 2      | UI graphique et navigation |
| 3      | Détection des applications |
| 4      | Actions (install/update) |
| 5      | Préférences utilisateur |
| 6      | Logs et audit sécurisés |
| 7      | Import/export automatisé |
| 8      | Supervision et état système |
| 9      | Sécurité et conformité SI |
| 10     | Extension, plugins, packaging |
| 11     | Tests automatisés + doc |
| 12     | Personnalisation interface/langue |

🧪 Conditions de validation
- Tests Pester OK
- Doc utilisable
- Objets JSON exploitables
- Sécurité couverte
- UX claire

📎 Regroupement final
- README complet
- Doc utilisateur en markdown
- Manuel développeur
- Structure CI/CD packagée
- UI guide intégré si possible

🎬 Commande type
> “Copilot, relance le projet UpdatesFaciles à partir du module 6 (Logs/Audit), en respectant le prompt complet.”

📘 **Ressources complémentaires**
Le projet contient deux fichiers d’appui :
- `README_UpdatesFaciles.md` : résumé technique du projet, modules, outils, commandes.
- `GuideContributeur.md` : guide à destination des techniciens et développeurs souhaitant participer au projet. Contient les conventions, exigences de qualité, format attendu des modules, style PowerShell.

Ces fichiers peuvent être mis à jour indépendamment du prompt, mais leur contenu est pris en compte dans les relances et validations IA.

🧠 Mise à jour documentaire intelligente
L’assistant IA Copilot est autorisé à :
- Mettre à jour les fichiers Markdown liés au projet :
  - `README_UpdatesFaciles.md`
  - `GuideContributeur.md`
  - `Accueil_UpdatesFaciles.md`
  - `Historique_Modules.md`
- Enrichir, corriger ou compléter les sections concernées après chaque étape validée du projet
- Proposer une nouvelle version du fichier `.md` correspondant en cas de modification majeure, ajout de module, changement de workflow ou extension
- Résumer les modifications dans un bloc clair à la fin du message
- Attendre confirmation utilisateur avant de remplacer le fichier source

Mises à jour intégrées
- Icône affichée via $window.SetValue(...) après correction du chemin Ressources\icon.ico
- ViewModel simulé injecté avec 3 logiciels fictifs (Firefox, 7-Zip, Notepad++)
- Fallback vers <Window> classique dans le XAML (au lieu de MetroWindow)
- Bloc de styles MahApps.Metro désactivé dans le script pour éviter les erreurs
- Logo ASCII intégré dans le script principal (App.xaml.ps1)
- Suggestion future : création de styles locaux (Buttons.xaml, Colors.xaml) pour personnalisation


🤖 IA autonome à relance guidée
- Lorsqu’un module ou script est incomplet ou absent, Copilot :
  - le propose automatiquement,
  - le complète sans attendre une relance explicite,
  - conserve la cohérence du projet en respectant l’architecture existante.

- Copilot utilise un affichage structuré pour :
  - présenter clairement chaque résultat (UI, scripts, doc, tests),
  - expliquer chaque champ visible dans l’interface.

- À chaque relance du projet, Copilot :
  - résume l’état actuel du projet,
  - propose les améliorations UX/UI standards (tri, filtre, style, actions),
  - injecte automatiquement des exemples réalistes (données simulées).

- S’il manque une pièce (module, dossier, fonction, vue, JSON…), Copilot la génère automatiquement, documentée et testable.