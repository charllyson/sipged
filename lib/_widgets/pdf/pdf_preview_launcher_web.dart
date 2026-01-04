import 'dart:typed_data';
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:siged/_widgets/pdf/pdf_preview_io.dart';

Future<void> launchPdfPreview(BuildContext context, Uint8List bytes, {String? fileName}) async {
  final blob = html.Blob([bytes], 'application/pdf');
  final url  = html.Url.createObjectUrlFromBlob(blob);
  try {
    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: PdfPreview(pdfUrl: url),
      ),
    );
  } finally {
    html.Url.revokeObjectUrl(url); // 🔒 evita vazamento
  }
}
