import 'package:flutter/material.dart';

class PdfPreviewWeb extends StatelessWidget {
  final String pdfUrl;
  const PdfPreviewWeb({super.key, required this.pdfUrl});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Visualização de PDF disponível apenas na Web'),
    );
  }
}
