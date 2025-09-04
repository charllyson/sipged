// lib/main.dart
import 'flavors.dart';
import 'bootstrap.dart';

void main() {
  // Quando executar sem -t main_dev.dart, ainda assim pega o FLAVOR via --dart-define
  Flavor.name = const String.fromEnvironment('FLAVOR', defaultValue: 'dev');
  bootstrapAndRunApp();
}
