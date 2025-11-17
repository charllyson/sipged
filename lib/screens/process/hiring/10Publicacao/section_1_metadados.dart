// lib/screens/process/hiring/10Publicacao/section_1_metadados.dart
import 'package:flutter/material.dart';
import 'package:siged/_blocs/process/hiring/0Stages/hiring_data.dart';
import 'package:siged/_utils/validates/form_validation_mixin.dart';
import 'package:siged/_widgets/input/custom_text_field.dart';
import 'package:siged/_widgets/input/drop_down_botton_change.dart'
    show DropDownButtonChange;
import 'package:siged/_widgets/layout/responsive_utils.dart';
import 'package:siged/_widgets/texts/section_text_name.dart';

import 'package:siged/_blocs/process/hiring/10Publicacao/publicacao_extrato_data.dart';

class SectionMetadadosExtrato extends StatefulWidget {
  final bool isEditable;
  final PublicacaoExtratoData data;

  /// Chamado sempre que algum campo é alterado.
  final void Function(PublicacaoExtratoData updated) onChanged;

  const SectionMetadadosExtrato({
    super.key,
    required this.isEditable,
    required this.data,
    required this.onChanged,
  });

  @override
  State<SectionMetadadosExtrato> createState() =>
      _SectionMetadadosExtratoState();
}

class _SectionMetadadosExtratoState extends State<SectionMetadadosExtrato>
    with FormValidationMixin {
  late final TextEditingController _tipoExtratoCtrl;
  late final TextEditingController _numeroContratoCtrl;
  late final TextEditingController _processoCtrl;
  late final TextEditingController _objetoResumoCtrl;

  @override
  void initState() {
    super.initState();
    _tipoExtratoCtrl =
        TextEditingController(text: widget.data.tipoExtrato ?? '');
    _numeroContratoCtrl =
        TextEditingController(text: widget.data.numeroContrato ?? '');
    _processoCtrl = TextEditingController(text: widget.data.processo ?? '');
    _objetoResumoCtrl =
        TextEditingController(text: widget.data.objetoResumo ?? '');
  }

  @override
  void didUpdateWidget(covariant SectionMetadadosExtrato oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data != widget.data) {
      _tipoExtratoCtrl.text = widget.data.tipoExtrato ?? '';
      _numeroContratoCtrl.text = widget.data.numeroContrato ?? '';
      _processoCtrl.text = widget.data.processo ?? '';
      _objetoResumoCtrl.text = widget.data.objetoResumo ?? '';
    }
  }

  void _emitChange() {
    final updated = widget.data.copyWith(
      tipoExtrato: _tipoExtratoCtrl.text,
      numeroContrato: _numeroContratoCtrl.text,
      processo: _processoCtrl.text,
      objetoResumo: _objetoResumoCtrl.text,
    );
    widget.onChanged(updated);
  }

  @override
  void dispose() {
    _tipoExtratoCtrl.dispose();
    _numeroContratoCtrl.dispose();
    _processoCtrl.dispose();
    _objetoResumoCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle('1) Metadados do Extrato'),
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
                        child: DropDownButtonChange(
                          enabled: widget.isEditable,
                          labelText: 'Tipo de extrato',
                          controller: _tipoExtratoCtrl,
                          items: HiringData.tipoExtrato,
                          onChanged: (v) {
                            _tipoExtratoCtrl.text = v ?? '';
                            _emitChange();
                            setState(() {});
                          },
                          validator: validateRequired,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: w2,
                        child: CustomTextField(
                          controller: _numeroContratoCtrl,
                          labelText: 'Nº do contrato/ARP',
                          enabled: widget.isEditable,
                          validator: validateRequired,
                          onChanged: (_) => _emitChange(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: w2,
                        child: CustomTextField(
                          controller: _processoCtrl,
                          labelText: 'Nº do processo (SEI/Interno)',
                          enabled: widget.isEditable,
                          validator: validateRequired,
                          onChanged: (_) => _emitChange(),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: w2,
                  child: CustomTextField(
                    controller: _objetoResumoCtrl,
                    labelText: 'Objeto (resumo para o extrato)',
                    maxLines: 7,
                    enabled: widget.isEditable,
                    validator: validateRequired,
                    textAlignVertical: TextAlignVertical.top,
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
