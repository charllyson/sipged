// lib/main.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'bootstrap.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Em DEV (web ou não) ainda carregamos o .env antigo.
  // Só evitamos .env em WEB + RELEASE (produção), por causa do 406 no servidor.
  final shouldLoadEnv = !kIsWeb || !kReleaseMode;
  if (shouldLoadEnv) {
    await dotenv.load(fileName: ".env");
  }

  bootstrapAndRunApp();
}
