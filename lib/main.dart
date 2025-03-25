import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'splash_screen.dart';
import 'theme_provider.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:path/path.dart' as path;

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  try {
    Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    print("Firebase Initialized");
  } catch (e) {
    print("Firebase initialization error: $e");
  }

  runApp(
    MultiProvider(
      providers: [
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
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          themeMode: themeProvider.themeMode,
          theme: ThemeData.light(),
          darkTheme: ThemeData.dark(),
          home: const SplashScreen(),
        );
      },
    );
  }
}
