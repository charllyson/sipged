import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:siged/_widgets/input/custom_date_field.dart';

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

  SectionMetadados({
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
        const SectionTitle('1) Metadados'),
        LayoutBuilder(
          builder: (context, constraints) {
            final w4 = inputW4(context, constraints);

            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: w4,
                  child: CustomTextField(
                    controller: c.pjNumeroCtrl,
                    labelText: 'Nº do parecer',
                    enabled: c.isEditable,
                    validator: validateRequired,
                  ),
                ),
                SizedBox(
                  width: w4,
                  child: CustomDateField(
                    controller: c.pjDataCtrl,
                    labelText: 'Data do parecer',
                    enabled: c.isEditable,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(8),
                      TextInputMask(mask: '99/99/9999'),
                    ],
                  ),
                ),
                SizedBox(
                  width: w4,
                  child: CustomTextField(
                    controller: c.pjOrgaoJuridicoCtrl,
                    labelText: 'Órgão/Unidade jurídica',
                    enabled: c.isEditable,
                    validator: validateRequired,
                  ),
                ),
                SizedBox(
                  width: w4,
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
              ],
            );
          },
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
