// lib/main_dev.dart
import 'flavors.dart';
import 'bootstrap.dart';

void main() {
  Flavor.name = 'dev';
  bootstrapAndRunApp();
}
