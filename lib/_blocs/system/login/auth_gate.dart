import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:sisged/_blocs/system/login/splash_page.dart';

/// Gate simples: mostra Splash até receber o PRIMEIRO evento do authStateChanges()
class AuthGate extends StatelessWidget {
  final Widget signedIn;
  final Widget signedOut;

  const AuthGate({super.key, required this.signedIn, required this.signedOut});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges().distinct(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const SplashPage();
        }
        final user = snap.data;
        if (user == null) return signedOut;
        return signedIn;
      },
    );
  }
}