// Só será compilado no web
// ignore: avoid_web_libraries_in_flutter
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:typed_data';

import 'web_fetch_bytes.dart' show fetchBytesWeb;                // você já tem
import 'heic_web_convert.dart' show convertHeicBytesToJpegWeb;   // você já tem

Future<Uint8List> loadImageBytes(String url) => fetchBytesWeb(url);

Future<Uint8List?> tryConvertHeicToJpeg(Uint8List heicBytes) async {
  // globalContext ~ globalThis
  final hasHeic2AnyJs = globalContext.hasProperty('heic2any'.toJS);
  final hasHeic2Any = hasHeic2AnyJs.toDart;

  if (!hasHeic2Any) return null;

  final jpg = await convertHeicBytesToJpegWeb(heicBytes);

  // checa SOI JPEG
  if (jpg.length >= 2 && jpg[0] == 0xFF && jpg[1] == 0xD8) return jpg;
  return null;
}

bool sniffIsHeic(Uint8List bytes) {
  if (bytes.isEmpty) return false;

  final isPng = bytes.length > 4 && bytes[0] == 0x89 && bytes[1] == 0x50;
  final isJpg = bytes.length > 2 && bytes[0] == 0xFF && bytes[1] == 0xD8;
  final isWebp = bytes.length > 12 &&
      bytes[0] == 0x52 && bytes[1] == 0x49 && bytes[2] == 0x46 && bytes[3] == 0x46 &&
      bytes[8] == 0x57 && bytes[9] == 0x45 && bytes[10] == 0x42 && bytes[11] == 0x50;

  return !(isPng || isJpg || isWebp);
}
