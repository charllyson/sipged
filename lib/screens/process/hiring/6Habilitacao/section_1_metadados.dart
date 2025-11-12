import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:siged/_blocs/system/user/user_bloc.dart';
import 'package:siged/_blocs/system/user/user_data.dart';
import 'package:siged/_widgets/input/custom_text_field.dart';
import 'package:siged/_widgets/autocomplete/autocomplete_user_class.dart';
import 'package:siged/_widgets/texts/section_text_name.dart';
import 'package:siged/_widgets/layout/responsive_utils.dart';
import 'package:siged/_utils/formats/mask_class.dart';
import 'package:siged/_utils/validates/form_validation_mixin.dart';

import 'package:siged/_blocs/process/hiring/6Habilitacao/habilitacao_controller.dart';

class SectionMetadados extends StatefulWidget {
  final HabilitacaoController controller;
  const SectionMetadados({super.key, required this.controller});

  @override
  State<SectionMetadados> createState() => _SectionMetadadosState();
}

class _SectionMetadadosState extends State<SectionMetadados> with FormValidationMixin {
  double _w(BuildContext ctx, {int itemsPerLine = 4}) => responsiveInputWidth(
    context: ctx, itemsPerLine: itemsPerLine, spacing: 12, margin: 12, extraPadding: 24,
  );

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final users = context.select<UserBloc, List<UserData>>((b) => b.state.all);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle('1) Metadados'),
        Wrap(spacing: 12, runSpacing: 12, children: [
          SizedBox(
            width: _w(context),
            child: CustomTextField(
              controller: c.dgNumeroDossieCtrl,
              labelText: 'Nº do dossiê (interno/SEI)',
              enabled: c.isEditable,
              validator: validateRequired,
            ),
          ),
          SizedBox(
            width: _w(context),
            child: CustomTextField(
              controller: c.dgDataMontagemCtrl,
              labelText: 'Data de montagem',
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
            child: AutocompleteUserClass(
              label: 'Responsável pela checagem',
              controller: c.dgResponsavelCtrl,
              allUsers: users,
              enabled: c.isEditable,
              initialUserId: c.dgResponsavelUserId,
              validator: validateRequired,
              onChanged: (uid) => c.dgResponsavelUserId = uid,
            ),
          ),
          SizedBox(
            width: _w(context),
            child: CustomTextField(
              controller: c.dgLinksPastaCtrl,
              labelText: 'Link da pasta (SEI/Drive/Storage/PNCP)',
              enabled: c.isEditable,
            ),
          ),
        ]),
        const SizedBox(height: 16),
      ],
    );
  }
}
