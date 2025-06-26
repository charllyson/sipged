import 'dart:html' as html;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class PdfPreviewWeb extends StatelessWidget {
  final String pdfUrl;
  const PdfPreviewWeb({
    required this.pdfUrl,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final viewId = 'pdf-${pdfUrl.hashCode}';

    // Registra o iframe para visualização web
    // ignore: undefined_prefixed_name
    ui.platformViewRegistry.registerViewFactory(
      viewId,
          (int _) {
        final iframe = html.IFrameElement()
          ..src = pdfUrl
          ..style.border = 'none'
          ..style.height = '100%'
          ..style.width = '100%';

        return iframe;
      },
    );

    return SizedBox(
      child: HtmlElementView(viewType: viewId),
    );
  }
}