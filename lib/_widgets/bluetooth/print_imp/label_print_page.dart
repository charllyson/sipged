/*
import 'package:flutter/material.dart';

// Import condicional por plataforma:
// - default: stub
// - web:     implementação Web Bluetooth
// - io:      implementação nativa (Android/iOS)
import 'package:siged/_widgets/bluetooth/print_imp/label_print_impl_stub.dart'
if (dart.library.html) 'package:siged/_widgets/bluetooth/print_imp/label_print_impl_web.dart'
if (dart.library.io)   'package:siged/_widgets/bluetooth/print_imp/label_print_impl_native.dart';

// ATENÇÃO: as 3 implementações acima DEVEM expor um top-level:
// Widget buildLabelPrintPage({ String? initialText, String? initialQr, Size? initialSizeMm });

class LabelPrintPage extends StatelessWidget {
  final String? initialText;
  final String? initialQr;
  final Size? initialSizeMm;

  const LabelPrintPage({
    super.key,
    this.initialText,
    this.initialQr,
    this.initialSizeMm,
  });

  @override
  Widget build(BuildContext context) {
    // vem da implementação selecionada pelo import condicional
    return buildLabelPrintPage(
      initialText: initialText,
      initialQr: initialQr,
      initialSizeMm: initialSizeMm,
    );
  }
}
*/
