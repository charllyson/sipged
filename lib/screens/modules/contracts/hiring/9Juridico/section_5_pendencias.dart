// lib/screens/modules/contracts/hiring/9Juridico/section_5_pendencias.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:siged/_utils/mask/sipged_masks.dart';

import 'package:siged/_widgets/input/custom_date_field.dart';
import 'package:siged/_widgets/layout/responsive_utils.dart';
import 'package:siged/_widgets/input/custom_text_field.dart';
import 'package:siged/_widgets/texts/section_text_name.dart';
import 'package:siged/_blocs/modules/contracts/hiring/9Juridico/parecer_juridico_data.dart';

class SectionPendencias extends StatefulWidget {
  final ParecerJuridicoData data;
  final bool isEditable;
  final void Function(ParecerJuridicoData updated) onChanged;

  const SectionPendencias({
    super.key,
    required this.data,
    required this.isEditable,
    required this.onChanged,
  });

  @override
  State<SectionPendencias> createState() => _SectionPendenciasState();
}

class _SectionPendenciasState extends State<SectionPendencias> {
  late final TextEditingController _pendDescricaoCtrl;
  late final TextEditingController _pendPrazoCtrl;
  late final TextEditingController _pendResponsavelCtrl;

  @override
  void initState() {
    super.initState();
    _pendDescricaoCtrl =
        TextEditingController(text: widget.data.pendDescricao ?? '');
    _pendPrazoCtrl =
        TextEditingController(text: widget.data.pendPrazo ?? '');
    _pendResponsavelCtrl =
        TextEditingController(text: widget.data.pendResponsavel ?? '');
  }

  @override
  void didUpdateWidget(covariant SectionPendencias oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data != widget.data) {
      _pendDescricaoCtrl.text = widget.data.pendDescricao ?? '';
      _pendPrazoCtrl.text = widget.data.pendPrazo ?? '';
      _pendResponsavelCtrl.text = widget.data.pendResponsavel ?? '';
    }
  }

  @override
  void dispose() {
    _pendDescricaoCtrl.dispose();
    _pendPrazoCtrl.dispose();
    _pendResponsavelCtrl.dispose();
    super.dispose();
  }

  void _emitChange() {
    final updated = widget.data.copyWith(
      pendDescricao: _pendDescricaoCtrl.text,
      pendPrazo: _pendPrazoCtrl.text,
      pendResponsavel: _pendResponsavelCtrl.text,
    );
    widget.onChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(text: '5) Pendências e Prazos de Saneamento'),
        LayoutBuilder(
          builder: (context, constraints) {
            final w4 = inputW4(context, constraints);
            final w1 = inputW1(context, constraints);

            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: w4,
                  child: CustomTextField(
                    controller: _pendDescricaoCtrl,
                    labelText: 'Pendências apontadas (resumo)',
                    maxLines: 2,
                    enabled: widget.isEditable,
                    textAlignVertical: TextAlignVertical.top,
                    onChanged: (_) => _emitChange(),
                  ),
                ),
                SizedBox(
                  width: w4,
                  child: CustomDateField(
                    controller: _pendPrazoCtrl,
                    labelText: 'Prazo para saneamento',
                    enabled: widget.isEditable,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(8),
                      SipGedMasks.dateDDMMYYYY,
                    ],
                    onChanged: (_) => _emitChange(),
                  ),
                ),
                SizedBox(
                  width: w1,
                  child: CustomTextField(
                    controller: _pendResponsavelCtrl,
                    labelText: 'Responsável pelo saneamento',
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
