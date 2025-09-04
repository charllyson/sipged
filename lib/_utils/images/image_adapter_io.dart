import 'dart:typed_data';
import 'package:http/http.dart' as http;

Future<Uint8List> loadImageBytes(String url) async {
  final r = await http.get(Uri.parse(url));
  if (r.statusCode >= 200 && r.statusCode < 300) return r.bodyBytes;
  throw Exception('HTTP ${r.statusCode} ao baixar $url');
}

Future<Uint8List?> tryConvertHeicToJpeg(Uint8List heicBytes) async {
  // Sem conversão nativa aqui. iOS exibe HEIC direto com Image.network,
  // Android pode falhar (depende do decodificador). Deixamos null => fallback no widget.
  return null;
}

bool sniffIsHeic(Uint8List bytes) {
  // mesma heurística simplificada
  if (bytes.isEmpty) return false;
  final isPng = bytes.length > 4 && bytes[0] == 0x89 && bytes[1] == 0x50;
  final isJpg = bytes.length > 2 && bytes[0] == 0xFF && bytes[1] == 0xD8;
  final isWebp = bytes.length > 12 &&
      bytes[0] == 0x52 && bytes[1] == 0x49 && bytes[2] == 0x46 && bytes[3] == 0x46 &&
      bytes[8] == 0x57 && bytes[9] == 0x45 && bytes[10] == 0x42 && bytes[11] == 0x50;
  return !(isPng || isJpg || isWebp);
}
