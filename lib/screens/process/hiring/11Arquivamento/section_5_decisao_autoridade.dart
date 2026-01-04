import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// ===== Users
import 'package:siged/_blocs/system/user/user_bloc.dart';
import 'package:siged/_blocs/system/user/user_data.dart';

// ===== Dados / Inputs
import 'package:siged/_blocs/process/hiring/0Stages/hiring_data.dart';
import 'package:siged/_widgets/input/custom_auto_complete.dart';
import 'package:siged/_widgets/input/custom_date_field.dart';
import 'package:siged/_widgets/input/custom_text_field.dart';
import 'package:siged/_widgets/input/drop_down_botton_change.dart'
    show DropDownButtonChange;


import 'package:siged/_widgets/layout/responsive_utils.dart';
import 'package:siged/_widgets/texts/section_text_name.dart';
import 'package:siged/_utils/formats/mask_class.dart';

import 'package:siged/_blocs/process/hiring/11Arquivamento/termo_arquivamento_data.dart';

class SectionDecisaoAutoridadeTA extends StatefulWidget {
  final TermoArquivamentoData data;
  final bool isEditable;
  final void Function(TermoArquivamentoData updated) onChanged;

  const SectionDecisaoAutoridadeTA({
    super.key,
    required this.data,
    required this.isEditable,
    required this.onChanged,
  });

  @override
  State<SectionDecisaoAutoridadeTA> createState() =>
      _SectionDecisaoAutoridadeTAState();
}

class _SectionDecisaoAutoridadeTAState
    extends State<SectionDecisaoAutoridadeTA> {
  late final TextEditingController _autoridadeCtrl;
  late final TextEditingController _decisaoCtrl;
  late final TextEditingController _dataDecisaoCtrl;
  late final TextEditingController _observacoesCtrl;

  String? _autoridadeUserId;

  @override
  void initState() {
    super.initState();
    final d = widget.data;

    _autoridadeCtrl = TextEditingController(); // texto é UI; modelo guarda ID
    _decisaoCtrl = TextEditingController(text: d.taDecisao ?? '');
    _dataDecisaoCtrl = TextEditingController(text: d.taDataDecisao ?? '');
    _observacoesCtrl =
        TextEditingController(text: d.taObservacoesDecisao ?? '');

    _autoridadeUserId = d.taAutoridadeUserId;
  }

  @override
  void didUpdateWidget(covariant SectionDecisaoAutoridadeTA oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data != widget.data) {
      final d = widget.data;

      void _sync(TextEditingController c, String? v) {
        final text = v ?? '';
        if (c.text != text) c.text = text;
      }

      _sync(_decisaoCtrl, d.taDecisao);
      _sync(_dataDecisaoCtrl, d.taDataDecisao);
      _sync(_observacoesCtrl, d.taObservacoesDecisao);

      _autoridadeUserId = d.taAutoridadeUserId;
    }
  }

  @override
  void dispose() {
    _autoridadeCtrl.dispose();
    _decisaoCtrl.dispose();
    _dataDecisaoCtrl.dispose();
    _observacoesCtrl.dispose();
    super.dispose();
  }

  void _emitChange() {
    final updated = widget.data.copyWith(
      taAutoridadeUserId: _autoridadeUserId,
      taDecisao: _decisaoCtrl.text,
      taDataDecisao: _dataDecisaoCtrl.text,
      taObservacoesDecisao: _observacoesCtrl.text,
    );
    widget.onChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    final users = context.select<UserBloc, List<UserData>>((b) => b.state.all);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(text: '5) Decisão da Autoridade'),
        LayoutBuilder(
          builder: (context, constraints) {
            final w2 = inputW2(context, constraints);

            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: w2,
                  child: Column(
                    children: [
                      SizedBox(
                        width: w2,
                        child: CustomAutoComplete<UserData>(
                          label: 'Autoridade competente',
                          controller: _autoridadeCtrl,
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
                      const SizedBox(height: 12),
                      SizedBox(
                        width: w2,
                        child: DropDownButtonChange(
                          enabled: widget.isEditable,
                          labelText: 'Decisão',
                          controller: _decisaoCtrl,
                          items: HiringData.decisaoArquivamento,
                          onChanged: (v) {
                            _decisaoCtrl.text = v ?? '';
                            _emitChange();
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: w2,
                        child: CustomDateField(
                          controller: _dataDecisaoCtrl,
                          labelText: 'Data da decisão',
                          enabled: widget.isEditable,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(8),
                            TextInputMask(mask: '99/99/9999'),
                          ],
                          onChanged: (_) => _emitChange(),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: w2,
                  child: CustomTextField(
                    controller: _observacoesCtrl,
                    labelText: 'Observações da decisão',
                    maxLines: 7,
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
