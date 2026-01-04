import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:siged/_widgets/layout/responsive_utils.dart';
import 'package:siged/_widgets/input/custom_text_field.dart';
import 'package:siged/_widgets/input/drop_down_botton_change.dart';
import 'package:siged/_utils/formats/mask_class.dart';
import 'package:siged/_widgets/texts/section_text_name.dart';

import 'package:siged/_blocs/process/hiring/7Dotacao/dotacao_data.dart';

class SectionEmpenho extends StatefulWidget {
  final DotacaoData data;
  final bool isEditable;
  final void Function(DotacaoData updated) onChanged;

  const SectionEmpenho({
    super.key,
    required this.data,
    required this.isEditable,
    required this.onChanged,
  });

  @override
  State<SectionEmpenho> createState() => _SectionEmpenhoState();
}

class _SectionEmpenhoState extends State<SectionEmpenho> {
  late final TextEditingController _empenhoModalidadeCtrl;
  late final TextEditingController _empenhoNumeroCtrl;
  late final TextEditingController _empenhoDataCtrl;
  late final TextEditingController _empenhoValorCtrl;

  @override
  void initState() {
    super.initState();
    final d = widget.data;

    _empenhoModalidadeCtrl =
        TextEditingController(text: d.empenhoModalidade ?? '');
    _empenhoNumeroCtrl =
        TextEditingController(text: d.empenhoNumero ?? '');
    _empenhoDataCtrl =
        TextEditingController(text: d.empenhoData ?? '');
    _empenhoValorCtrl =
        TextEditingController(text: d.empenhoValor ?? '');
  }

  @override
  void didUpdateWidget(covariant SectionEmpenho oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data != widget.data) {
      final d = widget.data;

      void _sync(TextEditingController c, String? v) {
        final text = v ?? '';
        if (c.text != text) c.text = text;
      }

      _sync(_empenhoModalidadeCtrl, d.empenhoModalidade);
      _sync(_empenhoNumeroCtrl, d.empenhoNumero);
      _sync(_empenhoDataCtrl, d.empenhoData);
      _sync(_empenhoValorCtrl, d.empenhoValor);
    }
  }

  @override
  void dispose() {
    _empenhoModalidadeCtrl.dispose();
    _empenhoNumeroCtrl.dispose();
    _empenhoDataCtrl.dispose();
    _empenhoValorCtrl.dispose();
    super.dispose();
  }

  void _emitChange() {
    final updated = widget.data.copyWith(
      empenhoModalidade: _empenhoModalidadeCtrl.text,
      empenhoNumero: _empenhoNumeroCtrl.text,
      empenhoData: _empenhoDataCtrl.text,
      empenhoValor: _empenhoValorCtrl.text,
    );
    widget.onChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    const modalidades = ['Ordinário', 'Estimativo', 'Global'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(text: '5) Empenho'),
        LayoutBuilder(
          builder: (context, constraints) {
            final w4 = inputW4(context, constraints);

            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: w4,
                  child: DropDownButtonChange(
                    enabled: widget.isEditable,
                    labelText: 'Modalidade de Empenho',
                    controller: _empenhoModalidadeCtrl,
                    items: modalidades,
                    onChanged: (v) {
                      _empenhoModalidadeCtrl.text = v ?? '';
                      _emitChange();
                    },
                  ),
                ),
                SizedBox(
                  width: w4,
                  child: CustomTextField(
                    controller: _empenhoNumeroCtrl,
                    labelText: 'Nº da NE (Nota de Empenho)',
                    enabled: widget.isEditable,
                    onChanged: (_) => _emitChange(),
                  ),
                ),
                SizedBox(
                  width: w4,
                  child: CustomTextField(
                    controller: _empenhoDataCtrl,
                    labelText: 'Data da NE',
                    hintText: 'dd/mm/aaaa',
                    enabled: widget.isEditable,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(8),
                      TextInputMask(mask: '99/99/9999'),
                    ],
                    keyboardType: TextInputType.number,
                    onChanged: (_) => _emitChange(),
                  ),
                ),
                SizedBox(
                  width: w4,
                  child: CustomTextField(
                    controller: _empenhoValorCtrl,
                    labelText: 'Valor Empenhado (R\$)',
                    enabled: widget.isEditable,
                    keyboardType: TextInputType.number,
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
