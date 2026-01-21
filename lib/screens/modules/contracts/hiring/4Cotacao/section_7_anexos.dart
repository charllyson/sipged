// lib/screens/modules/contracts/hiring/4Cotacao/section_7_anexos.dart
import 'package:flutter/material.dart';

import 'package:siged/_widgets/texts/section_text_name.dart';
import 'package:siged/_widgets/input/custom_text_field.dart';
import 'package:siged/_widgets/layout/responsive_utils.dart';
import 'package:siged/_blocs/modules/contracts/hiring/4Cotacao/cotacao_data.dart';

class SectionAnexos extends StatefulWidget {
  final CotacaoData data;
  final bool isEditable;
  final void Function(CotacaoData updated) onChanged;

  const SectionAnexos({
    super.key,
    required this.data,
    required this.isEditable,
    required this.onChanged,
  });

  @override
  State<SectionAnexos> createState() => _SectionAnexosState();
}

class _SectionAnexosState extends State<SectionAnexos> {
  late final TextEditingController _linksAnexosCtrl;

  @override
  void initState() {
    super.initState();
    _linksAnexosCtrl =
        TextEditingController(text: widget.data.linksAnexos ?? '');
  }

  @override
  void didUpdateWidget(covariant SectionAnexos oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data != widget.data) {
      final v = widget.data.linksAnexos ?? '';
      if (_linksAnexosCtrl.text != v) {
        _linksAnexosCtrl.text = v;
      }
    }
  }

  @override
  void dispose() {
    _linksAnexosCtrl.dispose();
    super.dispose();
  }

  void _emitChange() {
    final updated = widget.data.copyWith(
      linksAnexos: _linksAnexosCtrl.text,
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
            const SectionTitle(text: '6) Evidências/Anexos'),
            SizedBox(
              width: w1,
              child: CustomTextField(
                controller: _linksAnexosCtrl,
                labelText:
                'Links (SEI, propostas, planilhas, prints do Painel etc.)',
                maxLines: 2,
                enabled: widget.isEditable,
                onChanged: (_) => _emitChange(),
              ),
            ),
          ],
        );
      },
    );
  }
}
