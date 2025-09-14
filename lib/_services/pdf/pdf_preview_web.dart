// lib/_widgets/archives/pdf/pdf_preview_web.dart
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class PdfPreview extends StatelessWidget {
  final String pdfUrl;
  const PdfPreview({super.key, required this.pdfUrl});

  @override
  Widget build(BuildContext context) {
    final viewId = 'pdf-${pdfUrl.hashCode}';

    if (kIsWeb) {
      // evite registrar duas vezes em hot reload:
      // ignore: undefined_prefixed_name
      ui_web.platformViewRegistry.registerViewFactory(
        viewId,
            (int _) => html.IFrameElement()
          ..src = pdfUrl
          ..style.border = 'none'
          ..style.height = '100%'
          ..style.width = '100%',
      );
    }

    return kIsWeb
        ? HtmlElementView(viewType: viewId)
        : const Center(child: Text('Disponível apenas na Web'));
  }
}
