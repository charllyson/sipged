import 'package:flutter/material.dart';
import 'package:siged/_utils/formats/sipged_format_money.dart';

class FooterResumo {
  final String label;
  final double? value;
  final Color backgroundColor;
  final FontWeight? fontWeight;

  FooterResumo({
    required this.label,
    required this.value,
    required this.backgroundColor,
    this.fontWeight
  });

  factory FooterResumo.empty() {
    return FooterResumo(
      label: '',
      value: null,
      backgroundColor: Colors.transparent,
    );
  }
}

class FooterRowsGeneric extends StatelessWidget {
  final List<FooterResumo> linhas;
  final bool mostrarColunaExcluir;

  const FooterRowsGeneric({
    super.key,
    required this.linhas,
    this.mostrarColunaExcluir = false,
  });

  List<TableRow> get rows => linhas
      .map(
        (linha) => TableRow(
      decoration: BoxDecoration(color: linha.backgroundColor),
      children: [
        const SizedBox(),
        const SizedBox(),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            linha.label,
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: linha.fontWeight ?? FontWeight.bold),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            SipGedFormatMoney.doubleToText(linha.value),
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: linha.fontWeight ?? FontWeight.bold),
          ),
        ),
        if (mostrarColunaExcluir) const SizedBox(),
      ],
    ),
  )
      .toList();

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
