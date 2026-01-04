import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:siged/_widgets/buttons/back_circle_button.dart';
import 'package:siged/_widgets/menu/upBar/up_bar.dart';

/// Abre uma tela nativa de pré-visualização do PDF (com opções de imprimir/compartilhar)
Future<void> launchPdfPreview(
    BuildContext context,
    Uint8List bytes, {
      required String fileName,
    }) async {
  await Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => Scaffold(
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(72),
          child: UpBar(
            leading: Padding(
              padding: const EdgeInsets.only(left: 12.0),
              child: BackCircleButton(),
            ),
            titleWidgets: [
              Text(fileName)
            ],
            actions: [
              IconButton(
                tooltip: 'Compartilhar',
                icon: const Icon(Icons.ios_share),
                onPressed: () => Printing.sharePdf(
                  bytes: bytes,
                  filename: fileName,
                ),
              ),
              IconButton(
                tooltip: 'Imprimir',
                icon: const Icon(Icons.print),
                onPressed: () => Printing.layoutPdf(
                  onLayout: (_) async => bytes,
                  name: fileName,
                ),
              ),
            ]
          ),
        ),
        body: PdfPreview(
          build: (format) async => bytes,
          pdfFileName: fileName,
          allowPrinting: true,
          allowSharing: true,
          canChangePageFormat: true,
          canChangeOrientation: true,
          canDebug: false,
          initialPageFormat: PdfPageFormat.a4, // ajuste se quiser
          maxPageWidth: 1400,                  // opcional
        ),
      ),
    ),
  );
}
