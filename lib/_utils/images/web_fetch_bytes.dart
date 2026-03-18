import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

Future<Uint8List> fetchBytesWeb(String url) async {
  final response = await web.window.fetch(url.toJS).toDart;

  if (!response.ok) {
    throw Exception(
      'Erro ao buscar bytes: HTTP ${response.status} - $url',
    );
  }

  final buffer = await response.arrayBuffer().toDart;
  return Uint8List.view(buffer.toDart);
}