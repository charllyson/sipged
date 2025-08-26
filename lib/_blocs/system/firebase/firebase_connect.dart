import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform, kIsWeb;

/// Wrapper manual de opções do Firebase por plataforma.
/// ⚠️ Idealmente, substitua por `firebase_options.dart` gerado pelo `flutterfire configure`.
class DefaultFirebaseOptions {
  /// Retorna as opções da plataforma atual.
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      // Preencha `android` e retorne aqui.
      // return android;
        throw UnsupportedError(
          'FirebaseOptions não configurado para Android. '
              'Preencha os campos em `android` abaixo ou gere pelo FlutterFire CLI.',
        );

      case TargetPlatform.iOS:
      // Preencha `ios` e retorne aqui.
      // return ios;
        throw UnsupportedError(
          'FirebaseOptions não configurado para iOS. '
              'Preencha os campos em `ios` abaixo ou gere pelo FlutterFire CLI.',
        );

      case TargetPlatform.macOS:
      // Preencha `macos` e retorne aqui.
      // return macos;
        throw UnsupportedError(
          'FirebaseOptions não configurado para macOS. '
              'Preencha os campos em `macos` abaixo ou gere pelo FlutterFire CLI.',
        );

      case TargetPlatform.windows:
      // Preencha `windows` e retorne aqui.
      // return windows;
        throw UnsupportedError(
          'FirebaseOptions não configurado para Windows. '
              'Preencha os campos em `windows` abaixo ou gere pelo FlutterFire CLI.',
        );

      case TargetPlatform.linux:
      // Preencha `linux` e retorne aqui.
      // return linux;
        throw UnsupportedError(
          'FirebaseOptions não configurado para Linux. '
              'Preencha os campos em `linux` abaixo ou gere pelo FlutterFire CLI.',
        );

      default:
        throw UnsupportedError(
          'Plataforma não suportada para FirebaseOptions.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: "AIzaSyAEnqNIkEefhaumkiRKrm-lxjTF_cpmiDY",
    authDomain: "medic-bc913.firebaseapp.com",
    projectId: "medic-bc913",
    storageBucket: "medic-bc913.appspot.com",
    messagingSenderId: "855464885227",
    appId: "1:855464885227:web:387a2a609347859d0df7ae",
    measurementId: "G-83ZFJRY0E9",
  );
}
