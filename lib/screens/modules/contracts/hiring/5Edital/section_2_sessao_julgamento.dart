// lib/screens/modules/contracts/hiring/5Edital/section_2_sessao_julgamento.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:sipged/_widgets/input/date_field_change.dart';
import 'package:sipged/_widgets/input/time_field_change.dart';
import 'package:sipged/_widgets/texts/section_text_name.dart';
import 'package:sipged/_widgets/input/text_field_change.dart';
import 'package:sipged/_widgets/layout/responsive_utils.dart';

// ✅ novo (remove mask_class.dart)
import 'package:sipged/_utils/mask/sipged_masks.dart';

import 'package:sipged/_blocs/modules/contracts/hiring/5Edital/edital_data.dart';

class SectionSessaoJulgamento extends StatefulWidget {
  final bool isEditable;
  final EditalData data;
  final void Function(EditalData updated) onChanged;

  const SectionSessaoJulgamento({
    super.key,
    required this.isEditable,
    required this.data,
    required this.onChanged,
  });

  @override
  State<SectionSessaoJulgamento> createState() => _SectionSessaoJulgamentoState();
}

class _SectionSessaoJulgamentoState extends State<SectionSessaoJulgamento> {
  late final TextEditingController _dataSessaoCtrl;
  late final TextEditingController _horaSessaoCtrl;
  late final TextEditingController _responsavelCtrl;
  late final TextEditingController _localPlataformaCtrl;

  @override
  void initState() {
    super.initState();
    final d = widget.data;
    _dataSessaoCtrl = TextEditingController(text: d.dataSessao);
    _horaSessaoCtrl = TextEditingController(text: d.horaSessao);
    _responsavelCtrl = TextEditingController(text: d.responsavel);
    _localPlataformaCtrl = TextEditingController(text: d.localPlataforma);
  }

  @override
  void didUpdateWidget(covariant SectionSessaoJulgamento oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data != widget.data) {
      final d = widget.data;

      if (_dataSessaoCtrl.text != d.dataSessao) _dataSessaoCtrl.text = d.dataSessao;
      if (_horaSessaoCtrl.text != d.horaSessao) _horaSessaoCtrl.text = d.horaSessao;
      if (_responsavelCtrl.text != d.responsavel) _responsavelCtrl.text = d.responsavel;
      if (_localPlataformaCtrl.text != d.localPlataforma) _localPlataformaCtrl.text = d.localPlataforma;
    }
  }

  @override
  void dispose() {
    _dataSessaoCtrl.dispose();
    _horaSessaoCtrl.dispose();
    _responsavelCtrl.dispose();
    _localPlataformaCtrl.dispose();
    super.dispose();
  }

  void _emitChange() {
    final updated = widget.data.copyWith(
      dataSessao: _dataSessaoCtrl.text,
      horaSessao: _horaSessaoCtrl.text,
      responsavel: _responsavelCtrl.text,
      localPlataforma: _localPlataformaCtrl.text,
    );
    widget.onChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    final isEditable = widget.isEditable;

    return LayoutBuilder(
      builder: (context, constraints) {
        final w4 = inputW4(context, constraints);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionTitle(text: '2) Sessão / Abertura & Julgamento'),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: w4,
                  child: DateFieldChange(
                    controller: _dataSessaoCtrl,
                    labelText: 'Data da sessão',
                    enabled: isEditable,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      SipGedMasks.dateDDMMYYYY,
                    ],
                    onChanged: (_) => _emitChange(),
                  ),
                ),
                SizedBox(
                  width: w4,
                  child: TimeFieldChange(
                    controller: _horaSessaoCtrl,
                    labelText: 'Hora da sessão (hh:mm)',
                    enabled: isEditable,
                    textInputType: TextInputType.datetime,
                    inputFormat: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9:]')),
                      LengthLimitingTextInputFormatter(5),
                    ],
                    onChanged: (_) => _emitChange(),
                  ),
                ),
                SizedBox(
                  width: w4,
                  child: CustomTextField(
                    controller: _responsavelCtrl,
                    labelText: 'Responsável (pregoeiro/comissão)',
                    enabled: isEditable,
                    onChanged: (_) => _emitChange(),
                  ),
                ),
                SizedBox(
                  width: w4,
                  child: CustomTextField(
                    controller: _localPlataformaCtrl,
                    labelText: 'Local/Plataforma',
                    enabled: isEditable,
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
