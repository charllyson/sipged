import 'package:flutter/material.dart';
import 'package:siged/_widgets/layout/responsive_utils.dart';
import 'package:siged/_widgets/input/custom_text_field.dart';
import 'package:siged/_widgets/input/drop_down_botton_change.dart' show DropDownButtonChange;
import 'package:siged/_widgets/texts/section_text_name.dart';
import 'package:siged/_widgets/autocomplete/autocomplete_user_class.dart';
import 'package:siged/_blocs/system/user/user_data.dart';
import 'package:siged/_blocs/process/hiring/8Minuta/minuta_contrato_controller.dart';

class SectionGestaoRefs extends StatelessWidget {
  final MinutaContratoController controller;
  final List<UserData> users;
  const SectionGestaoRefs({super.key, required this.controller, required this.users});

  double _w(BuildContext ctx, {int itemsPerLine = 4}) => responsiveInputWidth(
    context: ctx, itemsPerLine: itemsPerLine, spacing: 12, margin: 12, extraPadding: 24,
  );

  @override
  Widget build(BuildContext context) {
    final c = controller;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle('4) Gestão e Referências (do TR/Edital)'),
        Wrap(spacing: 12, runSpacing: 12, children: [
          SizedBox(
            width: _w(context, itemsPerLine: 2),
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
            width: _w(context, itemsPerLine: 2),
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
            width: _w(context, itemsPerLine: 1),
            child: CustomTextField(
              controller: c.mcLinksAnexosCtrl,
              labelText: 'Links/Anexos (TR, ETP, ARP, proposta, documentos do gestor)',
              maxLines: 2,
              enabled: c.isEditable,
            ),
          ),
          SizedBox(
            width: _w(context),
            child: DropDownButtonChange(
              enabled: false, // referência – vindo do TR
              labelText: 'Regime de execução (referência TR)',
              controller: TextEditingController(text: c.mcRegimeExecucaoRef ?? ''),
              items: const [],
              onChanged: (_) {},
            ),
          ),
          SizedBox(
            width: _w(context),
            child: CustomTextField(
              enabled: false, // referência – prazos do TR
              controller: TextEditingController(text: c.mcPrazosRef ?? ''),
              labelText: 'Prazos/Vigência (referência TR)',
            ),
          ),
        ]),
        const SizedBox(height: 16),
      ],
    );
  }
}
