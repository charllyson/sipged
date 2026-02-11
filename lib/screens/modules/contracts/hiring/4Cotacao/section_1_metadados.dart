import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:siged/_blocs/modules/contracts/hiring/0Stages/hiring_data.dart';
import 'package:siged/_blocs/system/user/user_bloc.dart';
import 'package:siged/_blocs/system/user/user_data.dart';
import 'package:siged/_widgets/input/custom_auto_complete.dart';

import 'package:siged/_widgets/input/custom_date_field.dart';
import 'package:siged/_widgets/texts/section_text_name.dart';
import 'package:siged/_widgets/input/custom_text_field.dart';
import 'package:siged/_widgets/input/drop_down_botton_change.dart';

import 'package:siged/_widgets/layout/responsive_utils.dart';

import 'package:siged/_utils/validates/sipged_validation.dart';
import 'package:siged/_blocs/modules/contracts/hiring/4Cotacao/cotacao_data.dart';

class SectionMetadados extends StatefulWidget {
  final CotacaoData data;
  final bool isEditable;
  final void Function(CotacaoData updated) onChanged;

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
    with SipGedValidation {
  late final TextEditingController _numeroCtrl;
  late final TextEditingController _dataAberturaCtrl;
  late final TextEditingController _dataEncerramentoCtrl;
  late final TextEditingController _responsavelCtrl;
  late final TextEditingController _metodologiaCtrl;

  String? _responsavelUserId;

  @override
  void initState() {
    super.initState();
    final d = widget.data;

    _numeroCtrl = TextEditingController(text: d.numero ?? '');
    _dataAberturaCtrl = TextEditingController(text: d.dataAbertura ?? '');
    _dataEncerramentoCtrl =
        TextEditingController(text: d.dataEncerramento ?? '');
    _responsavelCtrl = TextEditingController(text: d.responsavelNome ?? '');
    _metodologiaCtrl = TextEditingController(text: d.metodologia ?? '');
    _responsavelUserId = d.responsavelUserId;
  }

  @override
  void didUpdateWidget(covariant SectionMetadados oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data != widget.data) {
      final d = widget.data;

      void sync(TextEditingController c, String? v) {
        final text = v ?? '';
        if (c.text != text) c.text = text;
      }

      sync(_numeroCtrl, d.numero);
      sync(_dataAberturaCtrl, d.dataAbertura);
      sync(_dataEncerramentoCtrl, d.dataEncerramento);
      sync(_responsavelCtrl, d.responsavelNome);
      sync(_metodologiaCtrl, d.metodologia);
      _responsavelUserId = d.responsavelUserId;
    }
  }

  @override
  void dispose() {
    _numeroCtrl.dispose();
    _dataAberturaCtrl.dispose();
    _dataEncerramentoCtrl.dispose();
    _responsavelCtrl.dispose();
    _metodologiaCtrl.dispose();
    super.dispose();
  }

  void _emitChange() {
    final updated = widget.data.copyWith(
      numero: _numeroCtrl.text,
      dataAbertura: _dataAberturaCtrl.text,
      dataEncerramento: _dataEncerramentoCtrl.text,
      responsavelNome: _responsavelCtrl.text,
      responsavelUserId: _responsavelUserId,
      metodologia: _metodologiaCtrl.text,
    );
    widget.onChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    final users = context.select<UserBloc, List<UserData>>((b) => b.state.all);

    return LayoutBuilder(
      builder: (context, constraints) {
        final w5 = inputW5(context, constraints);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionTitle(text: '1) Metadados'),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: w5,
                  child: CustomTextField(
                    controller: _numeroCtrl,
                    labelText: 'Nº da cotação / referência',
                    enabled: widget.isEditable,
                    validator: validateRequired,
                    onChanged: (_) => _emitChange(),
                  ),
                ),
                SizedBox(
                  width: w5,
                  child: CustomDateField(
                    controller: _dataAberturaCtrl,
                    labelText: 'Data de abertura',
                    enabled: widget.isEditable,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(8),
                    ],
                    onChanged: (_) => _emitChange(),
                  ),
                ),
                SizedBox(
                  width: w5,
                  child: CustomDateField(
                    controller: _dataEncerramentoCtrl,
                    labelText: 'Data de encerramento',
                    enabled: widget.isEditable,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(8),
                    ],
                    onChanged: (_) => _emitChange(),
                  ),
                ),

                // ✅ Responsável pela pesquisa (genérico)
                SizedBox(
                  width: w5,
                  child: CustomAutoComplete<UserData>(
                    label: 'Responsável pela pesquisa',
                    controller: _responsavelCtrl,
                    enabled: widget.isEditable,
                    allList: users,
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
                  width: w5,
                  child: DropDownButtonChange(
                    enabled: widget.isEditable,
                    labelText: 'Metodologia',
                    controller: _metodologiaCtrl,
                    items: HiringData.metodologia,
                    onChanged: (v) {
                      _metodologiaCtrl.text = v ?? '';
                      _emitChange();
                    },
                    validator: validateRequired,
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
