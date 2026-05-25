import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

@JS('heic2any')
external JSPromise<web.Blob> _heic2any(JSObject options);

Future<Uint8List> convertHeicBytesToJpegWeb(Uint8List heicBytes) async {
  final parts = <web.BlobPart>[heicBytes.toJS].toJS;

  final heicBlob = web.Blob(
    parts,
    web.BlobPropertyBag(type: 'image/heic'),
  );

  final options = JSObject();
  options.setProperty('blob'.toJS, heicBlob);
  options.setProperty('toType'.toJS, 'image/jpeg'.toJS);

  final jpgBlob = await _heic2any(options).toDart;

  final buffer = await jpgBlob.arrayBuffer().toDart;
  final byteBuffer = buffer.toDart;

  return byteBuffer.asUint8List();
}