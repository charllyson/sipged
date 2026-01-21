// lib/screens/modules/contracts/hiring/10Publicacao/section_4_status_prazos.dart
import 'package:flutter/material.dart';

import 'package:siged/_blocs/modules/contracts/hiring/0Stages/hiring_data.dart';
import 'package:siged/_widgets/input/custom_text_field.dart';
import 'package:siged/_widgets/input/drop_down_botton_change.dart'
    show DropDownButtonChange;
import 'package:siged/_widgets/input/drop_down_yes_no.dart';
import 'package:siged/_widgets/layout/responsive_utils.dart';
import 'package:siged/_widgets/texts/section_text_name.dart';

import 'package:siged/_blocs/modules/contracts/hiring/10Publicacao/publicacao_extrato_data.dart';

class SectionStatusPrazos extends StatefulWidget {
  final bool isEditable;
  final PublicacaoExtratoData data;
  final void Function(PublicacaoExtratoData updated) onChanged;

  const SectionStatusPrazos({
    super.key,
    required this.isEditable,
    required this.data,
    required this.onChanged,
  });

  @override
  State<SectionStatusPrazos> createState() => _SectionStatusPrazosState();
}

class _SectionStatusPrazosState extends State<SectionStatusPrazos> {
  late final TextEditingController _statusCtrl;
  late final TextEditingController _prazoLegalCtrl;
  late final TextEditingController _observacoesCtrl;

  @override
  void initState() {
    super.initState();
    _statusCtrl = TextEditingController(text: widget.data.status ?? '');
    _prazoLegalCtrl =
        TextEditingController(text: widget.data.prazoLegal ?? '');
    _observacoesCtrl =
        TextEditingController(text: widget.data.observacoes ?? '');
  }

  @override
  void didUpdateWidget(covariant SectionStatusPrazos oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data != widget.data) {
      _statusCtrl.text = widget.data.status ?? '';
      _prazoLegalCtrl.text = widget.data.prazoLegal ?? '';
      _observacoesCtrl.text = widget.data.observacoes ?? '';
    }
  }

  void _emitChange() {
    final updated = widget.data.copyWith(
      status: _statusCtrl.text,
      prazoLegal: _prazoLegalCtrl.text,
      observacoes: _observacoesCtrl.text,
    );
    widget.onChanged(updated);
  }

  @override
  void dispose() {
    _statusCtrl.dispose();
    _prazoLegalCtrl.dispose();
    _observacoesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(text: '4) Status e Controle de Prazos'),
        LayoutBuilder(
          builder: (context, constraints) {
            final w2 = inputW2(context, constraints);
            inputW1(context, constraints);

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
                        child: DropDownButtonChange(
                          enabled: widget.isEditable,
                          labelText: 'Status',
                          controller: _statusCtrl,
                          items: HiringData.statusPublicacao,
                          onChanged: (v) {
                            _statusCtrl.text = v ?? '';
                            _emitChange();
                            setState(() {});
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: w2,
                        child: YesNoDrop(
                          enabled: widget.isEditable,
                          labelText: 'Prazo legal atendido?',
                          value: _prazoLegalCtrl.text,
                          controller: (val) {
                            _prazoLegalCtrl.text = val ?? '';
                            _emitChange();
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: w2,
                  child: CustomTextField(
                    controller: _observacoesCtrl,
                    labelText: 'Observações / ajustes solicitados',
                    maxLines: 4,
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
