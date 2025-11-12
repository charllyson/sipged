import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:siged/_blocs/system/user/user_bloc.dart';
import 'package:siged/_widgets/input/custom_text_field.dart';
import 'package:siged/_widgets/autocomplete/autocomplete_user_class.dart';
import 'package:siged/_utils/validates/form_validation_mixin.dart';
import 'package:siged/_utils/formats/mask_class.dart';
import 'package:flutter/services.dart';

import 'package:siged/_blocs/system/user/user_data.dart';
import 'package:siged/_blocs/process/hiring/2Etp/etp_controller.dart';

class SectionIdentificacaoEtp extends StatelessWidget with FormValidationMixin {
  final EtpController controller;
  SectionIdentificacaoEtp({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final users = context.select<UserBloc, List<UserData>>((b) => b.state.all);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _Title('1) Identificação / Metadados'),
        Wrap(
          spacing: 12, runSpacing: 12,
          children: [
            SizedBox(
              width: _w(context),
              child: CustomTextField(
                controller: c.etpNumeroCtrl,
                enabled: c.isEditable,
                labelText: 'Nº ETP / Referência interna',
                validator: validateRequired,
              ),
            ),
            SizedBox(
              width: _w(context),
              child: CustomTextField(
                controller: c.etpDataElaboracaoCtrl,
                enabled: c.isEditable,
                labelText: 'Data de elaboração',
                hintText: 'dd/mm/aaaa',
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
              width: _w(context),
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
  }

  double _w(BuildContext ctx, {int itemsPerLine = 4}) =>
      MediaQuery.of(ctx).size.width >= 1200 ? (MediaQuery.of(ctx).size.width - 64) / itemsPerLine : 480;

}

class _Title extends StatelessWidget {
  final String text;
  const _Title(this.text);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}
