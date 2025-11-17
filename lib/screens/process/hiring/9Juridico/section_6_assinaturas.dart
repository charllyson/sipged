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

  const SectionAssinaturas({
    super.key,
    required this.controller,
    required this.users,
  });

  @override
  Widget build(BuildContext context) {
    final c = controller;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle('6) Assinaturas / Referências finais'),
        LayoutBuilder(
          builder: (context, constraints) {
            final w2 = inputW2(context, constraints);
            final w1 = inputW1(context, constraints);

            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: w2,
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
                  width: w2,
                  child: CustomTextField(
                    controller: c.pjLocalCtrl,
                    labelText: 'Local',
                    enabled: c.isEditable,
                  ),
                ),
                SizedBox(
                  width: w1,
                  child: CustomTextField(
                    controller: c.pjObservacoesFinaisCtrl,
                    labelText: 'Observações finais',
                    maxLines: 2,
                    enabled: c.isEditable,
                    textAlignVertical: TextAlignVertical.top,
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
