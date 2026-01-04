import 'package:flutter_dotenv/flutter_dotenv.dart';

class CesiumKeyService {
  static String get ionToken => dotenv.env["CESIUM_ION_TOKEN"] ?? "";
}
