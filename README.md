# 🚀 Flutter Trello Clone Project

[![Flutter Version](https://img.shields.io/badge/Flutter-%3E%3D3.x.x-blue)](https://flutter.dev)
[![Dart Version](https://img.shields.io/badge/Dart-%3E%3D3.2.3-blue)](https://dart.dev)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## 📝 Description

Ce projet est une application Flutter développée dans le cadre d'un projet étudiant (T-DEV-600). L'objectif est de recréer certaines des fonctionnalités clés de Trello, en mettant l'accent sur les opérations CRUD pour les éléments principaux (workspaces, boards, lists, cards), ainsi que sur une expérience utilisateur et une interface soignées, tout en respectant les bonnes pratiques de développement et de test.

L'application utilise Firebase pour l'authentification et potentiellement Firestore pour la persistance des données utilisateur, et interagit avec l'API REST de Trello pour certaines fonctionnalités spécifiques.

## ✨ Fonctionnalités Principales

*   **Authentification :**
    *   Connexion via Email/Mot de passe (Firebase Auth)
    *   Connexion Anonyme (Firebase Auth)
    *   Gestion de l'état de connexion via Provider.
*   **Gestion Trello (CRUD) :**
    *   ✅ Création, Lecture, Mise à jour, Suppression des **Workspaces** (Espaces de travail).
    *   ✅ Création, Lecture, Mise à jour, Suppression des **Boards** (Tableaux).
    *   ✅ Création, Lecture, Mise à jour, Suppression des **Lists** (Listes).
    *   ✅ Création, Lecture, Mise à jour, Suppression des **Cards** (Cartes).
*   **Fonctionnalités Avancées Trello :**
    *   ❓ Création de tableaux à partir de **Templates** (via API Trello `idBoardSource`). *(Vérifier l'implémentation complète)*
    *   ❓ **Assignation** de membres Trello à des cartes (via API Trello `idMembers`). *(Vérifier l'implémentation complète)*
*   **UI/UX :**
    *   Respect des guidelines Material Design.
    *   Identité visuelle cohérente (thème clair/sombre, couleurs, typographie).
    *   Interface utilisateur conçue pour une expérience agréable.
*   **Autres :**
    *   Intégration d'un calendrier (`table_calendar`).
    *   Notifications locales (`flutter_local_notifications`).

## 🛠️ Tech Stack & Dépendances Clés

*   **Langage :** Dart
*   **Framework :** Flutter
*   **Authentification :** Firebase Authentication
*   **Base de données (potentielle) :** Cloud Firestore
*   **Gestion d'état :** Provider
*   **Configuration :** flutter_dotenv
*   **Réseau (API Trello) :** http
*   **UI & Utilitaires :**
    *   intl (Internationalisation/Formatage)
    *   table_calendar
    *   flutter_local_notifications
    *   timezone
    *   cupertino_icons
*   **Tests :**
    *   flutter_test
    *   mockito
    *   build_runner
*   **Linting :** flutter_lints

## 🚀 Démarrage Rapide

### Prérequis

*   Flutter SDK (Version compatible avec `sdk: '>=3.2.3 <4.0.0'`)
*   Git
*   Un IDE (VS Code, Android Studio...)
*   Un compte Trello pour obtenir une clé API et un token.
*   Un projet Firebase configuré pour l'authentification (et Firestore si utilisé).

### Installation

1.  **Cloner le dépôt :**
    ```bash
    git clone <URL_DU_DEPOT>
    cd flutter_application_test
    ```
2.  **Installer les dépendances :**
    ```bash
    flutter pub get
    ```

### Configuration

1.  **Firebase :**
    *   Suis les instructions de Firebase pour ajouter Flutter à ton projet Firebase.
    *   Télécharge les fichiers de configuration :
        *   `google-services.json` pour Android (à placer dans `android/app/`)
        *   `GoogleService-Info.plist` pour iOS (à placer dans `ios/Runner/` via Xcode)
    *   Assure-toi d'activer les méthodes d'authentification nécessaires (Email/Password, Anonyme) dans la console Firebase.
    *   **Important :** Ajoute ces fichiers de configuration Firebase à ton `.gitignore` pour ne pas les versionner.

2.  **API Trello & Secrets :**
    *   Crée un fichier nommé `.env` à la racine du projet (`flutter_application_test/.env`).
    *   Ajoute tes clés Trello dans ce fichier :
        ```dotenv
        TRELLO_API_KEY=VOTRE_CLE_API_TRELLO
        TRELLO_TOKEN=VOTRE_TOKEN_TRELLO
        ```
        *(Comment obtenir une clé API et un token Trello : Trello Developer Docs)*
    *   **Important :** Assure-toi que le fichier `.env` est bien listé dans ton `.gitignore` pour ne pas exposer tes secrets.

### Lancer l'application

Connectez un appareil ou lancez un émulateur/simulateur, puis exécute :

```bash
flutter run
```
