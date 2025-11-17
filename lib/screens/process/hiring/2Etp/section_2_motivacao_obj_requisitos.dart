import 'package:flutter/material.dart';
import 'package:siged/_widgets/input/custom_text_field.dart';
import 'package:siged/_widgets/texts/section_text_name.dart';
import 'package:siged/_widgets/layout/responsive_utils.dart';
import 'package:siged/_utils/validates/form_validation_mixin.dart';
import 'package:siged/_blocs/process/hiring/2Etp/etp_controller.dart';

class SectionMotivacaoObjRequisitos extends StatelessWidget
    with FormValidationMixin {
  final EtpController controller;
  SectionMotivacaoObjRequisitos({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final c = controller;

    return LayoutBuilder(
      builder: (context, constraints) {
        final w3 = inputW3(context, constraints);


        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionTitle('2) Motivação, objetivos e requisitos'),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: w3,
                  child: CustomTextField(
                    controller: c.etpMotivacaoCtrl,
                    enabled: c.isEditable,
                    labelText: 'Motivação / Problema',
                    validator: validateRequired,
                    maxLines: 5,
                  ),
                ),
                SizedBox(
                  width: w3,
                  child: CustomTextField(
                    controller: c.etpObjetivosCtrl,
                    enabled: c.isEditable,
                    labelText: 'Objetivos',
                    validator: validateRequired,
                    maxLines: 5,
                  ),
                ),
                SizedBox(
                  width: w3,
                  child: CustomTextField(
                    controller: c.etpRequisitosMinimosCtrl,
                    enabled: c.isEditable,
                    labelText: 'Requisitos mínimos / escopo preliminar',
                    maxLines: 5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }
}
