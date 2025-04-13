// lib/auth/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/pigeon_user_details.dart'; // Import the PigeonUserDetails model

class AuthService {
  // --- MODIFICATION ---
  // FirebaseAuth instance, final mais initialisé dans les constructeurs
  final FirebaseAuth _auth;

  // --- AJOUT ---
  // Constructeur principal utilisé par l'application
  AuthService() : _auth = FirebaseAuth.instance;

  // --- AJOUT ---
  // Constructeur pour l'injection de dépendance dans les tests
  @visibleForTesting
  AuthService.test(this._auth);

  // Stream pour suivre les changements d'état de l'authentification
  // Utilise maintenant la variable d'instance _auth
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Connexion anonyme
  // Utilise maintenant la variable d'instance _auth
  Future<PigeonUserDetails?> signInAnonymously() async {
    try {
      UserCredential userCredential = await _auth.signInAnonymously();
      debugPrint('=== SIGNIN ANONYME ===');
      if (userCredential.user != null) {
        return PigeonUserDetails(uid: userCredential.user!.uid);
      } else {
        return null;
      }
    } catch (e) {
      debugPrint("Erreur lors de la connexion anonyme : $e");
      return null;
    }
  }

  // Connexion avec email et mot de passe
  // Utilise maintenant la variable d'instance _auth
  Future<PigeonUserDetails?> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      debugPrint('=== SIGNIN EMAIL ===');
      if (userCredential.user != null) {
        return PigeonUserDetails(uid: userCredential.user!.uid);
      } else {
        return null;
      }
    } on FirebaseAuthException catch (e) {
      debugPrint("Erreur lors de la connexion avec email : ${e.code}");
      throw e; // Re-throw the exception
    } catch (e) {
      debugPrint("Erreur lors de la connexion avec email : $e");
      throw e; // Re-throw the exception
    }
  }

  // --- AJOUT ---
  // Méthode pour créer un nouvel utilisateur (Inscription)
  // Miroir de signIn, mais appelle createUserWithEmailAndPassword
  // Retourne PigeonUserDetails? pour rester cohérent avec les autres méthodes
  Future<PigeonUserDetails?> signUpWithEmailAndPassword(
      String email, String password) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      debugPrint('=== SIGNUP EMAIL ===');
      if (userCredential.user != null) {
        return PigeonUserDetails(uid: userCredential.user!.uid);
      } else {
        return null;
      }
    } on FirebaseAuthException catch (e) {
      debugPrint("Erreur lors de l'inscription avec email : ${e.code}");
      throw e; // Re-throw the exception
    } catch (e) {
      debugPrint("Erreur lors de l'inscription avec email : $e");
      throw e; // Re-throw the exception
    }
  }


  // Méthode pour se déconnecter
  // Utilise maintenant la variable d'instance _auth
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      debugPrint('=== SIGNOUT ===');
    } on FirebaseAuthException catch (e) {
      debugPrint('Erreur lors de la déconnexion: ${e.code}');
      // Gérer les erreurs ici
    }
  }

  // Récupérer l'utilisateur actuel (peut être null si non connecté) - Getter existant
  // Utilise maintenant la variable d'instance _auth
  User? get currentUser => _auth.currentUser;

  // --- AJOUT ---
  // Méthode pour récupérer l'utilisateur actuel (pour correspondre à l'appel du test)
  // Retourne simplement le getter currentUser
  User? getCurrentUser() {
    return currentUser;
  }
}
