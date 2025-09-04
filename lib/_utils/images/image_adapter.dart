// NÃO põe import de html aqui.
import 'dart:typed_data';

/// Tenta baixar os bytes de uma imagem por URL.
/// - Web: usa fetch e respeita CORS.
/// - Mobile/Desktop: usa http.
Future<Uint8List> loadImageBytes(String url) {
  // TODO: implement loadImageBytes
  throw UnimplementedError();
}

/// Se os bytes forem HEIC e a plataforma suportar conversão:
/// - Web: tenta converter via heic2any (JS). Se não tiver, retorna null.
/// - iOS/Android/Desktop: retorna null (o widget decide o fallback).
Future<Uint8List?> tryConvertHeicToJpeg(Uint8List heicBytes) {
  // TODO: implement tryConvertHeicToJpeg
  throw UnimplementedError();
}

/// Heurística simples pro web/mobile reutilizarem.
bool sniffIsHeic(Uint8List bytes) {
  // TODO: implement sniffIsHeic
  throw UnimplementedError();
}
