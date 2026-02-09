// lib/main.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/intl.dart';

import 'bootstrap.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Define locale padrão para NumberFormat/DateFormat
  Intl.defaultLocale = 'pt_BR';

  final shouldLoadEnv = !kIsWeb || !kReleaseMode;
  if (shouldLoadEnv) {
    await dotenv.load(fileName: ".env");
  }

  bootstrapAndRunApp();
}
