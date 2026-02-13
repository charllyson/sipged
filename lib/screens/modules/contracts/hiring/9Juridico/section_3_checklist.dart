// lib/screens/modules/contracts/hiring/9Juridico/section_3_checklist.dart
import 'package:flutter/material.dart';

import 'package:sipged/_widgets/layout/responsive_utils.dart';
import 'package:sipged/_widgets/input/custom_text_field.dart';
import 'package:sipged/_widgets/texts/section_text_name.dart';
import 'package:sipged/_utils/validates/sipged_validation.dart';

import 'package:sipged/_blocs/modules/contracts/hiring/9Juridico/parecer_juridico_data.dart';

class SectionChecklist extends StatefulWidget {
  final ParecerJuridicoData data;
  final bool isEditable;
  final void Function(ParecerJuridicoData updated) onChanged;

  const SectionChecklist({
    super.key,
    required this.data,
    required this.isEditable,
    required this.onChanged,
  });

  @override
  State<SectionChecklist> createState() => _SectionChecklistState();
}

class _SectionChecklistState extends State<SectionChecklist>
    with SipGedValidation {
  late final TextEditingController _analiseCtrl;

  @override
  void initState() {
    super.initState();
    _analiseCtrl =
        TextEditingController(text: widget.data.documentosExaminados ?? '');
  }

  @override
  void didUpdateWidget(covariant SectionChecklist oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data != widget.data) {
      _analiseCtrl.text = widget.data.documentosExaminados ?? '';
    }
  }

  @override
  void dispose() {
    _analiseCtrl.dispose();
    super.dispose();
  }

  void _emitChange() {
    final updated = widget.data.copyWith(
      documentosExaminados: _analiseCtrl.text,
    );
    widget.onChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(text: '3) Análise de Conformidade (Checklist)'),
        const SizedBox(height: 4),
        LayoutBuilder(
          builder: (context, constraints) {
            final w1 = inputW1(context, constraints);

            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: w1,
                  child: CustomTextField(
                    controller: _analiseCtrl,
                    labelText:
                    'Síntese da análise de conformidade (pontos atendidos/não atendidos)',
                    maxLines: 6,
                    enabled: widget.isEditable,
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
