// lib/screens/process/hiring/10Publicacao/section_5_responsavel.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:siged/_blocs/system/user/user_bloc.dart';
import 'package:siged/_blocs/system/user/user_data.dart';
import 'package:siged/_utils/validates/form_validation_mixin.dart';
import 'package:siged/_widgets/autocomplete/autocomplete_user_class.dart';
import 'package:siged/_widgets/layout/responsive_utils.dart';
import 'package:siged/_widgets/texts/section_text_name.dart';

import 'package:siged/_blocs/process/hiring/10Publicacao/publicacao_extrato_data.dart';

class SectionResponsavel extends StatefulWidget {
  final PublicacaoExtratoData data;
  final bool isEditable;
  final ValueChanged<PublicacaoExtratoData> onChanged;

  const SectionResponsavel({
    super.key,
    required this.data,
    required this.isEditable,
    required this.onChanged,
  });

  @override
  State<SectionResponsavel> createState() => _SectionResponsavelState();
}

class _SectionResponsavelState extends State<SectionResponsavel>
    with FormValidationMixin {
  late final TextEditingController _responsavelCtrl;

  @override
  void initState() {
    super.initState();
    // Texto fica apenas para exibição; modelo guarda só o userId
    _responsavelCtrl = TextEditingController();
  }

  @override
  void didUpdateWidget(covariant SectionResponsavel oldWidget) {
    super.didUpdateWidget(oldWidget);
    // O AutocompleteUserClass normalmente gerencia o texto sozinho
    // com base no initialUserId, então não precisamos sincronizar aqui.
  }

  @override
  void dispose() {
    _responsavelCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final users = context.select<UserBloc, List<UserData>>((b) => b.state.all);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle('5) Responsável'),
        LayoutBuilder(
          builder: (context, constraints) {
            final w5 = inputW5(context, constraints);

            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: w5,
                  child: AutocompleteUserClass(
                    label: 'Responsável pela publicação',
                    controller: _responsavelCtrl,
                    allUsers: users,
                    enabled: widget.isEditable,
                    initialUserId: widget.data.responsavelUserId,
                    validator: validateRequired,
                    onChanged: (userId) {
                      final updated = widget.data.copyWith(
                        responsavelUserId:
                        userId.isEmpty ? null : userId,
                      );
                      widget.onChanged(updated);
                    },
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
