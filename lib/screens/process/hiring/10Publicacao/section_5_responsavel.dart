import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:siged/_blocs/system/user/user_bloc.dart';
import 'package:siged/_blocs/system/user/user_data.dart';
import 'package:siged/_utils/validates/form_validation_mixin.dart';
import 'package:siged/_widgets/input/custom_auto_complete.dart';

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

  // ✅ guardamos o ID localmente para validar por ID
  String? _responsavelUserId;

  @override
  void initState() {
    super.initState();
    _responsavelCtrl = TextEditingController();
    _responsavelUserId = widget.data.responsavelUserId;
  }

  @override
  void didUpdateWidget(covariant SectionResponsavel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data != widget.data) {
      _responsavelUserId = widget.data.responsavelUserId;
    }
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
        const SectionTitle(text: '5) Responsável'),
        LayoutBuilder(
          builder: (context, constraints) {
            final w5 = inputW5(context, constraints);

            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: w5,
                  child: CustomAutoComplete<UserData>(
                    label: 'Responsável pela publicação',
                    controller: _responsavelCtrl,
                    allList: users,
                    enabled: widget.isEditable,
                    initialId: _responsavelUserId,
                    idOf: (u) => u.uid,
                    displayOf: (u) => u.name ?? u.email ?? '',
                    subtitleOf: (u) => u.email ?? '',
                    photoUrlOf: (u) => u.urlPhoto,
                    validator: (v) {
                      if (!widget.isEditable) return null;
                      return (_responsavelUserId ?? '').isNotEmpty
                          ? null
                          : 'Campo obrigatório';
                    },
                    onChanged: (id) {
                      _responsavelUserId = id.isEmpty ? null : id;

                      final updated = widget.data.copyWith(
                        responsavelUserId: _responsavelUserId,
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
