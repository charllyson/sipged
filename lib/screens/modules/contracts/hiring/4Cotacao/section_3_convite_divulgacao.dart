// lib/screens/modules/contracts/hiring/4Cotacao/section_3_convite_divulgacao.dart
import 'package:flutter/material.dart';

import 'package:siged/_widgets/input/custom_date_field.dart';
import 'package:siged/_widgets/texts/section_text_name.dart';
import 'package:siged/_widgets/input/custom_text_field.dart';
import 'package:siged/_widgets/input/drop_down_botton_change.dart';
import 'package:siged/_widgets/layout/responsive_utils.dart';
import 'package:siged/_blocs/modules/contracts/hiring/4Cotacao/cotacao_data.dart';

class SectionConviteDivulgacao extends StatefulWidget {
  final CotacaoData data;
  final bool isEditable;
  final void Function(CotacaoData updated) onChanged;

  const SectionConviteDivulgacao({
    super.key,
    required this.data,
    required this.isEditable,
    required this.onChanged,
  });

  @override
  State<SectionConviteDivulgacao> createState() =>
      _SectionConviteDivulgacaoState();
}

class _SectionConviteDivulgacaoState extends State<SectionConviteDivulgacao> {
  late final TextEditingController _meioDivulgacaoCtrl;
  late final TextEditingController _prazoRespostaCtrl;
  late final TextEditingController _fornecedoresConvidadosCtrl;

  @override
  void initState() {
    super.initState();
    final d = widget.data;

    _meioDivulgacaoCtrl =
        TextEditingController(text: d.meioDivulgacao ?? '');
    _prazoRespostaCtrl =
        TextEditingController(text: d.prazoResposta ?? '');
    _fornecedoresConvidadosCtrl =
        TextEditingController(text: d.fornecedoresConvidados ?? '');
  }

  @override
  void didUpdateWidget(covariant SectionConviteDivulgacao oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data != widget.data) {
      final d = widget.data;

      void sync(TextEditingController c, String? v) {
        final text = v ?? '';
        if (c.text != text) c.text = text;
      }

      sync(_meioDivulgacaoCtrl, d.meioDivulgacao);
      sync(_prazoRespostaCtrl, d.prazoResposta);
      sync(_fornecedoresConvidadosCtrl, d.fornecedoresConvidados);
    }
  }

  @override
  void dispose() {
    _meioDivulgacaoCtrl.dispose();
    _prazoRespostaCtrl.dispose();
    _fornecedoresConvidadosCtrl.dispose();
    super.dispose();
  }

  void _emitChange() {
    final updated = widget.data.copyWith(
      meioDivulgacao: _meioDivulgacaoCtrl.text,
      prazoResposta: _prazoRespostaCtrl.text,
      fornecedoresConvidados: _fornecedoresConvidadosCtrl.text,
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
            const SectionTitle(text: '3) Convite/Divulgação'),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: w3,
                  child: DropDownButtonChange(
                    enabled: widget.isEditable,
                    labelText: 'Meio de divulgação',
                    controller: _meioDivulgacaoCtrl,
                    items: const ['E-mail', 'Portal/Website', 'Telefone', 'Misto'],
                    onChanged: (v) {
                      _meioDivulgacaoCtrl.text = v ?? '';
                      _emitChange();
                    },
                  ),
                ),
                SizedBox(
                  width: w3,
                  child: CustomDateField(
                    controller: _prazoRespostaCtrl,
                    labelText: 'Prazo para resposta (dd/mm/aaaa hh:mm)',
                    enabled: widget.isEditable,
                    onChanged: (_) => _emitChange(),
                  ),
                ),
                SizedBox(
                  width: w3,
                  child: CustomTextField(
                    controller: _fornecedoresConvidadosCtrl,
                    labelText: 'Fornecedores convidados (nomes/CNPJ/e-mails)',
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
