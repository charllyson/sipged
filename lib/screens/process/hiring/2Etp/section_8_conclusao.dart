// lib/screens/process/hiring/2Etp/section_8_conclusao.dart
import 'package:flutter/material.dart';
import 'package:siged/_widgets/input/custom_text_field.dart';
import 'package:siged/_widgets/texts/section_text_name.dart';
import 'package:siged/_widgets/layout/responsive_utils.dart';
import 'package:siged/_blocs/process/hiring/2Etp/etp_data.dart';

class SectionConclusao extends StatefulWidget {
  final EtpData data;
  final bool isEditable;
  final void Function(EtpData updated) onChanged;

  const SectionConclusao({
    super.key,
    required this.data,
    required this.isEditable,
    required this.onChanged,
  });

  @override
  State<SectionConclusao> createState() => _SectionConclusaoState();
}

class _SectionConclusaoState extends State<SectionConclusao> {
  late final TextEditingController _conclusaoCtrl;

  @override
  void initState() {
    super.initState();
    _conclusaoCtrl =
        TextEditingController(text: widget.data.conclusao ?? '');
  }

  @override
  void didUpdateWidget(covariant SectionConclusao oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data != widget.data) {
      final v = widget.data.conclusao ?? '';
      if (_conclusaoCtrl.text != v) _conclusaoCtrl.text = v;
    }
  }

  @override
  void dispose() {
    _conclusaoCtrl.dispose();
    super.dispose();
  }

  void _emitChange() {
    widget.onChanged(
      widget.data.copyWith(conclusao: _conclusaoCtrl.text),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w1 = inputW1(context, constraints);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionTitle(text: '8) Conclusão'),
            SizedBox(
              width: w1,
              child: CustomTextField(
                controller: _conclusaoCtrl,
                enabled: widget.isEditable,
                labelText: 'Conclusão / Encaminhamento',
                maxLines: 3,
                onChanged: (_) => _emitChange(),
              ),
            ),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }
}
