// lib/screens/modules/contracts/hiring/3Tr/section_4_medicao_aceite_indicadores.dart
import 'package:flutter/material.dart';

import 'package:sipged/_widgets/texts/section_text_name.dart';
import 'package:sipged/_widgets/input/text_field_change.dart';
import 'package:sipged/_widgets/layout/responsive_utils.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/3Tr/tr_data.dart';

class SectionMedicaoAceiteIndicadores extends StatefulWidget {
  final bool isEditable;
  final TrData data;
  final void Function(TrData updated) onChanged;

  const SectionMedicaoAceiteIndicadores({
    super.key,
    required this.isEditable,
    required this.data,
    required this.onChanged,
  });

  @override
  State<SectionMedicaoAceiteIndicadores> createState() =>
      _SectionMedicaoAceiteIndicadoresState();
}

class _SectionMedicaoAceiteIndicadoresState
    extends State<SectionMedicaoAceiteIndicadores> {
  late final TextEditingController _criteriosMedicaoCtrl;
  late final TextEditingController _criteriosAceiteCtrl;
  late final TextEditingController _indicadoresCtrl;

  @override
  void initState() {
    super.initState();
    final d = widget.data;
    _criteriosMedicaoCtrl =
        TextEditingController(text: d.criteriosMedicao ?? '');
    _criteriosAceiteCtrl =
        TextEditingController(text: d.criteriosAceite ?? '');
    _indicadoresCtrl =
        TextEditingController(text: d.indicadoresDesempenho ?? '');
  }

  @override
  void didUpdateWidget(
      covariant SectionMedicaoAceiteIndicadores oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data != widget.data) {
      final d = widget.data;
      void sync(TextEditingController c, String? v) {
        final nv = v ?? '';
        if (c.text != nv) c.text = nv;
      }

      sync(_criteriosMedicaoCtrl, d.criteriosMedicao);
      sync(_criteriosAceiteCtrl, d.criteriosAceite);
      sync(_indicadoresCtrl, d.indicadoresDesempenho);
    }
  }

  @override
  void dispose() {
    _criteriosMedicaoCtrl.dispose();
    _criteriosAceiteCtrl.dispose();
    _indicadoresCtrl.dispose();
    super.dispose();
  }

  void _emitChange() {
    final updated = widget.data.copyWith(
      criteriosMedicao: _criteriosMedicaoCtrl.text,
      criteriosAceite: _criteriosAceiteCtrl.text,
      indicadoresDesempenho: _indicadoresCtrl.text,
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
            const SectionTitle(text: '4) Medição, Aceite e Indicadores'),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: w3,
                  child: CustomTextField(
                    controller: _criteriosMedicaoCtrl,
                    labelText: 'Critérios de medição',
                    maxLines: 3,
                    enabled: widget.isEditable,
                    onChanged: (_) => _emitChange(),
                  ),
                ),
                SizedBox(
                  width: w3,
                  child: CustomTextField(
                    controller: _criteriosAceiteCtrl,
                    labelText: 'Critérios de aceite',
                    maxLines: 3,
                    enabled: widget.isEditable,
                    onChanged: (_) => _emitChange(),
                  ),
                ),
                SizedBox(
                  width: w3,
                  child: CustomTextField(
                    controller: _indicadoresCtrl,
                    labelText: 'Indicadores de desempenho (SLA/KPI)',
                    maxLines: 3,
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
