import 'dart:typed_data';
import 'dart:js_interop';
import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;
import 'package:sipged/_widgets/pdf/pdf_preview_io.dart';

Future<void> launchPdfPreview(
    BuildContext context,
    Uint8List bytes, {
      String? fileName,
    }) async {
  final blob = web.Blob(
    [bytes.toJS].toJS,
    web.BlobPropertyBag(type: 'application/pdf'),
  );

  final url = web.URL.createObjectURL(blob);

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
    web.URL.revokeObjectURL(url);
  }
}