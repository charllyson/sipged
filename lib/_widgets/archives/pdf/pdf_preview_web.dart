import 'dart:ui_web' as ui_web;
import 'dart:html' as html;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class PdfPreviewWeb extends StatelessWidget {
  final String pdfUrl;

  const PdfPreviewWeb({super.key, required this.pdfUrl});

  @override
  Widget build(BuildContext context) {
    final viewId = 'pdf-${pdfUrl.hashCode}';

    if (kIsWeb) {
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
