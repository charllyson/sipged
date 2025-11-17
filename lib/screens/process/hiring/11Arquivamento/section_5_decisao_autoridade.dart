import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:siged/_blocs/process/hiring/0Stages/hiring_data.dart';
import 'package:siged/_widgets/input/custom_date_field.dart';

import 'package:siged/_widgets/input/custom_text_field.dart';
import 'package:siged/_widgets/input/drop_down_botton_change.dart'
    show DropDownButtonChange;
import 'package:siged/_widgets/autocomplete/autocomplete_user_class.dart';
import 'package:siged/_widgets/layout/responsive_utils.dart';
import 'package:siged/_widgets/texts/section_text_name.dart';
import 'package:siged/_blocs/system/user/user_data.dart';
import 'package:siged/_blocs/process/hiring/11Arquivamento/termo_arquivamento_controller.dart';
import 'package:siged/_utils/formats/mask_class.dart';

class SectionDecisaoAutoridadeTA extends StatefulWidget {
  final TermoArquivamentoController controller;
  final List<UserData> users;
  const SectionDecisaoAutoridadeTA({
    super.key,
    required this.controller,
    required this.users,
  });

  @override
  State<SectionDecisaoAutoridadeTA> createState() =>
      _SectionDecisaoAutoridadeTAState();
}

class _SectionDecisaoAutoridadeTAState
    extends State<SectionDecisaoAutoridadeTA> {
  @override
  Widget build(BuildContext context) {
    final c = widget.controller;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle('5) Decisão da Autoridade'),
        LayoutBuilder(
          builder: (context, constraints) {
            final w2 = inputW2(context, constraints);
            final w3 = inputW3(context, constraints);
            final w1 = inputW1(context, constraints);

            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: w2,
                  child: Column(
                    children: [
                      SizedBox(
                        width: w2,
                        child: AutocompleteUserClass(
                          label: 'Autoridade competente',
                          controller: c.taAutoridadeCtrl,
                          allUsers: widget.users,
                          enabled: c.isEditable,
                          initialUserId: c.taAutoridadeUserId,
                        ),
                      ),
                      SizedBox(height: 12),
                      SizedBox(
                        width: w2,
                        child: DropDownButtonChange(
                          enabled: c.isEditable,
                          labelText: 'Decisão',
                          controller: c.taDecisaoCtrl,
                          items: HiringData.decisaoArquivamento,
                          onChanged: (v) =>
                              setState(() => c.taDecisaoCtrl.text = v ?? ''),
                        ),
                      ),
                      SizedBox(height: 12),
                      SizedBox(
                        width: w2,
                        child: CustomDateField(
                          controller: c.taDataDecisaoCtrl,
                          labelText: 'Data da decisão',
                          enabled: c.isEditable,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(8),
                            TextInputMask(mask: '99/99/9999'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: w2,
                  child: CustomTextField(
                    controller: c.taObservacoesDecisaoCtrl,
                    labelText: 'Observações da decisão',
                    maxLines: 7,
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
