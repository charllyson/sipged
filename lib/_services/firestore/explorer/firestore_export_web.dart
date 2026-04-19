import 'dart:js_interop';
import 'package:web/web.dart' as web;

Future<void> downloadJson(String filename, String json) async {
  final blob = web.Blob(
    [json.toJS].toJS,
    web.BlobPropertyBag(type: 'application/json'),
  );
  final url = web.URL.createObjectURL(blob);

  final anchor = web.HTMLAnchorElement()
    ..href = url
    ..download = filename;

  anchor.click();
  web.URL.revokeObjectURL(url);
}

Future<void> downloadCsv(String filename, String csv) async {
  final blob = web.Blob(
    [csv.toJS].toJS,
    web.BlobPropertyBag(type: 'text/csv'),
  );
  final url = web.URL.createObjectURL(blob);

  final anchor = web.HTMLAnchorElement()
    ..href = url
    ..download = filename;

  anchor.click();
  web.URL.revokeObjectURL(url);
}