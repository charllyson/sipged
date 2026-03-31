// lib/screens/modules/contracts/hiring/8Minuta/section_2_partes_objeto.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sipged/_utils/mask/sipged_masks.dart';

import 'package:sipged/_widgets/layout/responsive_utils.dart';
import 'package:sipged/_widgets/input/text_field_change.dart';
import 'package:sipged/_widgets/texts/section_text_name.dart';
import 'package:sipged/_utils/validates/sipged_validation.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/8Minuta/minuta_contrato_data.dart';

class SectionPartesObjeto extends StatefulWidget {
  final MinutaContratoData data;
  final bool isEditable;
  final void Function(MinutaContratoData updated) onChanged;

  const SectionPartesObjeto({
    super.key,
    required this.data,
    required this.isEditable,
    required this.onChanged,
  });

  @override
  State<SectionPartesObjeto> createState() => _SectionPartesObjetoState();
}

class _SectionPartesObjetoState extends State<SectionPartesObjeto>
    with SipGedValidation {
  late final TextEditingController _contratanteCtrl;
  late final TextEditingController _contratadaRazaoCtrl;
  late final TextEditingController _contratadaCnpjCtrl;
  late final TextEditingController _objetoResumoCtrl;

  @override
  void initState() {
    super.initState();
    final d = widget.data;

    _contratanteCtrl = TextEditingController(text: d.contratante ?? '');
    _contratadaRazaoCtrl = TextEditingController(text: d.contratadaRazao ?? '');
    _contratadaCnpjCtrl = TextEditingController(text: d.contratadaCnpj ?? '');
    _objetoResumoCtrl = TextEditingController(text: d.objetoResumo ?? '');
  }

  @override
  void didUpdateWidget(covariant SectionPartesObjeto oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data != widget.data) {
      final d = widget.data;

      void sync(TextEditingController c, String? v) {
        final text = v ?? '';
        if (c.text != text) c.text = text;
      }

      sync(_contratanteCtrl, d.contratante);
      sync(_contratadaRazaoCtrl, d.contratadaRazao);
      sync(_contratadaCnpjCtrl, d.contratadaCnpj);
      sync(_objetoResumoCtrl, d.objetoResumo);
    }
  }

  @override
  void dispose() {
    _contratanteCtrl.dispose();
    _contratadaRazaoCtrl.dispose();
    _contratadaCnpjCtrl.dispose();
    _objetoResumoCtrl.dispose();
    super.dispose();
  }

  void _emitChange() {
    final updated = widget.data.copyWith(
      contratante: _contratanteCtrl.text,
      contratadaRazao: _contratadaRazaoCtrl.text,
      contratadaCnpj: _contratadaCnpjCtrl.text,
      objetoResumo: _objetoResumoCtrl.text,
    );
    widget.onChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(text: '2) Partes Contratantes e Objeto'),
        LayoutBuilder(
          builder: (context, constraints) {
            final w3 = inputW3(context, constraints);
            final w1 = inputW1(context, constraints);

            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: w3,
                  child: CustomTextField(
                    controller: _contratanteCtrl,
                    labelText: 'Contratante (Órgão/Unidade)',
                    enabled: widget.isEditable,
                    validator: validateRequired,
                    onChanged: (_) => _emitChange(),
                  ),
                ),
                SizedBox(
                  width: w3,
                  child: CustomTextField(
                    controller: _contratadaRazaoCtrl,
                    labelText: 'Contratada (Razão Social)',
                    enabled: widget.isEditable,
                    validator: validateRequired,
                    onChanged: (_) => _emitChange(),
                  ),
                ),
                SizedBox(
                  width: w3,
                  child: CustomTextField(
                    controller: _contratadaCnpjCtrl,
                    labelText: 'CNPJ da Contratada',
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
                  width: w1,
                  child: CustomTextField(
                    controller: _objetoResumoCtrl,
                    labelText: 'Objeto (resumo para o contrato)',
                    maxLines: 3,
                    enabled: widget.isEditable,
                    validator: validateRequired,
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
