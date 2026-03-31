// lib/screens/modules/contracts/hiring/3Tr/section_9_documentos_referencias.dart
import 'package:flutter/material.dart';

import 'package:sipged/_widgets/texts/section_text_name.dart';
import 'package:sipged/_widgets/input/text_field_change.dart';
import 'package:sipged/_widgets/layout/responsive_utils.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/3Tr/tr_data.dart';

class SectionDocumentosReferencias extends StatefulWidget {
  final bool isEditable;
  final TrData data;
  final void Function(TrData updated) onChanged;

  const SectionDocumentosReferencias({
    super.key,
    required this.isEditable,
    required this.data,
    required this.onChanged,
  });

  @override
  State<SectionDocumentosReferencias> createState() =>
      _SectionDocumentosReferenciasState();
}

class _SectionDocumentosReferenciasState
    extends State<SectionDocumentosReferencias> {
  late final TextEditingController _linksCtrl;

  @override
  void initState() {
    super.initState();
    final d = widget.data;
    _linksCtrl =
        TextEditingController(text: d.linksDocumentos ?? '');
  }

  @override
  void didUpdateWidget(
      covariant SectionDocumentosReferencias oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data != widget.data) {
      final d = widget.data;
      final nv = d.linksDocumentos ?? '';
      if (_linksCtrl.text != nv) {
        _linksCtrl.text = nv;
      }
    }
  }

  @override
  void dispose() {
    _linksCtrl.dispose();
    super.dispose();
  }

  void _emitChange() {
    final updated = widget.data.copyWith(
      linksDocumentos: _linksCtrl.text,
    );
    widget.onChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w1 = inputW1(context, constraints);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionTitle(text: '9) Documentos / Referências'),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: w1,
                  child: CustomTextField(
                    controller: _linksCtrl,
                    labelText:
                    'Links / Referências (SEI, projetos, estudos, mapas)',
                    maxLines: 2,
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
