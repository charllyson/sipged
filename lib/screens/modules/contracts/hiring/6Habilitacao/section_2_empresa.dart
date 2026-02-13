import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sipged/_utils/mask/sipged_masks.dart';

import 'package:sipged/_widgets/input/custom_text_field.dart';
import 'package:sipged/_widgets/texts/section_text_name.dart';
import 'package:sipged/_widgets/layout/responsive_utils.dart';
import 'package:sipged/_utils/validates/sipged_validation.dart';

import 'package:sipged/_blocs/modules/contracts/hiring/6Habilitacao/habilitacao_data.dart';

class SectionEmpresa extends StatefulWidget {
  final HabilitacaoData data;
  final bool isEditable;
  final void Function(HabilitacaoData updated) onChanged;

  const SectionEmpresa({
    super.key,
    required this.data,
    required this.isEditable,
    required this.onChanged,
  });

  @override
  State<SectionEmpresa> createState() => _SectionEmpresaState();
}

class _SectionEmpresaState extends State<SectionEmpresa>
    with SipGedValidation {
  late final TextEditingController _razaoSocialCtrl;
  late final TextEditingController _cnpjCtrl;
  late final TextEditingController _sociosRepresentantesCtrl;

  @override
  void initState() {
    super.initState();
    final d = widget.data;

    _razaoSocialCtrl =
        TextEditingController(text: d.razaoSocial ?? '');
    _cnpjCtrl = TextEditingController(text: d.cnpj ?? '');
    _sociosRepresentantesCtrl =
        TextEditingController(text: d.sociosRepresentantes ?? '');
  }

  @override
  void didUpdateWidget(covariant SectionEmpresa oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data != widget.data) {
      final d = widget.data;

      void sync(TextEditingController c, String? v) {
        final text = v ?? '';
        if (c.text != text) c.text = text;
      }

      sync(_razaoSocialCtrl, d.razaoSocial);
      sync(_cnpjCtrl, d.cnpj);
      sync(_sociosRepresentantesCtrl, d.sociosRepresentantes);
    }
  }

  @override
  void dispose() {
    _razaoSocialCtrl.dispose();
    _cnpjCtrl.dispose();
    _sociosRepresentantesCtrl.dispose();
    super.dispose();
  }

  void _emitChange() {
    final updated = widget.data.copyWith(
      razaoSocial: _razaoSocialCtrl.text,
      cnpj: _cnpjCtrl.text,
      sociosRepresentantes: _sociosRepresentantesCtrl.text,
    );
    widget.onChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w4 = inputW4(context, constraints);
        final w2 = inputW2(context, constraints);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionTitle(text: '2) Empresa Contratada / Identificação'),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: w4,
                  child: CustomTextField(
                    controller: _razaoSocialCtrl,
                    labelText: 'Razão Social',
                    enabled: widget.isEditable,
                    validator: validateRequired,
                    onChanged: (_) => _emitChange(),
                  ),
                ),
                SizedBox(
                  width: w4,
                  child: CustomTextField(
                    controller: _cnpjCtrl,
                    labelText: 'CNPJ',
                    enabled: widget.isEditable,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(14),
                      SipGedMasks.cnpj,
                    ],
                    keyboardType: TextInputType.number,
                    validator: validateRequired,
                    onChanged: (_) => _emitChange(),
                  ),
                ),
                SizedBox(
                  width: w2,
                  child: CustomTextField(
                    controller: _sociosRepresentantesCtrl,
                    labelText:
                    'Sócios/Representantes legais (nome/CPF)',
                    maxLines: 1,
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
