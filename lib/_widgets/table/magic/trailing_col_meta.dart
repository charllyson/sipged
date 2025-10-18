import 'package:flutter/material.dart';

enum TrailingValueType { text, number, money }

class TrailingColMeta {
  const TrailingColMeta({
    required this.title,
    this.width = 120,
    this.align = TextAlign.right,

    /// 🔒 Controle de edição
    this.editable = true,
    this.readOnlyHint = 'Somente leitura',

    /// 🔢 Formatação de valor
    this.type = TrailingValueType.text,
    this.decimals = 2,
    this.moneyPrefix = 'R\$ ',
  });

  final String title;
  final double width;
  final TextAlign align;

  /// 🔒 Habilita/Desabilita edição por coluna
  final bool editable;
  final String readOnlyHint;

  /// 🔢 Tipo de exibição e formato
  final TrailingValueType type;

  /// 🧮 Casas decimais (aplicado a number e money)
  final int decimals;

  /// 💵 Prefixo monetário (ex.: "R\$ ")
  final String moneyPrefix;
}
