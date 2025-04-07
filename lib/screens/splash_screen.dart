import 'package:flutter/material.dart';
import '../auth/wrapper.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Simulate some initialization work
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.of(context)
          .pushReplacement(MaterialPageRoute(builder: (_) => const Wrapper()));
    });

    return const Scaffold(
      backgroundColor: Colors.blueAccent,
      body: Center(
        child: Text("Loading...",
            style: TextStyle(color: Colors.white, fontSize: 24)),
      ),
    );
  }
}
