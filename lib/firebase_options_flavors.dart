// lib/firebase_options_flavors.dart
import 'package:firebase_core/firebase_core.dart';
import 'flavors.dart';

class FirebaseOptionsFlavors {
  static FirebaseOptions forWeb() {
    switch (Flavor.name) {
      case 'stg':
        return const FirebaseOptions(
          apiKey:       'COLOQUE_AQUI_STG',
          authDomain:   'COLOQUE_AQUI_STG.firebaseapp.com',
          projectId:    'COLOQUE_AQUI_STG',
          storageBucket:'COLOQUE_AQUI_STG.appspot.com',
          messagingSenderId: '...',
          appId:        '...',
          measurementId:'G-...STG',
        );
      case 'prod':
        return const FirebaseOptions(
          apiKey:       'COLOQUE_AQUI_PROD',
          authDomain:   'COLOQUE_AQUI_PROD.firebaseapp.com',
          projectId:    'COLOQUE_AQUI_PROD',
          storageBucket:'COLOQUE_AQUI_PROD.appspot.com',
          messagingSenderId: '...',
          appId:        '...',
          measurementId:'G-...PROD',
        );
      case 'dev':
      default:
        return const FirebaseOptions(
          apiKey:       'AIzaSyDZh7jcJNO0XEW2eCXecWq3MdTvRFPzHJk',
          authDomain:   'sisgeoderal.firebaseapp.com',
          projectId:    'sisgeoderal',
          storageBucket:'sisgeoderal.appspot.com',
          messagingSenderId: '769410863294',
          appId:        '1:769410863294:web:a51d56dfd32369dd4b0eef',
          measurementId:'G-EJBDWKRPQ8',
        );
    }
  }
}
