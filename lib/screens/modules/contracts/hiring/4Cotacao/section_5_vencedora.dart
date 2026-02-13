// lib/screens/modules/contracts/hiring/4Cotacao/section_5_vencedora.dart
import 'package:flutter/material.dart';

import 'package:sipged/_widgets/texts/section_text_name.dart';
import 'package:sipged/_widgets/input/custom_text_field.dart';
import 'package:sipged/_widgets/layout/responsive_utils.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/4Cotacao/cotacao_data.dart';

class SectionVencedora extends StatefulWidget {
  final CotacaoData data;
  final bool isEditable;
  final void Function(CotacaoData updated) onChanged;

  const SectionVencedora({
    super.key,
    required this.data,
    required this.isEditable,
    required this.onChanged,
  });

  @override
  State<SectionVencedora> createState() => _SectionVencedoraState();
}

class _SectionVencedoraState extends State<SectionVencedora> {
  late final TextEditingController _empresaLiderCtrl;
  late final TextEditingController _consorcioCtrl;

  @override
  void initState() {
    super.initState();
    final d = widget.data;

    _empresaLiderCtrl =
        TextEditingController(text: d.empresaLider ?? '');
    _consorcioCtrl =
        TextEditingController(text: d.consorcioEnvolvidas ?? '');
  }

  @override
  void didUpdateWidget(covariant SectionVencedora oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data != widget.data) {
      final d = widget.data;

      void sync(TextEditingController c, String? v) {
        final text = v ?? '';
        if (c.text != text) c.text = text;
      }

      sync(_empresaLiderCtrl, d.empresaLider);
      sync(_consorcioCtrl, d.consorcioEnvolvidas);
    }
  }

  @override
  void dispose() {
    _empresaLiderCtrl.dispose();
    _consorcioCtrl.dispose();
    super.dispose();
  }

  void _emitChange() {
    final updated = widget.data.copyWith(
      empresaLider: _empresaLiderCtrl.text,
      consorcioEnvolvidas: _consorcioCtrl.text,
    );
    widget.onChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w2 = inputW2(context, constraints);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionTitle(text: 'Empresa vencedora'),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: w2,
                  child: CustomTextField(
                    enabled: widget.isEditable,
                    labelText: 'Empresa líder',
                    controller: _empresaLiderCtrl,
                    onChanged: (_) => _emitChange(),
                  ),
                ),
                SizedBox(
                  width: w2,
                  child: CustomTextField(
                    enabled: widget.isEditable,
                    labelText: 'Consórcio envolvidas',
                    controller: _consorcioCtrl,
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
