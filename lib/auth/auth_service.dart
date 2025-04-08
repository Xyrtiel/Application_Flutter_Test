import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/pigeon_user_details.dart'; // Import the PigeonUserDetails model

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Stream pour suivre les changements d'état de l'authentification
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Connexion anonyme
  Future<PigeonUserDetails?> signInAnonymously() async {
    try {
      UserCredential userCredential = await _auth.signInAnonymously();
      debugPrint('=== SIGNIN ANONYME ===');
      // Create a PigeonUserDetails object
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

  // Méthode pour se déconnecter
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      debugPrint('=== SIGNOUT ===');
    } on FirebaseAuthException catch (e) {
      debugPrint('Erreur lors de la déconnexion: ${e.code}');
      // Gérer les erreurs ici
    }
  }

  // Récupérer l'utilisateur actuel (peut être null si non connecté)
  User? get currentUser => _auth.currentUser;
}
