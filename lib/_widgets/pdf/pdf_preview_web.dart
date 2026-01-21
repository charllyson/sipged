// lib/_widgets/files/pdf/pdf_preview_web.dart
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class PdfPreview extends StatelessWidget {
  final String pdfUrl;
  const PdfPreview({super.key, required this.pdfUrl});

  // evita registrar a mesma factory repetidas vezes (hot reload)
  static final Set<String> _registered = <String>{};

  @override
  Widget build(BuildContext context) {
    final viewId = 'pdf-${pdfUrl.hashCode}';

    if (kIsWeb && !_registered.contains(viewId)) {
      // ignore: undefined_prefixed_name
      ui_web.platformViewRegistry.registerViewFactory(
        viewId,
            (int _) => html.IFrameElement()
          ..src = pdfUrl
          ..style.border = 'none'
          ..style.height = '100%'
          ..style.width = '100%',
      );
      _registered.add(viewId);
    }

    if (!kIsWeb) {
      return const Center(child: Text('Disponível apenas na Web'));
    }

    // controla o tamanho dentro do Dialog
    final maxH = MediaQuery.of(context).size.height * 0.9;

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: 1200,
        maxHeight: maxH,
        minWidth: 320,
        minHeight: 300,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Column(
          children: [
            // Top bar com botão de fechar
            Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              color: Colors.grey.shade100,
              child: Row(
                children: [
                  const SizedBox(width: 8),
                  const Icon(Icons.picture_as_pdf, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Visualizando PDF',
                      style: Theme.of(context).textTheme.bodyMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Fechar',
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                ],
              ),
            ),

            // IFRAME (ocupa o restante)
            const Divider(height: 1, thickness: 1),
            Expanded(
              child: HtmlElementView(viewType: viewId),
            ),
          ],
        ),
      ),
    );
  }
}
