import 'dart:typed_data';
import 'dart:js_interop';
import 'package:web/web.dart' as web;

Future<Uint8List> fetchBytesWeb(String url) async {
  final resp = await web.window.fetch(url.toJS).toDart;
  final buffer = await resp.arrayBuffer().toDart;
  return Uint8List.view(buffer.toDart);
}