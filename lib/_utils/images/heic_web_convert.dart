// lib/_utils/heic_web_convert.dart
import 'dart:typed_data';
import 'dart:html' as html;           // web only
import 'dart:js_util' as jsu;
import 'package:flutter/foundation.dart' show kIsWeb;

/// Converte HEIC -> JPEG no Web usando window.heic2any.
/// Requer <script heic2any> antes do main.dart.js.
Future<Uint8List> convertHeicBytesToJpegWeb(Uint8List heicBytes) async {
  if (!kIsWeb) return heicBytes;

  final win = html.window;
  if (!jsu.hasProperty(win, 'heic2any')) {
    // heic2any não carregado -> devolve os bytes originais (HEIC)
    return heicBytes;
  }

  try {
    final heicBlob = html.Blob([heicBytes], 'image/heic');

    final dynamic raw = await jsu.promiseToFuture(
      jsu.callMethod(win, 'heic2any', [
        {'blob': heicBlob, 'toType': 'image/jpeg', 'quality': 0.92}
      ]),
    );

    final arrayBuffer = await _toArrayBuffer(raw);
    return Uint8List.view(arrayBuffer);
  } catch (_) {
    // Se falhar, devolve os bytes originais (HEIC) para o caller decidir o que fazer
    return heicBytes;
  }
}

Future<ByteBuffer> _toArrayBuffer(dynamic value) async {
  if (jsu.hasProperty(value, 'length')) {
    final len = jsu.getProperty(value, 'length') as int;
    if (len > 0) value = jsu.getProperty(value, '0');
  }
  if (value is ByteBuffer) return value;

  if (jsu.hasProperty(value, 'buffer')) {
    final buf = jsu.getProperty(value, 'buffer');
    if (buf is ByteBuffer) return buf;
  }
  if (jsu.hasProperty(value, 'arrayBuffer')) {
    final dynamic ab = await jsu.promiseToFuture(
      jsu.callMethod(value, 'arrayBuffer', const []),
    );
    return ab as ByteBuffer;
  }

  final blobCtor = jsu.getProperty(html.window, 'Blob');
  final parts = jsu.jsify([value]);
  final opts = jsu.jsify({'type': 'image/jpeg'});
  final dynamic blob = jsu.callConstructor(blobCtor, [parts, opts]);
  final dynamic ab = await jsu.promiseToFuture(
    jsu.callMethod(blob, 'arrayBuffer', const []),
  );
  return ab as ByteBuffer;
}
