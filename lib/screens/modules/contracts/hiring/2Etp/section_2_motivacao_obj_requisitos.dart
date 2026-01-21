// lib/screens/modules/contracts/hiring/2Etp/section_2_motivacao_obj_requisitos.dart
import 'package:flutter/material.dart';
import 'package:siged/_widgets/input/custom_text_field.dart';
import 'package:siged/_widgets/texts/section_text_name.dart';
import 'package:siged/_widgets/layout/responsive_utils.dart';
import 'package:siged/_utils/validates/form_validation_mixin.dart';
import 'package:siged/_blocs/modules/contracts/hiring/2Etp/etp_data.dart';

class SectionMotivacaoObjRequisitos extends StatefulWidget
    with FormValidationMixin {
  final EtpData data;
  final bool isEditable;
  final void Function(EtpData updated) onChanged;

  SectionMotivacaoObjRequisitos({
    super.key,
    required this.data,
    required this.isEditable,
    required this.onChanged,
  });

  @override
  State<SectionMotivacaoObjRequisitos> createState() =>
      _SectionMotivacaoObjRequisitosState();
}

class _SectionMotivacaoObjRequisitosState
    extends State<SectionMotivacaoObjRequisitos> {
  late final TextEditingController _motivacaoCtrl;
  late final TextEditingController _objetivosCtrl;
  late final TextEditingController _requisitosCtrl;

  @override
  void initState() {
    super.initState();
    final d = widget.data;
    _motivacaoCtrl = TextEditingController(text: d.motivacao ?? '');
    _objetivosCtrl = TextEditingController(text: d.objetivos ?? '');
    _requisitosCtrl = TextEditingController(text: d.requisitosMinimos ?? '');
  }

  @override
  void didUpdateWidget(
      covariant SectionMotivacaoObjRequisitos oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data != widget.data) {
      void _sync(TextEditingController c, String? value) {
        final v = value ?? '';
        if (c.text != v) c.text = v;
      }

      final d = widget.data;
      _sync(_motivacaoCtrl, d.motivacao);
      _sync(_objetivosCtrl, d.objetivos);
      _sync(_requisitosCtrl, d.requisitosMinimos);
    }
  }

  @override
  void dispose() {
    _motivacaoCtrl.dispose();
    _objetivosCtrl.dispose();
    _requisitosCtrl.dispose();
    super.dispose();
  }

  void _emitChange() {
    widget.onChanged(
      widget.data.copyWith(
        motivacao: _motivacaoCtrl.text,
        objetivos: _objetivosCtrl.text,
        requisitosMinimos: _requisitosCtrl.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w3 = inputW3(context, constraints);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionTitle(text: '2) Motivação, objetivos e requisitos'),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: w3,
                  child: CustomTextField(
                    controller: _motivacaoCtrl,
                    enabled: widget.isEditable,
                    labelText: 'Motivação / Problema',
                    validator: widget.validateRequired,
                    maxLines: 5,
                    onChanged: (_) => _emitChange(),
                  ),
                ),
                SizedBox(
                  width: w3,
                  child: CustomTextField(
                    controller: _objetivosCtrl,
                    enabled: widget.isEditable,
                    labelText: 'Objetivos',
                    validator: widget.validateRequired,
                    maxLines: 5,
                    onChanged: (_) => _emitChange(),
                  ),
                ),
                SizedBox(
                  width: w3,
                  child: CustomTextField(
                    controller: _requisitosCtrl,
                    enabled: widget.isEditable,
                    labelText: 'Requisitos mínimos / escopo preliminar',
                    maxLines: 5,
                    onChanged: (_) => _emitChange(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }
}
