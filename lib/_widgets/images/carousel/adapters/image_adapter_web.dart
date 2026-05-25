import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:typed_data';

import 'package:sipged/_widgets/images/carousel/adapters/heic_web_convert.dart';
import 'package:sipged/_widgets/images/carousel/adapters/web_fetch_bytes.dart';

Future<Uint8List> loadImageBytes(String url) {
  return fetchBytesWeb(url);
}

Future<Uint8List?> tryConvertHeicToJpeg(Uint8List heicBytes) async {
  final hasHeic2AnyJs = globalContext.hasProperty('heic2any'.toJS);
  final hasHeic2Any = hasHeic2AnyJs.toDart;

  if (!hasHeic2Any) return null;

  final jpg = await convertHeicBytesToJpegWeb(heicBytes);

  if (jpg.length >= 2 && jpg[0] == 0xFF && jpg[1] == 0xD8) {
    return jpg;
  }

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