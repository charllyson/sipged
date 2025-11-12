import 'package:flutter/material.dart';
import 'package:siged/_widgets/layout/responsive_utils.dart';
import 'package:siged/_widgets/input/custom_text_field.dart';
import 'package:siged/_widgets/texts/section_text_name.dart';
import 'package:siged/_widgets/autocomplete/autocomplete_user_class.dart';
import 'package:siged/_blocs/system/user/user_data.dart';
import 'package:siged/_blocs/process/hiring/9Juridico/parecer_juridico_controller.dart';

class SectionAssinaturas extends StatelessWidget {
  final ParecerJuridicoController controller;
  final List<UserData> users;
  const SectionAssinaturas({super.key, required this.controller, required this.users});

  double _w(BuildContext ctx, {int itemsPerLine = 4}) => responsiveInputWidth(
    context: ctx, itemsPerLine: itemsPerLine, spacing: 12, margin: 12, extraPadding: 24,
  );

  @override
  Widget build(BuildContext context) {
    final c = controller;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle('6) Assinaturas / Referências finais'),
        Wrap(spacing: 12, runSpacing: 12, children: [
          SizedBox(
            width: _w(context, itemsPerLine: 2),
            child: AutocompleteUserClass(
              label: 'Autoridade que aprovou o parecer',
              controller: c.pjAutoridadeCtrl,
              allUsers: users,
              enabled: c.isEditable,
              initialUserId: c.pjAutoridadeUserId,
              onChanged: (u) => c.pjAutoridadeUserId = u,
            ),
          ),
          SizedBox(
            width: _w(context, itemsPerLine: 2),
            child: CustomTextField(
              controller: c.pjLocalCtrl,
              labelText: 'Local',
              enabled: c.isEditable,
            ),
          ),
          SizedBox(
            width: _w(context, itemsPerLine: 1),
            child: CustomTextField(
              controller: c.pjObservacoesFinaisCtrl,
              labelText: 'Observações finais',
              maxLines: 2,
              enabled: c.isEditable,
            ),
          ),
        ]),
        const SizedBox(height: 16),
      ],
    );
  }
}
