// Converte HEIC -> JPEG no Web via biblioteca JS heic2any (precisa estar incluída no index.html)
import 'dart:async';
import 'dart:typed_data';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:js_util' as jsu;

Future<Uint8List> convertHeicBytesToJpegWeb(Uint8List heicBytes) async {
  final blob = html.Blob([heicBytes], 'image/heic');
  final promise = jsu.callMethod(html.window, 'heic2any', [
    {'blob': blob, 'toType': 'image/jpeg'}
  ]);
  final result = await jsu.promiseToFuture(promise);
  if (result is html.Blob) {
    final reader = html.FileReader();
    final completer = Completer<Uint8List>();
    reader.onLoadEnd.listen((_) {
      final buf = reader.result as ByteBuffer;
      completer.complete(buf.asUint8List());
    });
    reader.readAsArrayBuffer(result);
    return completer.future;
  }
  throw Exception('Falha ao converter HEIC');
}
