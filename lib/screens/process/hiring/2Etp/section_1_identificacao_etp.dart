import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';

import 'package:siged/_blocs/system/user/user_bloc.dart';
import 'package:siged/_blocs/system/user/user_data.dart';
import 'package:siged/_blocs/process/hiring/2Etp/etp_controller.dart';

import 'package:siged/_widgets/input/custom_date_field.dart';
import 'package:siged/_widgets/input/custom_text_field.dart';
import 'package:siged/_widgets/autocomplete/autocomplete_user_class.dart';
import 'package:siged/_widgets/texts/section_text_name.dart';
import 'package:siged/_widgets/layout/responsive_utils.dart';
import 'package:siged/_utils/validates/form_validation_mixin.dart';

class SectionIdentificacaoEtp extends StatelessWidget with FormValidationMixin {
  final EtpController controller;
  SectionIdentificacaoEtp({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final users = context.select<UserBloc, List<UserData>>((b) => b.state.all);

    return LayoutBuilder(
      builder: (context, constraints) {
        final w4 = inputW4(context, constraints);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionTitle('1) Identificação / Metadados'),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: w4,
                  child: CustomTextField(
                    controller: c.etpNumeroCtrl,
                    enabled: c.isEditable,
                    labelText: 'Nº ETP / Referência interna',
                    validator: validateRequired,
                  ),
                ),
                SizedBox(
                  width: w4,
                  child: CustomDateField(
                    controller: c.etpDataElaboracaoCtrl,
                    enabled: c.isEditable,
                    labelText: 'Data de elaboração',
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                  ),
                ),
                SizedBox(
                  width: w4,
                  child: AutocompleteUserClass(
                    label: 'Responsável técnico',
                    controller: c.etpResponsavelElaboracaoCtrl,
                    allUsers: users,
                    enabled: c.isEditable,
                    initialUserId: c.etpResponsavelElaboracaoUserId,
                    validator: validateRequired,
                    onChanged: (String? userId) {
                      c.etpResponsavelElaboracaoUserId = userId;
                    },
                  ),
                ),
                SizedBox(
                  width: w4,
                  child: CustomTextField(
                    controller: c.etpArtNumeroCtrl,
                    enabled: c.isEditable,
                    labelText: 'Nº ART (se aplicável)',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }
}
