// lib/_widgets/archives/pdf/pdf_preview.dart
export 'pdf_preview_stub.dart'
if (dart.library.html) 'pdf_preview_web.dart'
if (dart.library.io) 'pdf_preview_io.dart';
