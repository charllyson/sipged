import 'package:flutter/material.dart';

import 'package:sipged/_blocs/modules/contracts/hiring/1Dfd/dfd_data.dart';
import 'package:sipged/_widgets/input/custom_text_field.dart';
import 'package:sipged/_widgets/layout/responsive_utils.dart';
import 'package:sipged/_widgets/texts/section_text_name.dart';

class SectionObservacoes extends StatefulWidget {
  final bool isEditable;
  final DfdData data;
  final void Function(DfdData updated) onChanged;

  const SectionObservacoes({
    super.key,
    required this.isEditable,
    required this.data,
    required this.onChanged,
  });

  @override
  State<SectionObservacoes> createState() => _SectionObservacoesState();
}

class _SectionObservacoesState extends State<SectionObservacoes> {
  late final TextEditingController _observacoesCtrl;

  @override
  void initState() {
    super.initState();
    _observacoesCtrl =
        TextEditingController(text: widget.data.observacoes ?? '');
  }

  @override
  void didUpdateWidget(covariant SectionObservacoes oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data != widget.data) {
      final obs = widget.data.observacoes ?? '';
      if (_observacoesCtrl.text != obs) {
        _observacoesCtrl.text = obs;
      }
    }
  }

  @override
  void dispose() {
    _observacoesCtrl.dispose();
    super.dispose();
  }

  void _emitChange() {
    final updated = widget.data.copyWith(
      observacoes: _observacoesCtrl.text,
    );
    widget.onChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(text: '8) Observações'),
        LayoutBuilder(
          builder: (context, inner) {
            return SizedBox(
              width: inputW1(context, inner),
              child: CustomTextField(
                controller: _observacoesCtrl,
                enabled: widget.isEditable,
                labelText: 'Observações complementares',
                maxLines: 4,
                onChanged: (_) => _emitChange(),
              ),
            );
          },
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
