// lib/screens/modules/contracts/hiring/3Tr/section_5_obrigacoes_equipe_gestao.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sipged/_widgets/input/auto_complete_change.dart';

import 'package:sipged/_widgets/texts/section_text_name.dart';
import 'package:sipged/_widgets/input/text_field_change.dart';
import 'package:sipged/_widgets/input/drop_down_change.dart';

import 'package:sipged/_widgets/layout/responsive_utils.dart';

import 'package:sipged/_blocs/system/user/user_bloc.dart';
import 'package:sipged/_blocs/system/user/user_data.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/3Tr/tr_data.dart';

class SectionObrigacoesEquipeGestao extends StatefulWidget {
  final bool isEditable;
  final TrData data;
  final void Function(TrData updated) onChanged;

  const SectionObrigacoesEquipeGestao({
    super.key,
    required this.isEditable,
    required this.data,
    required this.onChanged,
  });

  @override
  State<SectionObrigacoesEquipeGestao> createState() =>
      _SectionObrigacoesEquipeGestaoState();
}

class _SectionObrigacoesEquipeGestaoState
    extends State<SectionObrigacoesEquipeGestao> {
  late final TextEditingController _equipeMinimaCtrl;
  late final TextEditingController _fiscalCtrl;
  late final TextEditingController _gestorCtrl;
  late final TextEditingController _obrContratadaCtrl;
  late final TextEditingController _obrContratanteCtrl;

  String? _fiscalUserId;
  String? _gestorUserId;

  @override
  void initState() {
    super.initState();
    final d = widget.data;

    _equipeMinimaCtrl = TextEditingController(text: d.equipeMinima ?? '');
    _fiscalCtrl = TextEditingController(text: d.fiscalNome ?? '');
    _gestorCtrl = TextEditingController(text: d.gestorNome ?? '');
    _obrContratadaCtrl =
        TextEditingController(text: d.obrigacoesContratada ?? '');
    _obrContratanteCtrl =
        TextEditingController(text: d.obrigacoesContratante ?? '');

    _fiscalUserId = d.fiscalUserId;
    _gestorUserId = d.gestorUserId;
  }

  @override
  void didUpdateWidget(covariant SectionObrigacoesEquipeGestao oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data != widget.data) {
      final d = widget.data;

      void sync(TextEditingController c, String? v) {
        final nv = v ?? '';
        if (c.text != nv) c.text = nv;
      }

      sync(_equipeMinimaCtrl, d.equipeMinima);
      sync(_fiscalCtrl, d.fiscalNome);
      sync(_gestorCtrl, d.gestorNome);
      sync(_obrContratadaCtrl, d.obrigacoesContratada);
      sync(_obrContratanteCtrl, d.obrigacoesContratante);

      _fiscalUserId = d.fiscalUserId;
      _gestorUserId = d.gestorUserId;
    }
  }

  @override
  void dispose() {
    _equipeMinimaCtrl.dispose();
    _fiscalCtrl.dispose();
    _gestorCtrl.dispose();
    _obrContratadaCtrl.dispose();
    _obrContratanteCtrl.dispose();
    super.dispose();
  }

  void _emitChange() {
    final updated = widget.data.copyWith(
      equipeMinima: _equipeMinimaCtrl.text,
      fiscalNome: _fiscalCtrl.text,
      fiscalUserId: _fiscalUserId,
      gestorNome: _gestorCtrl.text,
      gestorUserId: _gestorUserId,
      obrigacoesContratada: _obrContratadaCtrl.text,
      obrigacoesContratante: _obrContratanteCtrl.text,
    );
    widget.onChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    final users = context.select<UserBloc, List<UserData>>((b) => b.state.all);

    return LayoutBuilder(
      builder: (context, constraints) {
        final w3 = inputW3(context, constraints);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionTitle(text: '5) Obrigações, Equipe e Gestão'),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: w3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: w3,
                        child: DropDownChange(
                          enabled: widget.isEditable,
                          labelText: 'Equipe mínima exigida',
                          controller: _equipeMinimaCtrl,
                          items: const [
                            'Eng. civil + técnico de obras',
                            'Eng. civil + encarregado + laboratório',
                            'A definir no TR',
                          ],
                          onChanged: (v) {
                            _equipeMinimaCtrl.text = v ?? '';
                            _emitChange();
                            setState(() {});
                          },
                        ),
                      ),
                      const SizedBox(height: 12),

                      // ✅ Fiscal (genérico)
                      SizedBox(
                        width: w3,
                        child: AutoCompleteChange<UserData>(
                          label: 'Fiscal do contrato (indicativo)',
                          controller: _fiscalCtrl,
                          enabled: widget.isEditable,
                          allList: users,
                          initialId: _fiscalUserId,
                          idOf: (u) => u.uid,
                          displayOf: (u) => u.name ?? u.email ?? '',
                          subtitleOf: (u) => u.email ?? '',
                          photoUrlOf: (u) => u.urlPhoto,
                          onChanged: (id) {
                            _fiscalUserId = id.isEmpty ? null : id;
                            _emitChange();
                            setState(() {});
                          },
                        ),
                      ),
                      const SizedBox(height: 12),

                      // ✅ Gestor (genérico)
                      SizedBox(
                        width: w3,
                        child: AutoCompleteChange<UserData>(
                          label: 'Gestor do contrato (indicativo)',
                          controller: _gestorCtrl,
                          enabled: widget.isEditable,
                          allList: users,
                          initialId: _gestorUserId,
                          idOf: (u) => u.uid,
                          displayOf: (u) => u.name ?? u.email ?? '',
                          subtitleOf: (u) => u.email ?? '',
                          photoUrlOf: (u) => u.urlPhoto,
                          onChanged: (id) {
                            _gestorUserId = id.isEmpty ? null : id;
                            _emitChange();
                            setState(() {});
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: w3,
                  child: CustomTextField(
                    controller: _obrContratadaCtrl,
                    labelText: 'Obrigações da contratada',
                    maxLines: 7,
                    enabled: widget.isEditable,
                    onChanged: (_) => _emitChange(),
                  ),
                ),
                SizedBox(
                  width: w3,
                  child: CustomTextField(
                    controller: _obrContratanteCtrl,
                    labelText: 'Obrigações da contratante',
                    maxLines: 7,
                    enabled: widget.isEditable,
                    onChanged: (_) => _emitChange(),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
