// lib/screens/modules/contracts/hiring/3Tr/section_6_licenciamento_seguranca_sustentabilidade.dart
import 'package:flutter/material.dart';

import 'package:siged/_widgets/texts/section_text_name.dart';
import 'package:siged/_widgets/input/custom_text_field.dart';
import 'package:siged/_widgets/input/drop_down_botton_change.dart';
import 'package:siged/_widgets/layout/responsive_utils.dart';
import 'package:siged/_blocs/modules/contracts/hiring/3Tr/tr_data.dart';

class SectionLicenciamentoSegurancaSustentabilidade
    extends StatefulWidget {
  final bool isEditable;
  final TrData data;
  final void Function(TrData updated) onChanged;

  const SectionLicenciamentoSegurancaSustentabilidade({
    super.key,
    required this.isEditable,
    required this.data,
    required this.onChanged,
  });

  @override
  State<SectionLicenciamentoSegurancaSustentabilidade> createState() =>
      _SectionLicenciamentoSegurancaSustentabilidadeState();
}

class _SectionLicenciamentoSegurancaSustentabilidadeState
    extends State<SectionLicenciamentoSegurancaSustentabilidade> {
  late final TextEditingController _licenciamentoCtrl;
  late final TextEditingController _segurancaCtrl;
  late final TextEditingController _sustentabilidadeCtrl;

  @override
  void initState() {
    super.initState();
    final d = widget.data;
    _licenciamentoCtrl =
        TextEditingController(text: d.licenciamentoAmbiental ?? '');
    _segurancaCtrl =
        TextEditingController(text: d.segurancaTrabalho ?? '');
    _sustentabilidadeCtrl =
        TextEditingController(text: d.sustentabilidade ?? '');
  }

  @override
  void didUpdateWidget(
      covariant SectionLicenciamentoSegurancaSustentabilidade oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data != widget.data) {
      final d = widget.data;
      void _sync(TextEditingController c, String? v) {
        final nv = v ?? '';
        if (c.text != nv) c.text = nv;
      }

      _sync(_licenciamentoCtrl, d.licenciamentoAmbiental);
      _sync(_segurancaCtrl, d.segurancaTrabalho);
      _sync(_sustentabilidadeCtrl, d.sustentabilidade);
    }
  }

  @override
  void dispose() {
    _licenciamentoCtrl.dispose();
    _segurancaCtrl.dispose();
    _sustentabilidadeCtrl.dispose();
    super.dispose();
  }

  void _emitChange() {
    final updated = widget.data.copyWith(
      licenciamentoAmbiental: _licenciamentoCtrl.text,
      segurancaTrabalho: _segurancaCtrl.text,
      sustentabilidade: _sustentabilidadeCtrl.text,
    );
    widget.onChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w3 = inputW3(context, constraints);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionTitle(
                text: '6) Licenciamento, Segurança e Sustentabilidade'),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: w3,
                  child: DropDownButtonChange(
                    enabled: widget.isEditable,
                    labelText: 'Licenciamento ambiental',
                    controller: _licenciamentoCtrl,
                    items: const ['Sim', 'Não', 'A confirmar'],
                    onChanged: (v) {
                      _licenciamentoCtrl.text = v ?? '';
                      _emitChange();
                      setState(() {});
                    },
                  ),
                ),
                SizedBox(
                  width: w3,
                  child: CustomTextField(
                    controller: _segurancaCtrl,
                    labelText: 'Segurança do trabalho / Sinalização de obra',
                    maxLines: 1,
                    enabled: widget.isEditable,
                    onChanged: (_) => _emitChange(),
                  ),
                ),
                SizedBox(
                  width: w3,
                  child: CustomTextField(
                    controller: _sustentabilidadeCtrl,
                    labelText:
                    'Diretrizes de sustentabilidade e acessibilidade',
                    maxLines: 1,
                    enabled: widget.isEditable,
                    onChanged: (_) => _emitChange(),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
