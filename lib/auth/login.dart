// lib/auth/login.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_test/pigeon_api.dart';
import '../screens/homepage.dart'; // <--- AJOUTÉ : Importation de Homepage

// Le State reste associé au StatefulWidget
class _LoginState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true; // <--- AJOUTÉ : Pour masquer/afficher le mdp
  final HostApi _hostApi = HostApi();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    print('=== AFFICHAGE ERREUR: $message ===');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } else {
      print("!!! Widget unmounted, cannot show SnackBar for error: $message");
    }
  }

  Future<void> signIn() async {
    final String email = _emailController.text.trim();
    final String password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showError('Veuillez entrer l\'email et le mot de passe.');
      return;
    }

    // Vérifie 'mounted' avant setState pour éviter les erreurs si le widget est retiré pendant une opération
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    print('=== DÉBUT SIGNIN ===');

    try {
      final dynamic result = await _hostApi.signInWithEmailAndPassword(email, password);
      print('>>> Pigeon Result Type: ${result.runtimeType}');
      print('>>> Pigeon Result Value: $result');
      PigeonUserDetails? userDetails;

      // --- Logique de décodage du résultat Pigeon (inchangée) ---
      if (result is PigeonUserDetails) {
        userDetails = result;
        print('>>> Direct UserDetails received.');
      } else if (result is List) {
        if (result.isNotEmpty && result[0] != null) {
          try {
            // Assumant que PigeonUserDetails.decode existe et fonctionne comme prévu
            userDetails = PigeonUserDetails.decode(result[0]!);
            print('>>> Decoded UserDetails from List[0].');
          } catch (decodeError, stackTrace) {
            print('>>> Error decoding result[0]: $decodeError');
            print('>>> Decode StackTrace: $stackTrace');
            _showError('Erreur interne lors du traitement de la réponse.');
          }
        } else {
          print('>>> Pigeon result List was empty or first element was null.');
          _showError('Erreur lors de la connexion: réponse invalide reçue.');
        }
      } else if (result == null) {
        print('>>> Pigeon returned null.');
        _showError('Email ou mot de passe incorrect.');
      } else {
        print('>>> Unexpected Pigeon result format: ${result.runtimeType}');
        _showError('Erreur lors de la connexion: format de réponse inattendu.');
      }
      // --- Fin de la logique de décodage ---


      // --- NAVIGATION SI SUCCÈS ---
      if (userDetails != null) {
        print('>>> Connexion réussie! UID: ${userDetails.uid}, Email: ${userDetails.email}');
        // Vérifie si le widget est toujours monté AVANT de naviguer
        if (mounted) {
          Navigator.of(context).pushReplacement( // Remplace l'écran actuel
            MaterialPageRoute(builder: (context) => const Homepage()),
          );
        }
      }
      // --- FIN NAVIGATION ---

    } on PlatformException catch (e, s) {
      print('>>> PlatformException during signIn call: ${e.code} - ${e.message}');
      print('>>> Stacktrace: $s');
      String errorMessage = e.message ?? 'Une erreur de plateforme est survenue.';
      // Amélioration de la gestion des erreurs communes de Firebase Auth via PlatformException
      if (e.code == 'firebase_auth/invalid-credential' ||
          e.code.contains('ERROR_WRONG_PASSWORD') ||
          e.code.contains('ERROR_USER_NOT_FOUND') ||
          e.code.contains('invalid-credential')) { // Code plus générique parfois utilisé
        errorMessage = 'Email ou mot de passe incorrect.';
      } else if (e.code.contains('network-error') || e.code.contains('network_error')) {
        errorMessage = 'Erreur réseau. Vérifiez votre connexion.';
      }
      _showError(errorMessage);

    } catch (e, s) {
      print('>>> Generic error during signIn call: $e');
      print('>>> Stacktrace: $s');
      _showError('Une erreur inattendue est survenue: $e');

    } finally {
      // Vérifie 'mounted' avant setState
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      print('=== FIN SIGNIN ===');
    }
  }

  @override
  Widget build(BuildContext context) {
    print('=== BUILD LOGIN ===');
    return Scaffold(
      appBar: AppBar(title: const Text('Connexion')),
      body: Center( // Centre le contenu verticalement et horizontalement
        child: SingleChildScrollView( // Permet le défilement si le clavier masque les champs
           padding: const EdgeInsets.all(24.0), // Augmente un peu le padding
           child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch, // Étire les éléments enfants horizontalement
            children: [
              const Text( // Ajout d'un titre
                'Bienvenue !',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email), // Ajout d'une icône
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _passwordController,
                decoration: InputDecoration( // Utilise InputDecoration pour le suffixIcon
                  labelText: 'Mot de passe',
                  prefixIcon: const Icon(Icons.lock), // Ajout d'une icône
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton( // <--- AJOUTÉ : Bouton pour voir/cacher mdp
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
                obscureText: _obscurePassword, // <--- AJOUTÉ : Utilise la variable d'état
              ),
              const SizedBox(height: 30),
              _isLoading
                  ? const Center(child: CircularProgressIndicator()) // Centre l'indicateur
                  : ElevatedButton(
                      style: ElevatedButton.styleFrom( // Style pour un bouton plus large
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        textStyle: const TextStyle(fontSize: 16),
                      ),
                      onPressed: signIn, // Ne pas mettre '()' ici
                      child: const Text('Se connecter'),
                    ),
              // Optionnel: Ajouter un bouton pour l'inscription ou mot de passe oublié
              // const SizedBox(height: 20),
              // TextButton(
              //   onPressed: () { /* Naviguer vers l'écran d'inscription */ },
              //   child: const Text('Pas encore de compte ? S\'inscrire'),
              // ),
            ],
          ),
        ),
      ),
    );
  }
}

// Le StatefulWidget utilise maintenant le nom correct
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginState();
}
