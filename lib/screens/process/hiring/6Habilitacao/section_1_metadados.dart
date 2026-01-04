import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:siged/_blocs/system/user/user_bloc.dart';
import 'package:siged/_blocs/system/user/user_data.dart';
import 'package:siged/_blocs/process/hiring/6Habilitacao/habilitacao_data.dart';
import 'package:siged/_widgets/input/custom_auto_complete.dart';

import 'package:siged/_widgets/input/custom_text_field.dart';

import 'package:siged/_widgets/texts/section_text_name.dart';
import 'package:siged/_widgets/layout/responsive_utils.dart';
import 'package:siged/_utils/formats/mask_class.dart';
import 'package:siged/_utils/validates/form_validation_mixin.dart';

class SectionMetadados extends StatefulWidget {
  final HabilitacaoData data;
  final bool isEditable;
  final void Function(HabilitacaoData updated) onChanged;

  const SectionMetadados({
    super.key,
    required this.data,
    required this.isEditable,
    required this.onChanged,
  });

  @override
  State<SectionMetadados> createState() => _SectionMetadadosState();
}

class _SectionMetadadosState extends State<SectionMetadados>
    with FormValidationMixin {
  late final TextEditingController _numeroDossieCtrl;
  late final TextEditingController _dataMontagemCtrl;
  late final TextEditingController _responsavelNomeCtrl;
  late final TextEditingController _linksPastaCtrl;

  String? _responsavelUserId;

  @override
  void initState() {
    super.initState();
    final d = widget.data;

    _numeroDossieCtrl = TextEditingController(text: d.numeroDossie ?? '');
    _dataMontagemCtrl = TextEditingController(text: d.dataMontagem ?? '');
    _responsavelNomeCtrl = TextEditingController(text: d.responsavelNome ?? '');
    _linksPastaCtrl = TextEditingController(text: d.linksPasta ?? '');
    _responsavelUserId = d.responsavelUserId;
  }

  @override
  void didUpdateWidget(covariant SectionMetadados oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data != widget.data) {
      final d = widget.data;

      void _sync(TextEditingController c, String? v) {
        final text = v ?? '';
        if (c.text != text) c.text = text;
      }

      _sync(_numeroDossieCtrl, d.numeroDossie);
      _sync(_dataMontagemCtrl, d.dataMontagem);
      _sync(_responsavelNomeCtrl, d.responsavelNome);
      _sync(_linksPastaCtrl, d.linksPasta);
      _responsavelUserId = d.responsavelUserId;
    }
  }

  @override
  void dispose() {
    _numeroDossieCtrl.dispose();
    _dataMontagemCtrl.dispose();
    _responsavelNomeCtrl.dispose();
    _linksPastaCtrl.dispose();
    super.dispose();
  }

  void _emitChange() {
    final updated = widget.data.copyWith(
      numeroDossie: _numeroDossieCtrl.text,
      dataMontagem: _dataMontagemCtrl.text,
      responsavelNome: _responsavelNomeCtrl.text,
      responsavelUserId: _responsavelUserId,
      linksPasta: _linksPastaCtrl.text,
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
            const SectionTitle(text: '1) Metadados'),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: w4,
                  child: CustomTextField(
                    controller: _numeroDossieCtrl,
                    labelText: 'Nº do dossiê (interno/SEI)',
                    enabled: widget.isEditable,
                    validator: validateRequired,
                    onChanged: (_) => _emitChange(),
                  ),
                ),
                SizedBox(
                  width: w4,
                  child: CustomTextField(
                    controller: _dataMontagemCtrl,
                    labelText: 'Data de montagem',
                    hintText: 'dd/mm/aaaa',
                    enabled: widget.isEditable,
                    validator: validateRequired,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(8),
                      TextInputMask(mask: '99/99/9999'),
                    ],
                    keyboardType: TextInputType.number,
                    onChanged: (_) => _emitChange(),
                  ),
                ),

                // ✅ Responsável pela checagem (genérico)
                SizedBox(
                  width: w4,
                  child: CustomAutoComplete<UserData>(
                    label: 'Responsável pela checagem',
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
                    onChanged: (id) {
                      _responsavelUserId = id.isEmpty ? null : id;
                      _emitChange();
                    },
                  ),
                ),

                SizedBox(
                  width: w4,
                  child: CustomTextField(
                    controller: _linksPastaCtrl,
                    labelText: 'Link da pasta (SEI/Drive/Storage/PNCP)',
                    enabled: widget.isEditable,
                    onChanged: (_) => _emitChange(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }
}
