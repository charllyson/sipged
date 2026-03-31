// lib/screens/modules/contracts/hiring/8Minuta/section_4_gestao_refs.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart'; // ✅ necessário para context.select
import 'package:sipged/_widgets/input/auto_complete_change.dart';

import 'package:sipged/_widgets/layout/responsive_utils.dart';
import 'package:sipged/_widgets/input/text_field_change.dart';
import 'package:sipged/_widgets/input/drop_down_change.dart'
    show DropDownChange;
import 'package:sipged/_widgets/texts/section_text_name.dart';

import 'package:sipged/_blocs/system/user/user_bloc.dart';
import 'package:sipged/_blocs/system/user/user_data.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/8Minuta/minuta_contrato_data.dart';

class SectionGestaoRefs extends StatefulWidget {
  final MinutaContratoData data;
  final bool isEditable;
  final void Function(MinutaContratoData updated) onChanged;

  const SectionGestaoRefs({
    super.key,
    required this.data,
    required this.isEditable,
    required this.onChanged,
  });

  @override
  State<SectionGestaoRefs> createState() => _SectionGestaoRefsState();
}

class _SectionGestaoRefsState extends State<SectionGestaoRefs> {
  late final TextEditingController _gestorNomeCtrl;
  late final TextEditingController _fiscalNomeCtrl;
  late final TextEditingController _regimeExecCtrl;
  late final TextEditingController _prazosRefCtrl;
  late final TextEditingController _linksAnexosCtrl;

  String? _gestorUserId;
  String? _fiscalUserId;

  @override
  void initState() {
    super.initState();
    final d = widget.data;

    _gestorNomeCtrl = TextEditingController(text: d.gestorNome ?? '');
    _fiscalNomeCtrl = TextEditingController(text: d.fiscalNome ?? '');
    _regimeExecCtrl = TextEditingController(text: d.regimeExecucaoRef ?? '');
    _prazosRefCtrl = TextEditingController(text: d.prazosRef ?? '');
    _linksAnexosCtrl = TextEditingController(text: d.linksAnexos ?? '');

    _gestorUserId = d.gestorUserId;
    _fiscalUserId = d.fiscalUserId;
  }

  @override
  void didUpdateWidget(covariant SectionGestaoRefs oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data != widget.data) {
      final d = widget.data;

      void sync(TextEditingController c, String? v) {
        final text = v ?? '';
        if (c.text != text) c.text = text;
      }

      sync(_gestorNomeCtrl, d.gestorNome);
      sync(_fiscalNomeCtrl, d.fiscalNome);
      sync(_regimeExecCtrl, d.regimeExecucaoRef);
      sync(_prazosRefCtrl, d.prazosRef);
      sync(_linksAnexosCtrl, d.linksAnexos);

      _gestorUserId = d.gestorUserId;
      _fiscalUserId = d.fiscalUserId;
    }
  }

  @override
  void dispose() {
    _gestorNomeCtrl.dispose();
    _fiscalNomeCtrl.dispose();
    _regimeExecCtrl.dispose();
    _prazosRefCtrl.dispose();
    _linksAnexosCtrl.dispose();
    super.dispose();
  }

  void _emitChange() {
    final updated = widget.data.copyWith(
      gestorUserId: _gestorUserId,
      gestorNome: _gestorNomeCtrl.text,
      fiscalUserId: _fiscalUserId,
      fiscalNome: _fiscalNomeCtrl.text,
      linksAnexos: _linksAnexosCtrl.text,
      regimeExecucaoRef: _regimeExecCtrl.text,
      prazosRef: _prazosRefCtrl.text,
    );
    widget.onChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    final users = context.select<UserBloc, List<UserData>>((b) => b.state.all);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(text: '4) Gestão e Referências (do TR/Edital)'),
        LayoutBuilder(
          builder: (context, constraints) {
            final w4 = inputW4(context, constraints);
            final w1 = inputW1(context, constraints);

            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                // ✅ Gestor (genérico)
                SizedBox(
                  width: w4,
                  child: AutoCompleteChange<UserData>(
                    label: 'Gestor do contrato (definido no processo)',
                    controller: _gestorNomeCtrl,
                    allList: users,
                    enabled: widget.isEditable,
                    initialId: _gestorUserId,
                    idOf: (u) => u.uid,
                    displayOf: (u) => u.name ?? u.email ?? '',
                    subtitleOf: (u) => u.email ?? '',
                    photoUrlOf: (u) => u.urlPhoto,
                    onChanged: (id) {
                      _gestorUserId = id.isEmpty ? null : id;
                      _emitChange();
                    },
                  ),
                ),

                // ✅ Fiscal (genérico)
                SizedBox(
                  width: w4,
                  child: AutoCompleteChange<UserData>(
                    label: 'Fiscal do contrato (definido no processo)',
                    controller: _fiscalNomeCtrl,
                    allList: users,
                    enabled: widget.isEditable,
                    initialId: _fiscalUserId,
                    idOf: (u) => u.uid,
                    displayOf: (u) => u.name ?? u.email ?? '',
                    subtitleOf: (u) => u.email ?? '',
                    photoUrlOf: (u) => u.urlPhoto,
                    onChanged: (id) {
                      _fiscalUserId = id.isEmpty ? null : id;
                      _emitChange();
                    },
                  ),
                ),

                SizedBox(
                  width: w4,
                  child: DropDownChange(
                    labelText: 'Regime de execução (referência TR)',
                    enabled: widget.isEditable,
                    controller: _regimeExecCtrl,
                    items: const <String>[],
                    onChanged: (v) {
                      _regimeExecCtrl.text = v ?? '';
                      _emitChange();
                    },
                  ),
                ),
                SizedBox(
                  width: w4,
                  child: CustomTextField(
                    enabled: false,
                    controller: _prazosRefCtrl,
                    labelText: 'Prazos/Vigência (referência TR)',
                  ),
                ),
                SizedBox(
                  width: w1,
                  child: CustomTextField(
                    controller: _linksAnexosCtrl,
                    labelText:
                    'Links/Anexos (TR, ETP, ARP, proposta, documentos do gestor)',
                    maxLines: 2,
                    enabled: widget.isEditable,
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
