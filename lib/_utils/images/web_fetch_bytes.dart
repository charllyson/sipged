// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:js_util' as jsu;
import 'dart:typed_data';
import 'dart:async';

Future<Uint8List> fetchBytesWeb(String url) async {
  final req = html.HttpRequest();
  req.responseType = 'arraybuffer';
  final c = Completer<Uint8List>();

  req.onLoadEnd.listen((_) {
    if (req.status == 200 || req.status == 0) {
      final buf = req.response; // ArrayBuffer
      if (buf is ByteBuffer) {
        c.complete(buf.asUint8List());
      } else {
        c.completeError('fetchBytesWeb: resposta não é ArrayBuffer');
      }
    } else {
      c.completeError('fetchBytesWeb: status ${req.status}');
    }
  });

  // abre em modo CORS “padrão”
  req.open('GET', url);
  // se precisar cookies/credenciais, habilite: req.withCredentials = true;
  req.send();

  return c.future;
}
