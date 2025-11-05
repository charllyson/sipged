import 'package:firebase_core/firebase_core.dart';
import 'flavors.dart';

class FirebaseOptionsFlavors {
  /// Compatibilidade com build-time (FLAVOR), se você ainda usar.
  static FirebaseOptions forWeb() => forWebByFlavor(Flavor.name);

  /// Retorna as opções do Firebase para cada tenant/flavor.
  static FirebaseOptions forWebByFlavor(String flavor) {
    switch (flavor) {
      case 'dnitro':
        return const FirebaseOptions(
          apiKey: "AIzaSyBkM3xNHyL3aglqqTvKp8oVCn2cpaMRN6Q",
          authDomain: "dnitro-10930.firebaseapp.com",
          projectId: "dnitro-10930",
          storageBucket: "dnitro-10930.appspot.com", // ✅ CORRETO
          messagingSenderId: "1082794997619",
          appId: "1:1082794997619:web:0a5f4524ea1d02c7e3f706",
          measurementId: "G-GN7022MXZ2",
        );

      case 'amprecatorios':
        return const FirebaseOptions(
          apiKey: "AIzaSyAY3EIQVdughSK8CBKOUVtr4fKhi4TMdGU",
          authDomain: "meloemonte.firebaseapp.com",
          projectId: "meloemonte",
          storageBucket: "meloemonte.firebasestorage.app",
          messagingSenderId: "572384566535",
          appId: "1:572384566535:web:8543604bcbc69b905db9a2",
          measurementId: "G-TKX4SV3BNH"
        );

      case 'der':
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
