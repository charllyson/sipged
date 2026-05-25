import 'dart:typed_data';

import 'package:http/http.dart' as http;

Future<Uint8List> loadImageBytes(String url) async {
  final response = await http.get(Uri.parse(url));

  if (response.statusCode >= 200 && response.statusCode < 300) {
    return response.bodyBytes;
  }

  throw Exception('HTTP ${response.statusCode} ao baixar $url');
}

Future<Uint8List?> tryConvertHeicToJpeg(Uint8List heicBytes) async {
  return null;
}

bool sniffIsHeic(Uint8List bytes) {
  if (bytes.length < 12) return false;

  final box = String.fromCharCodes(bytes.sublist(4, 12)).toLowerCase();

  return box.contains('heic') ||
      box.contains('heix') ||
      box.contains('hevc') ||
      box.contains('heim') ||
      box.contains('heif');
}