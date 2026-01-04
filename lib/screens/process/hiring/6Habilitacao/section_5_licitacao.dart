import 'package:flutter/material.dart';

import 'package:siged/_widgets/input/custom_text_field.dart';
import 'package:siged/_widgets/input/drop_down_botton_change.dart';
import 'package:siged/_widgets/texts/section_text_name.dart';
import 'package:siged/_widgets/layout/responsive_utils.dart';
import 'package:siged/_utils/validates/form_validation_mixin.dart';

import 'package:siged/_blocs/process/hiring/0Stages/hiring_data.dart';
import 'package:siged/_blocs/process/hiring/6Habilitacao/habilitacao_data.dart';

class SectionLicitacao extends StatefulWidget with FormValidationMixin {
  final HabilitacaoData data;
  final bool isEditable;
  final void Function(HabilitacaoData updated) onChanged;

  SectionLicitacao({
    super.key,
    required this.data,
    required this.isEditable,
    required this.onChanged,
  });

  @override
  State<SectionLicitacao> createState() => _SectionLicitacaoState();
}

class _SectionLicitacaoState extends State<SectionLicitacao> {
  late final TextEditingController _modalidadeCtrl;
  late final TextEditingController _numeroProcessoCtrl;
  late final TextEditingController _ataSessaoCtrl;
  late final TextEditingController _ataAdjudicacaoCtrl;
  late final TextEditingController _editalCtrl;
  late final TextEditingController _oficiosCtrl;

  @override
  void initState() {
    super.initState();
    final d = widget.data;

    _modalidadeCtrl =
        TextEditingController(text: d.modalidade ?? '');
    _numeroProcessoCtrl =
        TextEditingController(text: d.numeroProcesso ?? '');
    _ataSessaoCtrl =
        TextEditingController(text: d.ataSessaoLink ?? '');
    _ataAdjudicacaoCtrl =
        TextEditingController(text: d.ataAdjudicacaoLink ?? '');
    _editalCtrl = TextEditingController(text: d.editalLink ?? '');
    _oficiosCtrl =
        TextEditingController(text: d.oficiosLinks ?? '');
  }

  @override
  void didUpdateWidget(covariant SectionLicitacao oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data != widget.data) {
      final d = widget.data;

      void _sync(TextEditingController c, String? v) {
        final text = v ?? '';
        if (c.text != text) c.text = text;
      }

      _sync(_modalidadeCtrl, d.modalidade);
      _sync(_numeroProcessoCtrl, d.numeroProcesso);
      _sync(_ataSessaoCtrl, d.ataSessaoLink);
      _sync(_ataAdjudicacaoCtrl, d.ataAdjudicacaoLink);
      _sync(_editalCtrl, d.editalLink);
      _sync(_oficiosCtrl, d.oficiosLinks);
    }
  }

  @override
  void dispose() {
    _modalidadeCtrl.dispose();
    _numeroProcessoCtrl.dispose();
    _ataSessaoCtrl.dispose();
    _ataAdjudicacaoCtrl.dispose();
    _editalCtrl.dispose();
    _oficiosCtrl.dispose();
    super.dispose();
  }

  void _emitChange() {
    final updated = widget.data.copyWith(
      modalidade: _modalidadeCtrl.text,
      numeroProcesso: _numeroProcessoCtrl.text,
      ataSessaoLink: _ataSessaoCtrl.text,
      ataAdjudicacaoLink: _ataAdjudicacaoCtrl.text,
      editalLink: _editalCtrl.text,
      oficiosLinks: _oficiosCtrl.text,
    );
    widget.onChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w6 = inputW6(context, constraints);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionTitle(text: '5) Documentos da Licitação/Adesão'),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: w6,
                  child: DropDownButtonChange(
                    enabled: widget.isEditable,
                    labelText: 'Modalidade do processo',
                    controller: _modalidadeCtrl,
                    items: HiringData.modalidadeDeContratacao,
                    onChanged: (v) {
                      _modalidadeCtrl.text = v ?? '';
                      _emitChange();
                    },
                    validator: widget.validateRequired,
                  ),
                ),
                SizedBox(
                  width: w6,
                  child: CustomTextField(
                    controller: _numeroProcessoCtrl,
                    labelText: 'Nº do processo/edital/ARP',
                    enabled: widget.isEditable,
                    onChanged: (_) => _emitChange(),
                  ),
                ),
                SizedBox(
                  width: w6,
                  child: CustomTextField(
                    controller: _ataSessaoCtrl,
                    labelText: 'Ata da sessão (link/arquivo)',
                    enabled: widget.isEditable,
                    onChanged: (_) => _emitChange(),
                  ),
                ),
                SizedBox(
                  width: w6,
                  child: CustomTextField(
                    controller: _ataAdjudicacaoCtrl,
                    labelText: 'Ata de adjudicação (link/arquivo)',
                    enabled: widget.isEditable,
                    onChanged: (_) => _emitChange(),
                  ),
                ),
                SizedBox(
                  width: w6,
                  child: CustomTextField(
                    controller: _editalCtrl,
                    labelText: 'Edital/Termo de Adesão (link/arquivo)',
                    enabled: widget.isEditable,
                    onChanged: (_) => _emitChange(),
                  ),
                ),
                SizedBox(
                  width: w6,
                  child: CustomTextField(
                    controller: _oficiosCtrl,
                    labelText:
                    'Ofícios/comunicações (links/arquivos)',
                    enabled: widget.isEditable,
                    onChanged: (_) => _emitChange(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }
}
