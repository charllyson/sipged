import 'dart:typed_data';

Future<Uint8List> loadImageBytes(String url) {
  throw UnimplementedError('loadImageBytes não implementado nesta plataforma.');
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