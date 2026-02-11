import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:siged/_widgets/input/custom_auto_complete.dart';

import 'package:siged/_widgets/layout/responsive_utils.dart';
import 'package:siged/_widgets/input/custom_text_field.dart';

import 'package:siged/_widgets/texts/section_text_name.dart';
import 'package:siged/_utils/validates/sipged_validation.dart';

import 'package:siged/_blocs/system/user/user_bloc.dart';
import 'package:siged/_blocs/system/user/user_data.dart';
import 'package:siged/_blocs/modules/contracts/hiring/7Dotacao/dotacao_data.dart';

class SectionIdentificacao extends StatefulWidget {
  final DotacaoData data;
  final bool isEditable;
  final void Function(DotacaoData updated) onChanged;

  const SectionIdentificacao({
    super.key,
    required this.data,
    required this.isEditable,
    required this.onChanged,
  });

  @override
  State<SectionIdentificacao> createState() => _SectionIdentificacaoState();
}

class _SectionIdentificacaoState extends State<SectionIdentificacao>
    with SipGedValidation {
  late final TextEditingController _exercicioCtrl;
  late final TextEditingController _processoSeiCtrl;
  late final TextEditingController _responsavelNomeCtrl;

  String? _responsavelUserId;

  @override
  void initState() {
    super.initState();
    final d = widget.data;

    _exercicioCtrl = TextEditingController(text: d.exercicio ?? '');
    _processoSeiCtrl = TextEditingController(text: d.processoSei ?? '');
    _responsavelNomeCtrl =
        TextEditingController(text: d.responsavelOrcNome ?? '');
    _responsavelUserId = d.responsavelOrcUserId;
  }

  @override
  void didUpdateWidget(covariant SectionIdentificacao oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data != widget.data) {
      final d = widget.data;

      void sync(TextEditingController c, String? v) {
        final text = v ?? '';
        if (c.text != text) c.text = text;
      }

      sync(_exercicioCtrl, d.exercicio);
      sync(_processoSeiCtrl, d.processoSei);
      sync(_responsavelNomeCtrl, d.responsavelOrcNome);
      _responsavelUserId = d.responsavelOrcUserId;
    }
  }

  @override
  void dispose() {
    _exercicioCtrl.dispose();
    _processoSeiCtrl.dispose();
    _responsavelNomeCtrl.dispose();
    super.dispose();
  }

  void _emitChange() {
    final updated = widget.data.copyWith(
      exercicio: _exercicioCtrl.text,
      processoSei: _processoSeiCtrl.text,
      responsavelOrcNome: _responsavelNomeCtrl.text,
      responsavelOrcUserId: _responsavelUserId,
    );
    widget.onChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    final users = context.select<UserBloc, List<UserData>>((b) => b.state.all);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(text: '1) Identificação / Exercício'),
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
                    controller: _exercicioCtrl,
                    labelText: 'Exercício (ano)',
                    enabled: widget.isEditable,
                    keyboardType: TextInputType.number,
                    onChanged: (_) => _emitChange(),
                  ),
                ),
                SizedBox(
                  width: w4,
                  child: CustomTextField(
                    controller: _processoSeiCtrl,
                    labelText: 'Nº do processo (SEI/Interno)',
                    enabled: widget.isEditable,
                    validator: validateRequired,
                    onChanged: (_) => _emitChange(),
                  ),
                ),

                SizedBox(
                  width: w4,
                  child: CustomAutoComplete<UserData>(
                    label: 'Responsável orçamentário',
                    controller: _responsavelNomeCtrl,
                    initialId: _responsavelUserId,
                    allList: users,
                    enabled: widget.isEditable,
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
                      _emitChange();
                    },
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
