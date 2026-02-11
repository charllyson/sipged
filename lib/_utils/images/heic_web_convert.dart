// Converte HEIC -> JPEG no Web via biblioteca JS heic2any
// (precisa estar incluída no index.html e exposta no global scope como `heic2any`)

import 'dart:typed_data';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:web/web.dart' as web;

@JS('heic2any')
external JSPromise<web.Blob> _heic2any(JSObject options);

Future<Uint8List> convertHeicBytesToJpegWeb(Uint8List heicBytes) async {
  // ✅ BlobPart tipado corretamente
  final parts = <web.BlobPart>[heicBytes.toJS].toJS;

  final heicBlob = web.Blob(
    parts,
    web.BlobPropertyBag(type: 'image/heic'),
  );

  // options { blob: heicBlob, toType: 'image/jpeg' }
  final opts = JSObject();
  opts.setProperty('blob'.toJS, heicBlob);
  opts.setProperty('toType'.toJS, 'image/jpeg'.toJS);

  // Promise<Blob>
  final jpgBlob = await _heic2any(opts).toDart;

  // Blob -> ArrayBuffer -> Uint8List
  final jsBuf = await jpgBlob.arrayBuffer().toDart;
  final byteBuffer = jsBuf.toDart;
  return byteBuffer.asUint8List();
}
