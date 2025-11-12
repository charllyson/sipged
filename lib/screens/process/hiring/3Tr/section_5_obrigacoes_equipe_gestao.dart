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

  double _w(BuildContext ctx, {int itemsPerLine = 2}) =>
      responsiveInputWidth(context: ctx, itemsPerLine: itemsPerLine);

  @override
  Widget build(BuildContext context) {
    final c = context.watch<TrController>();
    final users = context.select<UserBloc, List<UserData>>((b) => b.state.all);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle('5) Obrigações, Equipe e Gestão'),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            SizedBox(
              width: _w(context),
              child: CustomTextField(
                controller: c.trObrigacoesContratadaCtrl,
                labelText: 'Obrigações da contratada',
                maxLines: 4,
                enabled: c.isEditable,
              ),
            ),
            SizedBox(
              width: _w(context),
              child: CustomTextField(
                controller: c.trObrigacoesContratanteCtrl,
                labelText: 'Obrigações da contratante',
                maxLines: 4,
                enabled: c.isEditable,
              ),
            ),
            SizedBox(
              width: _w(context),
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
            SizedBox(
              width: _w(context),
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
            SizedBox(
              width: _w(context),
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
      ],
    );
  }
}
