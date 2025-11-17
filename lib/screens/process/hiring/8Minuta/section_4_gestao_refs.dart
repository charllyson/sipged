import 'package:flutter/material.dart';

import 'package:siged/_widgets/layout/responsive_utils.dart';
import 'package:siged/_widgets/input/custom_text_field.dart';
import 'package:siged/_widgets/input/drop_down_botton_change.dart'
    show DropDownButtonChange;
import 'package:siged/_widgets/texts/section_text_name.dart';
import 'package:siged/_widgets/autocomplete/autocomplete_user_class.dart';

import 'package:siged/_blocs/system/user/user_data.dart';
import 'package:siged/_blocs/process/hiring/8Minuta/minuta_contrato_controller.dart';

class SectionGestaoRefs extends StatelessWidget {
  final MinutaContratoController controller;
  final List<UserData> users;

  const SectionGestaoRefs({
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
        const SectionTitle('4) Gestão e Referências (do TR/Edital)'),
        LayoutBuilder(
          builder: (context, constraints) {
            final w2 = inputW2(context, constraints);
            final w4 = inputW4(context, constraints);
            final w1 = inputW1(context, constraints);

            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: w4,
                  child: AutocompleteUserClass(
                    label: 'Gestor do contrato (definido no processo)',
                    controller: c.mcGestorCtrl,
                    allUsers: users,
                    enabled: c.isEditable,
                    initialUserId: c.mcGestorUserId,
                    onChanged: (u) => c.mcGestorUserId = u,
                  ),
                ),
                SizedBox(
                  width: w4,
                  child: AutocompleteUserClass(
                    label: 'Fiscal do contrato (definido no processo)',
                    controller: c.mcFiscalCtrl,
                    allUsers: users,
                    enabled: c.isEditable,
                    initialUserId: c.mcFiscalUserId,
                    onChanged: (u) => c.mcFiscalUserId = u,
                  ),
                ),
                SizedBox(
                  width: w4,
                  child: DropDownButtonChange(
                    labelText: 'Regime de execução (referência TR)',
                    controller: TextEditingController(
                      text: c.mcRegimeExecucaoRef ?? '',
                    ),
                    items: const [],
                    onChanged: (_) {},
                  ),
                ),
                SizedBox(
                  width: w4,
                  child: CustomTextField(
                    enabled: false, // referência – prazos do TR
                    controller: TextEditingController(
                      text: c.mcPrazosRef ?? '',
                    ),
                    labelText: 'Prazos/Vigência (referência TR)',
                  ),
                ),
                SizedBox(
                  width: w1,
                  child: CustomTextField(
                    controller: c.mcLinksAnexosCtrl,
                    labelText:
                    'Links/Anexos (TR, ETP, ARP, proposta, documentos do gestor)',
                    maxLines: 2,
                    enabled: c.isEditable,
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
