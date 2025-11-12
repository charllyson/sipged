import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:siged/_blocs/system/user/user_bloc.dart';
import 'package:siged/_blocs/system/user/user_data.dart';
import 'package:siged/_utils/validates/form_validation_mixin.dart';
import 'package:siged/_widgets/autocomplete/autocomplete_user_class.dart';
import 'package:siged/_widgets/layout/responsive_utils.dart';
import 'package:siged/_widgets/texts/section_text_name.dart';
import 'package:siged/_blocs/process/hiring/10Publicacao/publicacao_extrato_controller.dart';

class SectionResponsavel extends StatefulWidget {
  final PublicacaoExtratoController controller;
  const SectionResponsavel({super.key, required this.controller});

  @override
  State<SectionResponsavel> createState() => _SectionResponsavelState();
}

class _SectionResponsavelState extends State<SectionResponsavel>
    with FormValidationMixin {
  double _w(BuildContext ctx, {int itemsPerLine = 3}) => responsiveInputWidth(
    context: ctx,
    itemsPerLine: itemsPerLine,
    spacing: 12,
    margin: 12,
    extraPadding: 24,
  );

  @override
  Widget build(BuildContext context) {
    final users = context.select<UserBloc, List<UserData>>((b) => b.state.all);
    final c = widget.controller;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SectionTitle('5) Responsável'),
      Wrap(spacing: 12, runSpacing: 12, children: [
        SizedBox(
          width: _w(context),
          child: AutocompleteUserClass(
            label: 'Responsável pela publicação',
            controller: c.peResponsavelCtrl,
            allUsers: users,
            enabled: c.isEditable,
            initialUserId: c.peResponsavelUserId,
            validator: validateRequired,
          ),
        ),
      ]),
      const SizedBox(height: 24),
    ]);
  }
}
