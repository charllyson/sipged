// lib/screens/modules/contracts/hiring/11Arquivamento/section_4_pecas_anexas.dart
import 'package:flutter/material.dart';

import 'package:siged/_widgets/input/custom_text_field.dart';
import 'package:siged/_widgets/layout/responsive_utils.dart';
import 'package:siged/_widgets/texts/section_text_name.dart';

import 'package:siged/_blocs/modules/contracts/hiring/11Arquivamento/termo_arquivamento_data.dart';

class SectionPecasAnexasTA extends StatefulWidget {
  final TermoArquivamentoData data;
  final bool isEditable;
  final void Function(TermoArquivamentoData updated) onChanged;

  const SectionPecasAnexasTA({
    super.key,
    required this.data,
    required this.isEditable,
    required this.onChanged,
  });

  @override
  State<SectionPecasAnexasTA> createState() => _SectionPecasAnexasTAState();
}

class _SectionPecasAnexasTAState extends State<SectionPecasAnexasTA> {
  late final TextEditingController _pecasCtrl;
  late final TextEditingController _linksCtrl;

  @override
  void initState() {
    super.initState();
    final d = widget.data;

    _pecasCtrl = TextEditingController(text: d.taPecasAnexas ?? '');
    _linksCtrl = TextEditingController(text: d.taLinks ?? '');
  }

  @override
  void didUpdateWidget(covariant SectionPecasAnexasTA oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data != widget.data) {
      final d = widget.data;

      void _sync(TextEditingController c, String? v) {
        final text = v ?? '';
        if (c.text != text) c.text = text;
      }

      _sync(_pecasCtrl, d.taPecasAnexas);
      _sync(_linksCtrl, d.taLinks);
    }
  }

  @override
  void dispose() {
    _pecasCtrl.dispose();
    _linksCtrl.dispose();
    super.dispose();
  }

  void _emitChange() {
    final updated = widget.data.copyWith(
      taPecasAnexas: _pecasCtrl.text,
      taLinks: _linksCtrl.text,
    );
    widget.onChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(text: '4) Peças Anexas'),
        LayoutBuilder(
          builder: (context, constraints) {
            final w2 = inputW2(context, constraints);

            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: w2,
                  child: CustomTextField(
                    controller: _pecasCtrl,
                    labelText:
                    'Peças anexas (TR, ETP, pareceres, publicações etc.)',
                    maxLines: 1,
                    enabled: widget.isEditable,
                    onChanged: (_) => _emitChange(),
                  ),
                ),
                SizedBox(
                  width: w2,
                  child: CustomTextField(
                    controller: _linksCtrl,
                    labelText: 'Links (SEI/Drive/PNCP)',
                    maxLines: 1,
                    enabled: widget.isEditable,
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
