// lib/main_prod.dart
import 'flavors.dart';
import 'bootstrap.dart';

void main() {
  Flavor.name = 'prod';
  bootstrapAndRunApp();
}
