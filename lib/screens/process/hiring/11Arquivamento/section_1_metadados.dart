import 'package:flutter/material.dart';
import 'package:siged/_utils/validates/form_validation_mixin.dart';
import 'package:siged/_widgets/input/custom_text_field.dart';
import 'package:siged/_widgets/layout/responsive_utils.dart';
import 'package:siged/_widgets/texts/section_text_name.dart';
import 'package:siged/_widgets/autocomplete/autocomplete_user_class.dart';
import 'package:siged/_blocs/system/user/user_data.dart';
import 'package:flutter/services.dart';
import 'package:siged/_utils/formats/mask_class.dart';
import 'package:siged/_blocs/process/hiring/11Arquivamento/termo_arquivamento_controller.dart';

class SectionMetadadosTA extends StatefulWidget {
  final TermoArquivamentoController controller;
  final List<UserData> users;
  const SectionMetadadosTA({super.key, required this.controller, required this.users});

  @override
  State<SectionMetadadosTA> createState() => _SectionMetadadosTAState();
}

class _SectionMetadadosTAState extends State<SectionMetadadosTA>
    with FormValidationMixin {
  double _w(BuildContext ctx, {int itemsPerLine = 4}) => responsiveInputWidth(
    context: ctx, itemsPerLine: itemsPerLine, spacing: 12, margin: 12, extraPadding: 24,
  );

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SectionTitle('1) Metadados'),
      Wrap(spacing: 12, runSpacing: 12, children: [
        SizedBox(
          width: _w(context),
          child: CustomTextField(
            controller: c.taNumeroCtrl,
            labelText: 'Nº do Termo',
            enabled: c.isEditable,
            validator: validateRequired,
          ),
        ),
        SizedBox(
          width: _w(context),
          child: CustomTextField(
            controller: c.taDataCtrl,
            labelText: 'Data',
            hintText: 'dd/mm/aaaa',
            enabled: c.isEditable,
            validator: validateRequired,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(8),
              TextInputMask(mask: '99/99/9999'),
            ],
            keyboardType: TextInputType.number,
          ),
        ),
        SizedBox(
          width: _w(context),
          child: CustomTextField(
            controller: c.taProcessoCtrl,
            labelText: 'Nº do processo (SEI/Interno)',
            enabled: c.isEditable,
            validator: validateRequired,
          ),
        ),
        SizedBox(
          width: _w(context),
          child: AutocompleteUserClass(
            label: 'Responsável pelo termo',
            controller: c.taResponsavelCtrl,
            allUsers: widget.users,
            enabled: c.isEditable,
            initialUserId: c.taResponsavelUserId,
            validator: validateRequired,
          ),
        ),
      ]),
      const SizedBox(height: 16),
    ]);
  }
}
