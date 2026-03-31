// lib/screens/modules/contracts/hiring/8Minuta/section_3_valor.dart
import 'package:flutter/material.dart';

import 'package:sipged/_widgets/layout/responsive_utils.dart';
import 'package:sipged/_widgets/input/text_field_change.dart';
import 'package:sipged/_widgets/texts/section_text_name.dart';

import 'package:sipged/_blocs/modules/contracts/hiring/8Minuta/minuta_contrato_data.dart';

class SectionValor extends StatefulWidget {
  final MinutaContratoData data;
  final bool isEditable;
  final void Function(MinutaContratoData updated) onChanged;

  const SectionValor({
    super.key,
    required this.data,
    required this.isEditable,
    required this.onChanged,
  });

  @override
  State<SectionValor> createState() => _SectionValorState();
}

class _SectionValorState extends State<SectionValor> {
  late final TextEditingController _valorGlobalCtrl;

  @override
  void initState() {
    super.initState();
    final d = widget.data;
    _valorGlobalCtrl = TextEditingController(text: d.valorGlobal ?? '');
  }

  @override
  void didUpdateWidget(covariant SectionValor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data != widget.data) {
      final d = widget.data;
      final newValor = d.valorGlobal ?? '';
      if (_valorGlobalCtrl.text != newValor) {
        _valorGlobalCtrl.text = newValor;
      }
    }
  }

  @override
  void dispose() {
    _valorGlobalCtrl.dispose();
    super.dispose();
  }

  void _emitChange() {
    final updated = widget.data.copyWith(
      valorGlobal: _valorGlobalCtrl.text,
    );
    widget.onChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(text: '3) Valor Contratual'),
        LayoutBuilder(
          builder: (context, constraints) {
            final w4 = inputW4(context, constraints);

            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: w4,
                  child: CustomTextField(
                    controller: _valorGlobalCtrl,
                    labelText: 'Valor global (R\$)',
                    enabled: widget.isEditable,
                    keyboardType: TextInputType.number,
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
