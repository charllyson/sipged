// Função utilitária para baixar bytes no Web usando fetch
import 'dart:typed_data';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

Future<Uint8List> fetchBytesWeb(String url) async {
  final resp = await html.HttpRequest.request(
    url,
    responseType: 'arraybuffer',
  );
  final buf = resp.response as ByteBuffer;
  return buf.asUint8List();
}
