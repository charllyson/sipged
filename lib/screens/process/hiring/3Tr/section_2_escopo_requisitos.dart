// lib/screens/process/hiring/3Tr/section_2_escopo_requisitos.dart
import 'package:flutter/material.dart';

import 'package:siged/_widgets/texts/section_text_name.dart';
import 'package:siged/_widgets/input/custom_text_field.dart';
import 'package:siged/_widgets/layout/responsive_utils.dart';
import 'package:siged/_utils/validates/form_validation_mixin.dart';
import 'package:siged/_blocs/process/hiring/3Tr/tr_data.dart';

class SectionEscopoRequisitos extends StatefulWidget {
  final bool isEditable;
  final TrData data;
  final void Function(TrData updated) onChanged;

  const SectionEscopoRequisitos({
    super.key,
    required this.isEditable,
    required this.data,
    required this.onChanged,
  });

  @override
  State<SectionEscopoRequisitos> createState() =>
      _SectionEscopoRequisitosState();
}

class _SectionEscopoRequisitosState extends State<SectionEscopoRequisitos>
    with FormValidationMixin {
  late final TextEditingController _escopoCtrl;
  late final TextEditingController _requisitosCtrl;
  late final TextEditingController _especificacoesCtrl;

  @override
  void initState() {
    super.initState();
    final d = widget.data;
    _escopoCtrl =
        TextEditingController(text: d.escopoDetalhado ?? '');
    _requisitosCtrl =
        TextEditingController(text: d.requisitosTecnicos ?? '');
    _especificacoesCtrl =
        TextEditingController(text: d.especificacoesNormas ?? '');
  }

  @override
  void didUpdateWidget(covariant SectionEscopoRequisitos oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data != widget.data) {
      final d = widget.data;
      void _sync(TextEditingController c, String? v) {
        final nv = v ?? '';
        if (c.text != nv) c.text = nv;
      }

      _sync(_escopoCtrl, d.escopoDetalhado);
      _sync(_requisitosCtrl, d.requisitosTecnicos);
      _sync(_especificacoesCtrl, d.especificacoesNormas);
    }
  }

  @override
  void dispose() {
    _escopoCtrl.dispose();
    _requisitosCtrl.dispose();
    _especificacoesCtrl.dispose();
    super.dispose();
  }

  void _emitChange() {
    final updated = widget.data.copyWith(
      escopoDetalhado: _escopoCtrl.text,
      requisitosTecnicos: _requisitosCtrl.text,
      especificacoesNormas: _especificacoesCtrl.text,
    );
    widget.onChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w3 = inputW3(context, constraints);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionTitle(text: '2) Escopo / Requisitos'),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: w3,
                  child: CustomTextField(
                    controller: _escopoCtrl,
                    labelText: 'Escopo detalhado da contratação',
                    maxLines: 4,
                    enabled: widget.isEditable,
                    validator: validateRequired,
                    onChanged: (_) => _emitChange(),
                  ),
                ),
                SizedBox(
                  width: w3,
                  child: CustomTextField(
                    controller: _requisitosCtrl,
                    labelText: 'Requisitos técnicos mínimos',
                    maxLines: 4,
                    enabled: widget.isEditable,
                    onChanged: (_) => _emitChange(),
                  ),
                ),
                SizedBox(
                  width: w3,
                  child: CustomTextField(
                    controller: _especificacoesCtrl,
                    labelText:
                    'Especificações / normas aplicáveis (ABNT, DNIT etc.)',
                    maxLines: 4,
                    enabled: widget.isEditable,
                    onChanged: (_) => _emitChange(),
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
