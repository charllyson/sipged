import 'package:flutter/material.dart';
import 'package:sipged/_widgets/input/custom_auto_complete.dart';

import 'package:sipged/_widgets/layout/responsive_utils.dart';
import 'package:sipged/_widgets/input/custom_text_field.dart';
import 'package:sipged/_widgets/texts/section_text_name.dart';
import 'package:sipged/_blocs/system/user/user_data.dart';

import 'package:sipged/_blocs/modules/contracts/hiring/9Juridico/parecer_juridico_data.dart';

class SectionAssinaturas extends StatefulWidget {
  final ParecerJuridicoData data;
  final bool isEditable;
  final List<UserData> users;
  final void Function(ParecerJuridicoData updated) onChanged;

  const SectionAssinaturas({
    super.key,
    required this.data,
    required this.isEditable,
    required this.users,
    required this.onChanged,
  });

  @override
  State<SectionAssinaturas> createState() => _SectionAssinaturasState();
}

class _SectionAssinaturasState extends State<SectionAssinaturas> {
  late final TextEditingController _autoridadeNomeCtrl;
  late final TextEditingController _localCtrl;
  late final TextEditingController _observacoesFinaisCtrl;

  String? _autoridadeUserId;

  @override
  void initState() {
    super.initState();
    _autoridadeNomeCtrl =
        TextEditingController(text: widget.data.autoridadeNome ?? '');
    _localCtrl = TextEditingController(text: widget.data.local ?? '');
    _observacoesFinaisCtrl =
        TextEditingController(text: widget.data.observacoesFinais ?? '');
    _autoridadeUserId = widget.data.autoridadeUserId;
  }

  @override
  void didUpdateWidget(covariant SectionAssinaturas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data != widget.data) {
      _autoridadeNomeCtrl.text = widget.data.autoridadeNome ?? '';
      _localCtrl.text = widget.data.local ?? '';
      _observacoesFinaisCtrl.text = widget.data.observacoesFinais ?? '';
      _autoridadeUserId = widget.data.autoridadeUserId;
    }
  }

  @override
  void dispose() {
    _autoridadeNomeCtrl.dispose();
    _localCtrl.dispose();
    _observacoesFinaisCtrl.dispose();
    super.dispose();
  }

  void _emitChange() {
    final updated = widget.data.copyWith(
      autoridadeUserId: _autoridadeUserId,
      autoridadeNome: _autoridadeNomeCtrl.text,
      local: _localCtrl.text,
      observacoesFinais: _observacoesFinaisCtrl.text,
    );
    widget.onChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    final users = widget.users;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(text: '6) Assinaturas / Referências finais'),
        LayoutBuilder(
          builder: (context, constraints) {
            final w2 = inputW2(context, constraints);
            final w1 = inputW1(context, constraints);

            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: w2,
                  child: CustomAutoComplete<UserData>(
                    label: 'Autoridade que aprovou o parecer',
                    controller: _autoridadeNomeCtrl,
                    allList: users,
                    enabled: widget.isEditable,
                    initialId: _autoridadeUserId,
                    idOf: (u) => u.uid,
                    displayOf: (u) => u.name ?? u.email ?? '',
                    subtitleOf: (u) => u.email ?? '',
                    photoUrlOf: (u) => u.urlPhoto,
                    onChanged: (id) {
                      _autoridadeUserId = id.isEmpty ? null : id;
                      _emitChange();
                    },
                  ),
                ),
                SizedBox(
                  width: w2,
                  child: CustomTextField(
                    controller: _localCtrl,
                    labelText: 'Local',
                    enabled: widget.isEditable,
                    onChanged: (_) => _emitChange(),
                  ),
                ),
                SizedBox(
                  width: w1,
                  child: CustomTextField(
                    controller: _observacoesFinaisCtrl,
                    labelText: 'Observações finais',
                    maxLines: 2,
                    enabled: widget.isEditable,
                    textAlignVertical: TextAlignVertical.top,
                    onChanged: (_) => _emitChange(),
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
