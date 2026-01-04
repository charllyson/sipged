// lib/screens/process/hiring/9Juridico/section_2_documentos.dart
import 'package:flutter/material.dart';

import 'package:siged/_widgets/layout/responsive_utils.dart';
import 'package:siged/_widgets/input/custom_text_field.dart';
import 'package:siged/_widgets/texts/section_text_name.dart';
import 'package:siged/_utils/validates/form_validation_mixin.dart';

import 'package:siged/_blocs/process/hiring/9Juridico/parecer_juridico_data.dart';

class SectionDocumentos extends StatefulWidget {
  final ParecerJuridicoData data;
  final bool isEditable;
  final void Function(ParecerJuridicoData updated) onChanged;

  const SectionDocumentos({
    super.key,
    required this.data,
    required this.isEditable,
    required this.onChanged,
  });

  @override
  State<SectionDocumentos> createState() => _SectionDocumentosState();
}

class _SectionDocumentosState extends State<SectionDocumentos>
    with FormValidationMixin {
  late final TextEditingController _refProcessoCtrl;
  late final TextEditingController _linksAnexosCtrl;

  @override
  void initState() {
    super.initState();
    _refProcessoCtrl =
        TextEditingController(text: widget.data.refProcesso ?? '');
    _linksAnexosCtrl =
        TextEditingController(text: widget.data.linksAnexos ?? '');
  }

  @override
  void didUpdateWidget(covariant SectionDocumentos oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data != widget.data) {
      _refProcessoCtrl.text = widget.data.refProcesso ?? '';
      _linksAnexosCtrl.text = widget.data.linksAnexos ?? '';
    }
  }

  @override
  void dispose() {
    _refProcessoCtrl.dispose();
    _linksAnexosCtrl.dispose();
    super.dispose();
  }

  void _emitChange() {
    final updated = widget.data.copyWith(
      refProcesso: _refProcessoCtrl.text,
      linksAnexos: _linksAnexosCtrl.text,
    );
    widget.onChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(text: '2) Documentos / Peças analisadas'),
        LayoutBuilder(
          builder: (context, constraints) {
            final w3 = inputW3(context, constraints);

            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: w3,
                  child: CustomTextField(
                    controller: _refProcessoCtrl,
                    labelText: 'Referência do processo (SEI/Interno)',
                    enabled: widget.isEditable,
                    onChanged: (_) => _emitChange(),
                  ),
                ),
                SizedBox(
                  width: w3,
                  child: CustomTextField(
                    controller: _linksAnexosCtrl,
                    labelText: 'Links/Anexos (SEI/Drive/PNCP)',
                    enabled: widget.isEditable,
                    textAlignVertical: TextAlignVertical.top,
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
