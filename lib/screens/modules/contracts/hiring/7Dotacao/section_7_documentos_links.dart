import 'package:flutter/material.dart';

import 'package:sipged/_widgets/input/text_field_change.dart';
import 'package:sipged/_widgets/texts/section_text_name.dart';

import 'package:sipged/_blocs/modules/contracts/hiring/7Dotacao/dotacao_data.dart';

class SectionDocumentosLinks extends StatefulWidget {
  final DotacaoData data;
  final bool isEditable;
  final void Function(DotacaoData updated) onChanged;

  const SectionDocumentosLinks({
    super.key,
    required this.data,
    required this.isEditable,
    required this.onChanged,
  });

  @override
  State<SectionDocumentosLinks> createState() =>
      _SectionDocumentosLinksState();
}

class _SectionDocumentosLinksState extends State<SectionDocumentosLinks> {
  late final TextEditingController _linksCtrl;

  @override
  void initState() {
    super.initState();
    _linksCtrl = TextEditingController(text: widget.data.links ?? '');
  }

  @override
  void didUpdateWidget(
      covariant SectionDocumentosLinks oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data != widget.data) {
      final v = widget.data.links ?? '';
      if (_linksCtrl.text != v) _linksCtrl.text = v;
    }
  }

  @override
  void dispose() {
    _linksCtrl.dispose();
    super.dispose();
  }

  void _emitChange() {
    final updated = widget.data.copyWith(
      links: _linksCtrl.text,
    );
    widget.onChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(text: '7) Documentos / Links'),
        CustomTextField(
          controller: _linksCtrl,
          labelText:
          'Links (NE, Reserva, prints do SIAF/SIGEF, planilhas)',
          enabled: widget.isEditable,
          maxLines: 2,
          onChanged: (_) => _emitChange(),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
