// lib/auth/login.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_test/pigeon_api.dart';

// Le State reste associé au StatefulWidget
class _LoginState extends State<LoginScreen> { // <--- MODIFIÉ ICI
  // ... (le reste du code de _LoginState reste identique) ...
   final TextEditingController _emailController = TextEditingController();
   final TextEditingController _passwordController = TextEditingController();
   bool _isLoading = false;
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

        if (result is PigeonUserDetails) {
          userDetails = result;
          print('>>> Direct UserDetails received.');
        }
        else if (result is List) {
          if (result.isNotEmpty && result[0] != null) {
            try {
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
        }
        else if (result == null) {
           print('>>> Pigeon returned null.');
           _showError('Email ou mot de passe incorrect.');
        }
        else {
          print('>>> Unexpected Pigeon result format: ${result.runtimeType}');
          _showError('Erreur lors de la connexion: format de réponse inattendu.');
        }

        if (userDetails != null) {
           print('>>> Connexion réussie! UID: ${userDetails.uid}, Email: ${userDetails.email}');
        }

      } on PlatformException catch (e, s) {
        print('>>> PlatformException during signIn call: ${e.code} - ${e.message}');
        print('>>> Stacktrace: $s');
        String errorMessage = e.message ?? 'Une erreur de plateforme est survenue.';
        if (e.code == 'firebase_auth/invalid-credential' || e.code.contains('ERROR_WRONG_PASSWORD') || e.code.contains('ERROR_USER_NOT_FOUND')) {
           errorMessage = 'Email ou mot de passe incorrect.';
        } else if (e.code.contains('network-error')) {
           errorMessage = 'Erreur réseau. Vérifiez votre connexion.';
        }
        _showError(errorMessage);

      } catch (e, s) {
        print('>>> Generic error during signIn call: $e');
        print('>>> Stacktrace: $s');
        _showError('Une erreur inattendue est survenue: $e');

      } finally {
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
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Mot de passe'),
                obscureText: true,
              ),
              const SizedBox(height: 20),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: signIn,
                      child: const Text('Se connecter'),
                    ),
            ],
          ),
        ),
      );
    }
}

// Le StatefulWidget utilise maintenant le nom correct
class LoginScreen extends StatefulWidget { // <--- MODIFIÉ ICI
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginState(); // <--- MODIFIÉ ICI
}
