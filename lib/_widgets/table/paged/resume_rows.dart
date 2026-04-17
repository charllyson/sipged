import 'package:flutter/material.dart';
import 'package:sipged/_utils/formats/sipged_format_money.dart';
import 'package:sipged/_widgets/table/paged/resume_data.dart';


class ResumeRows extends StatelessWidget {
  final List<ResumeData> linhas;
  final bool mostrarColunaExcluir;

  const ResumeRows({
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
