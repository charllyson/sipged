// lib/_widgets/archives/pdf/pdf_preview_stub.dart
import 'package:flutter/material.dart';

class PdfPreview extends StatelessWidget {
  final String pdfUrl;
  const PdfPreview({super.key, required this.pdfUrl});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('PDF Preview indisponível nesta plataforma.'));
  }
}
