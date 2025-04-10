// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'config/firebase_options.dart';
import 'auth/wrapper.dart';
import 'auth/auth_service.dart';
// *** AJOUTE L'IMPORT SI NÉCESSAIRE ***
import 'config/theme_provider.dart'; // Assure-toi que ce chemin est correct

void main() async {
  // Assure que les bindings Flutter sont prêts avant les opérations async
  WidgetsFlutterBinding.ensureInitialized();

  // Charge les variables d'environnement depuis .env
  try {
    await dotenv.load(fileName: ".env");
    print(".env chargé avec succès."); // Message de confirmation
  } catch (e) {
    print("Erreur lors du chargement du fichier .env: $e");
  }

  // Initialise Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print("Firebase initialisé avec succès."); // Message de confirmation
    // AppCheck n'est pas dans ce snippet, mais était dans ton code précédent. Ajoute-le si nécessaire.
    // await FirebaseAppCheck.instance.activate(...)
  } catch (e) {
    print("Erreur lors de l'initialisation de Firebase: $e");
  }

  // Initialise les données de formatage pour la locale française
  try {
    await initializeDateFormatting('fr_FR', null);
    print("Formatage de date pour 'fr_FR' initialisé."); // Message de confirmation
  } catch (e) {
     print("Erreur lors de l'initialisation du formatage de date: $e");
  }

  // Utilise MultiProvider si tu as plusieurs providers (comme ThemeProvider)
  runApp(
    MultiProvider(
      providers: [
        Provider<AuthService>(create: (_) => AuthService()),
        // *** CORRECTION ICI : DÉCOMMENTE CETTE LIGNE ***
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // *** ASSURE-TOI QUE CE CODE UTILISE BIEN ThemeProvider MAINTENANT ***
    // Si tu veux que ton thème change dynamiquement, utilise Consumer
    return Consumer<ThemeProvider>( // Utilise Consumer pour écouter les changements de thème
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'Flutter Trello App',
          themeMode: themeProvider.themeMode, // Applique le mode de thème
          theme: ThemeData( // Thème clair
             colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple, brightness: Brightness.light),
             useMaterial3: true,
          ),
          darkTheme: ThemeData( // Thème sombre
             colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple, brightness: Brightness.dark),
             useMaterial3: true,
          ),
          home: const Wrapper(),
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}
