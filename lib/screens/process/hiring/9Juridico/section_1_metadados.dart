import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:siged/_widgets/layout/responsive_utils.dart';
import 'package:siged/_widgets/input/custom_text_field.dart';
import 'package:siged/_widgets/texts/section_text_name.dart';
import 'package:siged/_utils/validates/form_validation_mixin.dart';
import 'package:siged/_utils/formats/mask_class.dart';
import 'package:siged/_blocs/system/user/user_data.dart';
import 'package:siged/_widgets/autocomplete/autocomplete_user_class.dart';
import 'package:siged/_blocs/process/hiring/9Juridico/parecer_juridico_controller.dart';

class SectionMetadados extends StatelessWidget with FormValidationMixin {
  final ParecerJuridicoController controller;
  final List<UserData> users;
  SectionMetadados({super.key, required this.controller, required this.users});

  double _w(BuildContext ctx, {int itemsPerLine = 4}) => responsiveInputWidth(
    context: ctx, itemsPerLine: itemsPerLine, spacing: 12, margin: 12, extraPadding: 24,
  );

  @override
  Widget build(BuildContext context) {
    final c = controller;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle('1) Metadados'),
        Wrap(spacing: 12, runSpacing: 12, children: [
          SizedBox(
            width: _w(context),
            child: CustomTextField(
              controller: c.pjNumeroCtrl,
              labelText: 'Nº do parecer',
              enabled: c.isEditable,
              validator: validateRequired,
            ),
          ),
          SizedBox(
            width: _w(context),
            child: CustomTextField(
              controller: c.pjDataCtrl,
              labelText: 'Data do parecer',
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
              controller: c.pjOrgaoJuridicoCtrl,
              labelText: 'Órgão/Unidade jurídica',
              enabled: c.isEditable,
              validator: validateRequired,
            ),
          ),
          SizedBox(
            width: _w(context),
            child: AutocompleteUserClass(
              label: 'Parecerista',
              controller: c.pjPareceristaCtrl,
              allUsers: users,
              enabled: c.isEditable,
              initialUserId: c.pjPareceristaUserId,
              onChanged: (u) => c.pjPareceristaUserId = u,
              validator: validateRequired,
            ),
          ),
        ]),
        const SizedBox(height: 16),
      ],
    );
  }
}
