import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'homepage.dart';
import 'auth_service.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final AuthService authService = AuthService();

  bool isLoading = false;
  bool areFieldsFilled = false;

  @override
  void initState() {
    super.initState();
    emailController.addListener(updateFieldsStatus);
    passwordController.addListener(updateFieldsStatus);
  }

  @override
  void dispose() {
    emailController.removeListener(updateFieldsStatus);
    passwordController.removeListener(updateFieldsStatus);
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void updateFieldsStatus() {
    setState(() {
      areFieldsFilled = emailController.text.isNotEmpty && passwordController.text.isNotEmpty;
    });
  }

  Future<void> signIn() async {
    debugPrint("=== DÉBUT SIGNIN ===");
    String email = emailController.text.trim();
    String password = passwordController.text.trim();

    debugPrint("Email: $email, Password: ${password.isNotEmpty ? "****" : "(vide)"}");

    setState(() => isLoading = true);

    try {
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password
      );

      debugPrint("=== USER CONNECTÉ ===");
      debugPrint("User UID: ${userCredential.user?.uid}");

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const Homepage()),
        );
      }

    } on FirebaseAuthException catch (e) {
      debugPrint("=== ERREUR FIREBASE === Code: ${e.code}");
      _showError(_getFirebaseErrorMessage(e.code));
    } finally {
      if (mounted) {
        debugPrint("=== FIN SIGNIN ===");
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> signInAnonymously() async {
    debugPrint("=== SIGNIN ANONYME ===");
    setState(() => isLoading = true);

    try {
      User? user = await authService.signInAnonymously();
      if (user != null && mounted) {
        debugPrint("=== USER ANONYME CONNECTÉ: ${user.uid} ===");
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const Homepage()),
        );
      }
    } catch (e) {
      debugPrint("=== ERREUR SIGNIN ANONYME ===");
      _showError("Erreur lors de la connexion anonyme.");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _showError(String message) {
    debugPrint("=== AFFICHAGE ERREUR: $message ===");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  /// Correction: Fonction `_getFirebaseErrorMessage` ajoutée
  String _getFirebaseErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return "Aucun utilisateur trouvé avec cet email.";
      case 'wrong-password':
        return "Mot de passe incorrect.";
      case 'invalid-email':
        return "Email invalide.";
      case 'network-request-failed':
        return "Problème de connexion Internet.";
      case 'too-many-requests':
        return "Trop de tentatives. Réessayez plus tard.";
      default:
        return "Erreur de connexion. Vérifiez vos identifiants.";
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("=== BUILD LOGIN ===");
    return Scaffold(
      appBar: AppBar(title: const Text("Connexion")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: "Email"),
            ),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(labelText: "Mot de passe"),
              obscureText: true,
            ),
            const SizedBox(height: 20),

            isLoading
                ? const CircularProgressIndicator()
                : Column(
                    children: [
                      ElevatedButton(
                        onPressed: areFieldsFilled ? signIn : null, // Disable button if fields are not filled
                        style: ElevatedButton.styleFrom(
                          disabledBackgroundColor: Colors.grey, // Style for disabled button
                        ),
                        child: const Text("Se connecter"),
                      ),
                      ElevatedButton(
                        onPressed: signInAnonymously,
                        child: const Text("Connexion anonyme"),
                      ),
                    ],
                  ),
          ],
        ),
      ),
    );
  }
}
