import 'package:firebase_core/firebase_core.dart';

class FirebaseOptionsFlavors {
  const FirebaseOptionsFlavors._();

  /// Chave pública Web Push / VAPID.
  ///
  /// Firebase Console:
  /// Project Settings > Cloud Messaging > Web Push certificates.
  static const String webPushVapidKey = String.fromEnvironment(
    'WEB_PUSH_VAPID_KEY',
    defaultValue: '',
  );

  static FirebaseOptions forWeb() {
    return const FirebaseOptions(
      apiKey: 'AIzaSyDZh7jcJNO0XEW2eCXecWq3MdTvRFPzHJk',
      authDomain: 'sisgeoderal.firebaseapp.com',
      projectId: 'sisgeoderal',
      storageBucket: 'sisgeoderal.appspot.com',
      messagingSenderId: '769410863294',
      appId: '1:769410863294:web:a51d56dfd32369dd4b0eef',
      measurementId: 'G-EJBDWKRPQ8',
    );
  }
}