// lib/screens/modules/contracts/hiring/3Tr/section_8_riscos_penalidades_condicoes.dart
import 'package:flutter/material.dart';

import 'package:siged/_widgets/texts/section_text_name.dart';
import 'package:siged/_widgets/input/custom_text_field.dart';
import 'package:siged/_widgets/layout/responsive_utils.dart';
import 'package:siged/_blocs/modules/contracts/hiring/3Tr/tr_data.dart';

class SectionRiscosPenalidadesCondicoes extends StatefulWidget {
  final bool isEditable;
  final TrData data;
  final void Function(TrData updated) onChanged;

  const SectionRiscosPenalidadesCondicoes({
    super.key,
    required this.isEditable,
    required this.data,
    required this.onChanged,
  });

  @override
  State<SectionRiscosPenalidadesCondicoes> createState() =>
      _SectionRiscosPenalidadesCondicoesState();
}

class _SectionRiscosPenalidadesCondicoesState
    extends State<SectionRiscosPenalidadesCondicoes> {
  late final TextEditingController _matrizRiscosCtrl;
  late final TextEditingController _penalidadesCtrl;
  late final TextEditingController _demaisCondicoesCtrl;

  @override
  void initState() {
    super.initState();
    final d = widget.data;
    _matrizRiscosCtrl =
        TextEditingController(text: d.matrizRiscos ?? '');
    _penalidadesCtrl =
        TextEditingController(text: d.penalidades ?? '');
    _demaisCondicoesCtrl =
        TextEditingController(text: d.demaisCondicoes ?? '');
  }

  @override
  void didUpdateWidget(
      covariant SectionRiscosPenalidadesCondicoes oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data != widget.data) {
      final d = widget.data;
      void _sync(TextEditingController c, String? v) {
        final nv = v ?? '';
        if (c.text != nv) c.text = nv;
      }

      _sync(_matrizRiscosCtrl, d.matrizRiscos);
      _sync(_penalidadesCtrl, d.penalidades);
      _sync(_demaisCondicoesCtrl, d.demaisCondicoes);
    }
  }

  @override
  void dispose() {
    _matrizRiscosCtrl.dispose();
    _penalidadesCtrl.dispose();
    _demaisCondicoesCtrl.dispose();
    super.dispose();
  }

  void _emitChange() {
    final updated = widget.data.copyWith(
      matrizRiscos: _matrizRiscosCtrl.text,
      penalidades: _penalidadesCtrl.text,
      demaisCondicoes: _demaisCondicoesCtrl.text,
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
            const SectionTitle(text: '8) Riscos, Penalidades e Demais Condições'),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: w3,
                  child: CustomTextField(
                    controller: _matrizRiscosCtrl,
                    labelText: 'Matriz de riscos (preliminar)',
                    maxLines: 4,
                    enabled: widget.isEditable,
                    onChanged: (_) => _emitChange(),
                  ),
                ),
                SizedBox(
                  width: w3,
                  child: CustomTextField(
                    controller: _penalidadesCtrl,
                    labelText: 'Penalidades e sanções',
                    maxLines: 4,
                    enabled: widget.isEditable,
                    onChanged: (_) => _emitChange(),
                  ),
                ),
                SizedBox(
                  width: w3,
                  child: CustomTextField(
                    controller: _demaisCondicoesCtrl,
                    labelText:
                    'Demais condições (visita técnica, seguros, interfaces etc.)',
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
