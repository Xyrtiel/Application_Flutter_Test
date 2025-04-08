import 'package:pigeon/pigeon.dart';

// Configure Pigeon pour générer le code Kotlin
@ConfigurePigeon(PigeonOptions(
  dartOut: 'lib/pigeon_api.dart', // Chemin du fichier Dart généré
  // dartTestOut: 'test/pigeon_test.dart', // Optionnel pour les tests
  // CORRECTION ICI : Supprimer le '/' initial
  kotlinOut: 'android/app/src/main/kotlin/com/example/flutter_application_test/PigeonApi.kt', // Chemin du fichier Kotlin généré
  kotlinOptions: KotlinOptions(
    package: 'com.example.flutter_application_test', // Package Kotlin
  ),
))

// Définition de la classe de données à échanger
class PigeonUserDetails {
  String? uid; // Utilise String? pour permettre null si besoin
  String? email; // Ajoute le champ email
}

// Définition de l'API exposée par la plateforme native (Android/iOS)
@HostApi()
abstract class HostApi {
  // Méthode pour se connecter
  // Note: Pigeon gère les async/await et les erreurs automatiquement
  @async
  PigeonUserDetails? signInWithEmailAndPassword(String email, String password);

  // Ajoute d'autres méthodes si nécessaire (ex: signOut, signInAnonymously)
  // @async
  // void signOut();
  // @async
  // PigeonUserDetails? signInAnonymously();
}

// Tu peux aussi définir une @FlutterApi si le natif doit appeler Dart
