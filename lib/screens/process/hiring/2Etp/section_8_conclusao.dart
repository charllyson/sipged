import 'package:flutter/material.dart';
import 'package:siged/_widgets/input/custom_text_field.dart';
import 'package:siged/_blocs/process/hiring/2Etp/etp_controller.dart';

class SectionConclusao extends StatelessWidget {
  final EtpController controller;
  const SectionConclusao({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final c = controller;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _Title('8) Conclusão'),
        CustomTextField(
          controller: c.etpConclusaoCtrl,
          enabled: c.isEditable,
          labelText: 'Conclusão / Encaminhamento',
          maxLines: 3,
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _Title extends StatelessWidget {
  final String text;
  const _Title(this.text);
  @override
  Widget build(BuildContext context) =>
      Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(text, style: Theme.of(context).textTheme.titleMedium));
}
