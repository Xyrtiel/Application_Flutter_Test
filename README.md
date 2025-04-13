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

## 📂 Structure du Projet (Simplifiée)

