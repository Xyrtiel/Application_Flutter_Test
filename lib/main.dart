import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import './config/firebase_options.dart';
// import './screens/splash_screen.dart'; // SplashScreen n'est plus utilisé si Wrapper est home
import './config/theme_provider.dart';
import './auth/auth_service.dart';
import './auth/wrapper.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
// import './config/app_config.dart'; // Pas nécessaire pour charger les secrets via dotenv

// 2. Rendre la fonction main async
Future<void> main() async {
  // 3. Assurer l'initialisation des bindings Flutter
  WidgetsFlutterBinding.ensureInitialized();

  // 4. Charger les variables d'environnement depuis le fichier .env
  try {
    await dotenv.load(fileName: ".env");
    print(".env file loaded successfully."); // Confirmation
  } catch (e) {
    // Gérer l'erreur si le fichier .env ne peut pas être chargé
    print("ERREUR critique lors du chargement du fichier .env: $e");
    // Vous pourriez vouloir arrêter l'application ici ou utiliser des valeurs par défaut
    // si le chargement échoue, mais la classe Secrets lèvera une erreur plus tard
    // si les clés spécifiques sont manquantes.
  }

  // Initialisation de Firebase (code existant)
  try {
    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);
    print("Firebase Initialized");
    await FirebaseAppCheck.instance.activate(
      androidProvider: AndroidProvider.playIntegrity,
      appleProvider: AppleProvider.appAttest,
    );
     print("Firebase App Check activated.");
  } catch (e) {
    print("Firebase initialization/AppCheck error: $e");
  }

  // Lancement de l'application (code existant)
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        Provider<AuthService>(create: (_) => AuthService()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          themeMode: themeProvider.themeMode,
          theme: ThemeData.light(),
          darkTheme: ThemeData.dark(),
          home: const Wrapper(),
        );
      },
    );
  }
}
