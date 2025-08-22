// File: firebase_options.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform, kIsWeb;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for android - '
              'you can reconfigure this por rodar o FlutterFire CLI novamente.',
        );
      case TargetPlatform.iOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for iOS - '
              'você pode reconfigurar rodando o FlutterFire CLI.',
        );
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macOS - '
              'você pode reconfigurar rodando o FlutterFire CLI.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions não são suportadas para essa plataforma.',
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
