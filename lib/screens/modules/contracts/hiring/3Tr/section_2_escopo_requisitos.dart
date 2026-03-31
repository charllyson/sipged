// lib/screens/modules/contracts/hiring/3Tr/section_2_escopo_requisitos.dart
import 'package:flutter/material.dart';

import 'package:sipged/_widgets/texts/section_text_name.dart';
import 'package:sipged/_widgets/input/text_field_change.dart';
import 'package:sipged/_widgets/layout/responsive_utils.dart';
import 'package:sipged/_utils/validates/sipged_validation.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/3Tr/tr_data.dart';

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
    with SipGedValidation {
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
      void sync(TextEditingController c, String? v) {
        final nv = v ?? '';
        if (c.text != nv) c.text = nv;
      }

      sync(_escopoCtrl, d.escopoDetalhado);
      sync(_requisitosCtrl, d.requisitosTecnicos);
      sync(_especificacoesCtrl, d.especificacoesNormas);
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
