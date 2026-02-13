// lib/screens/modules/contracts/hiring/2Etp/section_1_identificacao_etp.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sipged/_blocs/system/user/user_bloc.dart';
import 'package:sipged/_blocs/system/user/user_data.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/2Etp/etp_data.dart';
import 'package:sipged/_widgets/input/custom_auto_complete.dart';

import 'package:sipged/_widgets/input/custom_date_field.dart';
import 'package:sipged/_widgets/input/custom_text_field.dart';

import 'package:sipged/_widgets/texts/section_text_name.dart';
import 'package:sipged/_widgets/layout/responsive_utils.dart';
import 'package:sipged/_utils/validates/sipged_validation.dart';


class SectionIdentificacaoEtp extends StatefulWidget {
  final bool isEditable;
  final EtpData data;
  final void Function(EtpData updated) onChanged;

  const SectionIdentificacaoEtp({
    super.key,
    required this.isEditable,
    required this.data,
    required this.onChanged,
  });

  @override
  State<SectionIdentificacaoEtp> createState() => _SectionIdentificacaoEtpState();
}

class _SectionIdentificacaoEtpState extends State<SectionIdentificacaoEtp>
    with SipGedValidation {
  late final TextEditingController _numeroCtrl;
  late final TextEditingController _dataElaboracaoCtrl;
  late final TextEditingController _responsavelNomeCtrl;
  late final TextEditingController _artNumeroCtrl;

  String? _responsavelUserId;

  @override
  void initState() {
    super.initState();
    final d = widget.data;

    _numeroCtrl = TextEditingController(text: d.numero ?? '');
    _dataElaboracaoCtrl = TextEditingController(text: d.dataElaboracao ?? '');
    _responsavelNomeCtrl =
        TextEditingController(text: d.responsavelElaboracaoNome ?? '');
    _artNumeroCtrl = TextEditingController(text: d.artNumero ?? '');

    _responsavelUserId = d.responsavelElaboracaoUserId;
  }

  @override
  void didUpdateWidget(covariant SectionIdentificacaoEtp oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data != widget.data) {
      final d = widget.data;

      void sync(TextEditingController c, String? value) {
        final v = value ?? '';
        if (c.text != v) c.text = v;
      }

      sync(_numeroCtrl, d.numero);
      sync(_dataElaboracaoCtrl, d.dataElaboracao);
      sync(_responsavelNomeCtrl, d.responsavelElaboracaoNome);
      sync(_artNumeroCtrl, d.artNumero);

      _responsavelUserId = d.responsavelElaboracaoUserId;
    }
  }

  @override
  void dispose() {
    _numeroCtrl.dispose();
    _dataElaboracaoCtrl.dispose();
    _responsavelNomeCtrl.dispose();
    _artNumeroCtrl.dispose();
    super.dispose();
  }

  void _emitChange() {
    final updated = widget.data.copyWith(
      numero: _numeroCtrl.text,
      dataElaboracao: _dataElaboracaoCtrl.text,
      responsavelElaboracaoUserId: _responsavelUserId,
      responsavelElaboracaoNome: _responsavelNomeCtrl.text,
      artNumero: _artNumeroCtrl.text,
    );
    widget.onChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    final users = context.select<UserBloc, List<UserData>>((b) => b.state.all);

    return LayoutBuilder(
      builder: (context, constraints) {
        final w4 = inputW4(context, constraints);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionTitle(text: '1) Identificação / Metadados'),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: w4,
                  child: CustomTextField(
                    controller: _numeroCtrl,
                    enabled: widget.isEditable,
                    labelText: 'Nº ETP / Referência interna',
                    validator: validateRequired,
                    onChanged: (_) => _emitChange(),
                  ),
                ),
                SizedBox(
                  width: w4,
                  child: CustomDateField(
                    controller: _dataElaboracaoCtrl,
                    enabled: widget.isEditable,
                    labelText: 'Data de elaboração',
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    onChanged: (_) => _emitChange(),
                  ),
                ),

                // ✅ Responsável técnico (agora genérico)
                SizedBox(
                  width: w4,
                  child: CustomAutoComplete<UserData>(
                    label: 'Responsável técnico',
                    controller: _responsavelNomeCtrl,
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
                    onChanged: (String id) {
                      _responsavelUserId = id.isEmpty ? null : id;

                      // Opcional: reforçar nome com base no user selecionado
                      if (id.isNotEmpty) {
                        final u = users.cast<UserData?>().firstWhere(
                              (e) => (e?.uid ?? '') == id,
                          orElse: () => null,
                        );
                        if (u != null) {
                          _responsavelNomeCtrl.text = u.name ?? u.email ?? '';
                        }
                      }

                      _emitChange();
                    },
                  ),
                ),

                SizedBox(
                  width: w4,
                  child: CustomTextField(
                    controller: _artNumeroCtrl,
                    enabled: widget.isEditable,
                    labelText: 'Nº ART (se aplicável)',
                    onChanged: (_) => _emitChange(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }
}
