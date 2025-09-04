// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

Future<void> downloadJson(String filename, String json) async {
  final blob = html.Blob([json], 'application/json');
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.AnchorElement(href: url)..download = filename..click();
  html.Url.revokeObjectUrl(url);
}

Future<void> downloadCsv(String filename, String csv) async {
  final blob = html.Blob([csv], 'text/csv');
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.AnchorElement(href: url)..download = filename..click();
  html.Url.revokeObjectUrl(url);
}
