# UpdatesFaciles – Assistant PowerShell modulaire

## 🎯 Objectif

Développer un assistant modulaire pour la gestion des logiciels (installés, portables, cloud, raccourcis) destiné aux techniciens IT, y compris débutants. L’outil doit être :

- Modulaire et réutilisable
- Documenté automatiquement
- Sécurisé (logs, audit, RGPD)
- Accessible (WCAG 2.1)
- Extensible (plugins, API locale)
- Testé et validé
- Intégrable (CI/CD)

## 🧰 Architecture technique

- Architecture MVVM
- UI en XAML (`<Window>` fallback depuis `<MetroWindow>`)
- Icône affichée via PowerShell (`SetValue(...)`)
- ViewModel simulé injecté (3 logiciels fictifs)
- Bloc MahApps.Metro désactivé dans PowerShell (non compatible `pack://application`)
- Objets typés avec JSON Schema

---

## 📦 Modules fonctionnels

| Numéro | Module                  | Rôle                                                       | Statut      |
|--------|-------------------------|-------------------------------------------------------------|-------------|
| 1      | Structure                | Initialisation du projet et objets typés                   | ✅ Validé    |
| 2      | Interface graphique      | UI WPF accessible et personnalisable                       | ✅ Validé    |
| 3      | Détection logicielle     | Scan des logiciels installés, portables, raccourcis        | ⏳ À venir   |
| 4      | Actions / rollback       | Installation, mise à jour, suppression                     | ⏳ À venir   |
| 5      | Préférences utilisateur  | Configuration, langues, raccourcis                         | ⏳ À venir   |
| 6      | Logs et audit            | Journalisation sécurisée, analyse                          | ⏳ À venir   |

---

## ⚙️ Outils standards

| Outil              | Rôle                                 | Version recommandée |
|--------------------|--------------------------------------|----------------------|
| PowerShell         | Langage principal                    | ≥ 7.0 (fallback 5.1) |
| Pester             | Tests unitaires                      | ≥ 5.7.1              |
| Plaster            | Génération de structure              | ≥ 1.1.3              |
| MahApps.Metro      | Interface graphique WPF              | ≥ 2.4.7 (DLLs chargées uniquement) |
| JSON Schema        | Validation des objets logiciels      | Draft 2020-12        |
| CredentialManager  | Sécurité des identifiants            | Intégré              |

---

## 🧪 Validation par module

Un module est considéré comme valide si :

- ✅ Tests Pester réussis
- 📝 Documentation générée
- 🔐 Sécurité couverte
- 📁 Objets JSON valides
- 👤 Utilisable sans connaissance dev
- 🧩 UI fonctionnelle si applicable

---

## 📘 Mise à jour documentaire intelligente

L’assistant IA Copilot est autorisé à :

- Mettre à jour automatiquement les fichiers Markdown du projet :
  - `README_UpdatesFaciles.md`
  - `GuideContributeur.md`
  - `Accueil_UpdatesFaciles.md`
  - `Historique_Modules.md`
- Proposer une version enrichie après chaque validation
- Attendre confirmation avant remplacement

---

## 🚀 Commandes Copilot

### Lancement initial

> Copilot, commence par générer :
> 1. La structure du projet
> 2. L’objet logiciel `SoftwareApp`
> 3. Le schéma JSON associé
> 4. La documentation
> 5. Les tests Pester
> 6. L’intégration dans `main.ps1`

### Relance ciblée

> Copilot, relance le projet UpdatesFaciles à partir du module 7 (Import/export), en respectant le prompt complet.

---

## 🔗 Liens utiles

- [Page d’accueil](./Accueil_UpdatesFaciles.md)
- [README technique](./README_UpdatesFaciles.md)
- [Guide contributeur](./GuideContributeur.md)
- [Historique des modules](./Historique_Modules.md)
- [UpdatesFaciles_Prompt](./UpdatesFaciles_Prompt.md)

Dernière étape : Module 3, scan enrichi à finaliser