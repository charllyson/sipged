// lib/screens/process/hiring/8Minuta/section_1_identificacao.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:siged/_widgets/layout/responsive_utils.dart';
import 'package:siged/_widgets/input/custom_text_field.dart';
import 'package:siged/_widgets/texts/section_text_name.dart';
import 'package:siged/_utils/validates/form_validation_mixin.dart';
import 'package:siged/_utils/formats/mask_class.dart';

import 'package:siged/_blocs/process/hiring/8Minuta/minuta_contrato_data.dart';

class SectionIdentificacao extends StatefulWidget {
  final MinutaContratoData data;
  final bool isEditable;
  final void Function(MinutaContratoData updated) onChanged;

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
    with FormValidationMixin {
  late final TextEditingController _numeroCtrl;
  late final TextEditingController _versaoCtrl;
  late final TextEditingController _dataElabCtrl;

  @override
  void initState() {
    super.initState();
    final d = widget.data;

    _numeroCtrl = TextEditingController(text: d.numero ?? '');
    _versaoCtrl = TextEditingController(text: d.versao ?? '');
    _dataElabCtrl = TextEditingController(text: d.dataElaboracao ?? '');
  }

  @override
  void didUpdateWidget(covariant SectionIdentificacao oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data != widget.data) {
      final d = widget.data;

      void _sync(TextEditingController c, String? v) {
        final text = v ?? '';
        if (c.text != text) c.text = text;
      }

      _sync(_numeroCtrl, d.numero);
      _sync(_versaoCtrl, d.versao);
      _sync(_dataElabCtrl, d.dataElaboracao);
    }
  }

  @override
  void dispose() {
    _numeroCtrl.dispose();
    _versaoCtrl.dispose();
    _dataElabCtrl.dispose();
    super.dispose();
  }

  void _emitChange() {
    final updated = widget.data.copyWith(
      numero: _numeroCtrl.text,
      versao: _versaoCtrl.text,
      dataElaboracao: _dataElabCtrl.text,
    );
    widget.onChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(text: '1) Identificação da Minuta'),
        LayoutBuilder(
          builder: (context, constraints) {
            final w3 = inputW3(context, constraints);

            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: w3,
                  child: CustomTextField(
                    controller: _numeroCtrl,
                    labelText: 'Nº da Minuta / Referência',
                    enabled: widget.isEditable,
                    validator: validateRequired,
                    onChanged: (_) => _emitChange(),
                  ),
                ),
                SizedBox(
                  width: w3,
                  child: CustomTextField(
                    controller: _versaoCtrl,
                    labelText: 'Versão',
                    enabled: widget.isEditable,
                    onChanged: (_) => _emitChange(),
                  ),
                ),
                SizedBox(
                  width: w3,
                  child: CustomTextField(
                    controller: _dataElabCtrl,
                    labelText: 'Data de elaboração',
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
              ],
            );
          },
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
