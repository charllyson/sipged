import 'package:flutter/material.dart';
import 'package:siged/_widgets/input/custom_text_field.dart';
import 'package:siged/_widgets/input/drop_down_botton_change.dart' show DropDownButtonChange;
import 'package:siged/_widgets/autocomplete/autocomplete_user_class.dart';
import 'package:siged/_widgets/layout/responsive_utils.dart';
import 'package:siged/_widgets/texts/section_text_name.dart';
import 'package:siged/_blocs/system/user/user_data.dart';
import 'package:siged/_blocs/process/hiring/11Arquivamento/termo_arquivamento_controller.dart';
import 'package:flutter/services.dart';
import 'package:siged/_utils/formats/mask_class.dart';

class SectionDecisaoAutoridadeTA extends StatefulWidget {
  final TermoArquivamentoController controller;
  final List<UserData> users;
  const SectionDecisaoAutoridadeTA({super.key, required this.controller, required this.users});

  @override
  State<SectionDecisaoAutoridadeTA> createState() => _SectionDecisaoAutoridadeTAState();
}

class _SectionDecisaoAutoridadeTAState extends State<SectionDecisaoAutoridadeTA> {
  double _w(BuildContext ctx, {int itemsPerLine = 4}) => responsiveInputWidth(
    context: ctx, itemsPerLine: itemsPerLine, spacing: 12, margin: 12, extraPadding: 24,
  );

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SectionTitle('5) Decisão da Autoridade'),
      Wrap(spacing: 12, runSpacing: 12, children: [
        SizedBox(
          width: _w(context, itemsPerLine: 2),
          child: AutocompleteUserClass(
            label: 'Autoridade competente',
            controller: c.taAutoridadeCtrl,
            allUsers: widget.users,
            enabled: c.isEditable,
            initialUserId: c.taAutoridadeUserId,
          ),
        ),
        SizedBox(
          width: _w(context),
          child: DropDownButtonChange(
            enabled: c.isEditable,
            labelText: 'Decisão',
            controller: c.taDecisaoCtrl,
            items: const ['Aprovo o arquivamento', 'Arquivar após saneamento', 'Não aprovo'],
            onChanged: (v) => setState(() => c.taDecisaoCtrl.text = v ?? ''),
          ),
        ),
        SizedBox(
          width: _w(context),
          child: CustomTextField(
            controller: c.taDataDecisaoCtrl,
            labelText: 'Data da decisão',
            hintText: 'dd/mm/aaaa',
            enabled: c.isEditable,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(8),
              TextInputMask(mask: '99/99/9999'),
            ],
            keyboardType: TextInputType.number,
          ),
        ),
        SizedBox(
          width: _w(context, itemsPerLine: 1),
          child: CustomTextField(
            controller: c.taObservacoesDecisaoCtrl,
            labelText: 'Observações da decisão',
            maxLines: 2,
            enabled: c.isEditable,
          ),
        ),
      ]),
      const SizedBox(height: 16),
    ]);
  }
}
