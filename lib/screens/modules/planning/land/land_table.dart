// lib/screens/modules/planning/rightWay/property/land_table.dart
import 'package:flutter/material.dart';
import 'package:sipged/_widgets/texts/section_text_name.dart';

class LandTable extends StatelessWidget {
  const LandTable({
    super.key,
    this.headerTitle = 'Imóveis cadastrados',
    this.padding = const EdgeInsets.symmetric(horizontal: 12),
    this.emptyMessage = 'Nenhum imóvel encontrado.',
  });

  final String headerTitle;
  final EdgeInsetsGeometry padding;
  final String emptyMessage;


  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SectionTitle(text: headerTitle),
      ],
    );
  }
}