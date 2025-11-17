import 'package:flutter/material.dart';
import 'package:siged/_widgets/input/custom_text_field.dart';
import 'package:siged/_widgets/texts/section_text_name.dart';
import 'package:siged/_widgets/layout/responsive_utils.dart';
import 'package:siged/_blocs/process/hiring/2Etp/etp_controller.dart';

class SectionConclusao extends StatelessWidget {
  final EtpController controller;
  const SectionConclusao({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final c = controller;

    return LayoutBuilder(
      builder: (context, constraints) {
        final w1 = inputW1(context, constraints);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionTitle('8) Conclusão'),
            SizedBox(
              width: w1,
              child: CustomTextField(
                controller: c.etpConclusaoCtrl,
                enabled: c.isEditable,
                labelText: 'Conclusão / Encaminhamento',
                maxLines: 3,
              ),
            ),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }
}
