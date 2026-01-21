import 'package:flutter/material.dart';

import 'package:siged/_widgets/layout/responsive_utils.dart';
import 'package:siged/_widgets/input/custom_text_field.dart';
import 'package:siged/_widgets/texts/section_text_name.dart';

import 'package:siged/_blocs/modules/contracts/hiring/7Dotacao/dotacao_data.dart';

class SectionNaturezaDespesa extends StatefulWidget {
  final DotacaoData data;
  final bool isEditable;
  final void Function(DotacaoData updated) onChanged;

  const SectionNaturezaDespesa({
    super.key,
    required this.data,
    required this.isEditable,
    required this.onChanged,
  });

  @override
  State<SectionNaturezaDespesa> createState() =>
      _SectionNaturezaDespesaState();
}

class _SectionNaturezaDespesaState extends State<SectionNaturezaDespesa> {
  late final TextEditingController _modalidadeAplicacaoCtrl;
  late final TextEditingController _elementoDespesaCtrl;
  late final TextEditingController _subelementoCtrl;
  late final TextEditingController _descricaoNdCtrl;

  @override
  void initState() {
    super.initState();
    final d = widget.data;

    _modalidadeAplicacaoCtrl =
        TextEditingController(text: d.modalidadeAplicacao ?? '');
    _elementoDespesaCtrl =
        TextEditingController(text: d.elementoDespesa ?? '');
    _subelementoCtrl =
        TextEditingController(text: d.subelemento ?? '');
    _descricaoNdCtrl =
        TextEditingController(text: d.descricaoNd ?? '');
  }

  @override
  void didUpdateWidget(
      covariant SectionNaturezaDespesa oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data != widget.data) {
      final d = widget.data;

      void _sync(TextEditingController c, String? v) {
        final text = v ?? '';
        if (c.text != text) c.text = text;
      }

      _sync(_modalidadeAplicacaoCtrl, d.modalidadeAplicacao);
      _sync(_elementoDespesaCtrl, d.elementoDespesa);
      _sync(_subelementoCtrl, d.subelemento);
      _sync(_descricaoNdCtrl, d.descricaoNd);
    }
  }

  @override
  void dispose() {
    _modalidadeAplicacaoCtrl.dispose();
    _elementoDespesaCtrl.dispose();
    _subelementoCtrl.dispose();
    _descricaoNdCtrl.dispose();
    super.dispose();
  }

  void _emitChange() {
    final updated = widget.data.copyWith(
      modalidadeAplicacao: _modalidadeAplicacaoCtrl.text,
      elementoDespesa: _elementoDespesaCtrl.text,
      subelemento: _subelementoCtrl.text,
      descricaoNd: _descricaoNdCtrl.text,
    );
    widget.onChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(text: '3) Natureza da Despesa'),
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
                    controller: _modalidadeAplicacaoCtrl,
                    labelText: 'Modalidade de aplicação (ex.: 90)',
                    enabled: widget.isEditable,
                    keyboardType: TextInputType.number,
                    onChanged: (_) => _emitChange(),
                  ),
                ),
                SizedBox(
                  width: w4,
                  child: CustomTextField(
                    controller: _elementoDespesaCtrl,
                    labelText: 'Elemento (ex.: 39, 44)',
                    enabled: widget.isEditable,
                    keyboardType: TextInputType.number,
                    onChanged: (_) => _emitChange(),
                  ),
                ),
                SizedBox(
                  width: w4,
                  child: CustomTextField(
                    controller: _subelementoCtrl,
                    labelText: 'Subelemento (quando houver)',
                    enabled: widget.isEditable,
                    onChanged: (_) => _emitChange(),
                  ),
                ),
                SizedBox(
                  width: w4,
                  child: CustomTextField(
                    controller: _descricaoNdCtrl,
                    labelText: 'Descrição da ND',
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
