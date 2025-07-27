# README_UI.md – Interface graphique UpdatesFaciles

## 🧭 Objectif

Ce fichier décrit le fonctionnement de l’interface graphique WPF du projet UpdatesFaciles, les choix techniques, les limitations et les pistes d’amélioration.

---

## 🖼️ Structure actuelle

- Type de fenêtre : `<Window>` classique
- Chargement XAML via `XamlReader.Load()`
- Icône affichée via `IconBitmapDecoder`
- ViewModel simulé injecté avec 3 logiciels fictifs
- Bouton "Analyser les logiciels" fonctionnel
- Logo ASCII affiché en console

---

## ⚠️ Limitations connues

- `MetroWindow` non compatible avec `XamlReader.Load()` dans PowerShell scripté
- Bloc `pack://application` pour styles MahApps.Metro non fonctionnel
- Pas de `App.xaml` compilé → styles à charger manuellement

---

## 🎨 Pistes d’amélioration

- Créer des fichiers `Styles/Buttons.xaml`, `Styles/Colors.xaml`
- Ajouter des effets visuels (`Hover`, `Focus`)
- Intégrer un système de notification ou journalisation visuelle
- Préparer une migration vers WPF compilé si besoin

---

## 📦 Fichiers liés

- `App.xaml.ps1` : script principal de lancement
- `MainWindow.xaml` : interface utilisateur
- `MainViewModel.ps1` : logique métier simulée
- `Ressources/icon.ico` : icône affichée