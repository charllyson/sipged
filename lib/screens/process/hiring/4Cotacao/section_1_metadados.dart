import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:siged/_blocs/system/user/user_bloc.dart';
import 'package:siged/_widgets/texts/section_text_name.dart';
import 'package:siged/_widgets/input/custom_text_field.dart';
import 'package:siged/_widgets/input/drop_down_botton_change.dart';
import 'package:siged/_widgets/autocomplete/autocomplete_user_class.dart';
import 'package:siged/_utils/validates/form_validation_mixin.dart';
import 'package:siged/_utils/formats/mask_class.dart';
import 'package:flutter/services.dart';

import 'package:siged/_blocs/system/user/user_data.dart';
import 'package:siged/_widgets/layout/responsive_utils.dart';
import 'package:siged/_blocs/process/hiring/4Cotacao/cotacao_controller.dart';

class SectionMetadados extends StatelessWidget with FormValidationMixin {
  final CotacaoController c;
  SectionMetadados({super.key, required this.c});

  double _w(BuildContext ctx, {int itemsPerLine = 4}) =>
      responsiveInputWidth(context: ctx, itemsPerLine: itemsPerLine, spacing: 12, margin: 12, extraPadding: 24);

  @override
  Widget build(BuildContext context) {
    final c = this.c;
    final users = context.select<UserBloc, List<UserData>>((b) => b.state.all);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle('1) Metadados'),
        Wrap(spacing: 12, runSpacing: 12, children: [
          SizedBox(
            width: _w(context),
            child: CustomTextField(
              controller: c.ctNumeroCtrl,
              labelText: 'Nº da cotação / referência',
              enabled: c.isEditable,
              validator: validateRequired,
            ),
          ),
          SizedBox(
            width: _w(context),
            child: CustomTextField(
              controller: c.ctDataAberturaCtrl,
              labelText: 'Data de abertura',
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
              controller: c.ctDataEncerramentoCtrl,
              labelText: 'Data de encerramento',
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
            width: _w(context),
            child: AutocompleteUserClass(
              label: 'Responsável pela pesquisa',
              controller: c.ctResponsavelCtrl,
              enabled: c.isEditable,
              allUsers: users,
              initialUserId: c.ctResponsavelUserId,
              validator: validateRequired,
            ),
          ),
          SizedBox(
            width: _w(context),
            child: DropDownButtonChange(
              enabled: c.isEditable,
              labelText: 'Metodologia',
              controller: c.ctMetodologiaCtrl,
              items: const ['SINAPI', 'Painel de Preços', 'Cotações diretas', 'Misto'],
              onChanged: (v) => c.ctMetodologiaCtrl.text = v ?? '',
              validator: validateRequired,
            ),
          ),
        ]),
      ],
    );
  }
}
