// lib/screens/process/hiring/1Dfd/dfd_sections/section_8_observacoes.dart
import 'package:flutter/material.dart';

import 'package:siged/_blocs/process/hiring/1Dfd/dfd_controller.dart';
import 'package:siged/_widgets/input/custom_text_field.dart';
import 'package:siged/_widgets/input/dropdown_yes_no.dart';
import 'package:siged/_widgets/texts/section_text_name.dart';

class SectionObservacoes extends StatelessWidget {
  final DfdController controller;
  const SectionObservacoes({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle('8) Observações'),
        LayoutBuilder(builder: (context, inner) {
          final w1 = inputWidth(context: context, inner: inner, perLine: 1, minItemWidth: 400);
          return SizedBox(
            width: w1,
            child: CustomTextField(
              controller: controller.dfdObservacoesCtrl,
              enabled: controller.isEditable,
              labelText: 'Observações complementares',
              maxLines: 4,
            ),
          );
        }),
      ],
    );
  }
}
