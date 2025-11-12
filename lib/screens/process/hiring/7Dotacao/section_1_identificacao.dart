import 'package:flutter/material.dart';
import 'package:siged/_widgets/layout/responsive_utils.dart';
import 'package:siged/_widgets/input/custom_text_field.dart';
import 'package:siged/_widgets/autocomplete/autocomplete_user_class.dart';
import 'package:siged/_widgets/texts/section_text_name.dart';
import 'package:siged/_utils/validates/form_validation_mixin.dart';
import 'package:siged/_blocs/system/user/user_data.dart';
import 'package:siged/_blocs/process/hiring/7Dotacao/dotacao_controller.dart';

class SectionIdentificacao extends StatelessWidget with FormValidationMixin {
  final DotacaoController controller;
  final List<UserData> users;
  SectionIdentificacao({super.key, required this.controller, required this.users});

  double _w(BuildContext ctx, {int itemsPerLine = 4}) => responsiveInputWidth(
    context: ctx, itemsPerLine: itemsPerLine, spacing: 12, margin: 12, extraPadding: 24,
  );

  @override
  Widget build(BuildContext context) {
    final c = controller;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle('1) Identificação / Exercício'),
        Wrap(spacing: 12, runSpacing: 12, children: [
          SizedBox(
            width: _w(context),
            child: CustomTextField(
              controller: c.exercicioCtrl,
              labelText: 'Exercício (ano)',
              enabled: c.isEditable,
              keyboardType: TextInputType.number,
            ),
          ),
          SizedBox(
            width: _w(context),
            child: CustomTextField(
              controller: c.processoSeiCtrl,
              labelText: 'Nº do processo (SEI/Interno)',
              enabled: c.isEditable,
              validator: validateRequired,
            ),
          ),
          SizedBox(
            width: _w(context),
            child: AutocompleteUserClass(
              label: 'Responsável orçamentário',
              controller: c.responsavelOrcCtrl,
              initialUserId: c.responsavelOrcUserId,
              allUsers: users,
              enabled: c.isEditable,
              validator: validateRequired,
              onChanged: (u) {
                c.responsavelOrcUserId = u;
              },
            ),
          ),
        ]),
        const SizedBox(height: 16),
      ],
    );
  }
}
