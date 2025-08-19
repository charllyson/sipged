import 'package:flutter/material.dart';

class PdfPreviewWeb extends StatelessWidget {
  final String pdfUrl;
  const PdfPreviewWeb({super.key, required this.pdfUrl});

  @override
  Widget build(BuildContext context) {
    // Fallback para plataformas que não são Web
    return SizedBox(
      width: 600,
      height: 400,
      child: Center(
        child: Text(
          'Pré-visualização de PDF indisponível nesta plataforma.\n'
              'URL: $pdfUrl',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
