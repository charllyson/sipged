import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:siged/_widgets/texts/section_text_name.dart';
import 'package:siged/_widgets/input/custom_text_field.dart';
import 'package:siged/_widgets/input/drop_down_botton_change.dart';
import 'package:siged/_widgets/autocomplete/autocomplete_user_class.dart';
import 'package:siged/_widgets/layout/responsive_utils.dart';
import 'package:siged/_blocs/process/hiring/3Tr/tr_controller.dart';
import 'package:siged/_blocs/system/user/user_bloc.dart';
import 'package:siged/_blocs/system/user/user_data.dart';

class SectionObrigacoesEquipeGestao extends StatelessWidget {
  const SectionObrigacoesEquipeGestao({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.watch<TrController>();
    final users = context.select<UserBloc, List<UserData>>((b) => b.state.all);

    return LayoutBuilder(
      builder: (context, constraints) {
        final w3 = inputW3(context, constraints);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionTitle('5) Obrigações, Equipe e Gestão'),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: w3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: w3,
                        child: DropDownButtonChange(
                          enabled: c.isEditable,
                          labelText: 'Equipe mínima exigida',
                          controller: c.trEquipeMinimaCtrl,
                          items: const [
                            'Eng. civil + técnico de obras',
                            'Eng. civil + encarregado + laboratório',
                            'A definir no TR',
                          ],
                          onChanged: (v) => c.trEquipeMinimaCtrl.text = v ?? '',
                        ),
                      ),
                      SizedBox(height: 12),
                      SizedBox(
                        width: w3,
                        child: AutocompleteUserClass(
                          label: 'Fiscal do contrato (indicativo)',
                          controller: c.trFiscalCtrl,
                          enabled: c.isEditable,
                          allUsers: users,
                          initialUserId: c.trFiscalUserId,
                          onChanged: (u) {
                            c.trFiscalUserId = u;
                          },
                        ),
                      ),
                      SizedBox(height: 12),
                      SizedBox(
                        width: w3,
                        child: AutocompleteUserClass(
                          label: 'Gestor do contrato (indicativo)',
                          controller: c.trGestorCtrl,
                          enabled: c.isEditable,
                          allUsers: users,
                          initialUserId: c.trGestorUserId,
                          onChanged: (u) {
                            c.trGestorUserId = u;
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: w3,
                  child: CustomTextField(
                    controller: c.trObrigacoesContratadaCtrl,
                    labelText: 'Obrigações da contratada',
                    maxLines: 7,
                    enabled: c.isEditable,
                  ),
                ),
                SizedBox(
                  width: w3,
                  child: CustomTextField(
                    controller: c.trObrigacoesContratanteCtrl,
                    labelText: 'Obrigações da contratante',
                    maxLines: 7,
                    enabled: c.isEditable,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
