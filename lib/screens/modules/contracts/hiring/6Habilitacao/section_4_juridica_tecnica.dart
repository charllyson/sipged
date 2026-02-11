import 'package:flutter/material.dart';

import 'package:siged/_widgets/input/custom_text_field.dart';
import 'package:siged/_widgets/input/drop_down_botton_change.dart';
import 'package:siged/_widgets/texts/section_text_name.dart';
import 'package:siged/_widgets/layout/responsive_utils.dart';

import 'package:siged/_blocs/modules/contracts/hiring/0Stages/hiring_data.dart';
import 'package:siged/_blocs/modules/contracts/hiring/6Habilitacao/habilitacao_data.dart';

class SectionJuridicaTecnica extends StatefulWidget {
  final HabilitacaoData data;
  final bool isEditable;
  final void Function(HabilitacaoData updated) onChanged;

  const SectionJuridicaTecnica({
    super.key,
    required this.data,
    required this.isEditable,
    required this.onChanged,
  });

  @override
  State<SectionJuridicaTecnica> createState() =>
      _SectionJuridicaTecnicaState();
}

class _SectionJuridicaTecnicaState extends State<SectionJuridicaTecnica> {
  late final TextEditingController _contratoSocialCtrl;
  late final TextEditingController _cartaoCnpjCtrl;
  late final TextEditingController _atestadosStatusCtrl;
  late final TextEditingController _atestadosLinksCtrl;

  @override
  void initState() {
    super.initState();
    final d = widget.data;

    _contratoSocialCtrl =
        TextEditingController(text: d.contratoSocialLink ?? '');
    _cartaoCnpjCtrl =
        TextEditingController(text: d.cartaoCnpjLink ?? '');
    _atestadosStatusCtrl =
        TextEditingController(text: d.atestadosStatus ?? '');
    _atestadosLinksCtrl =
        TextEditingController(text: d.atestadosLinks ?? '');
  }

  @override
  void didUpdateWidget(covariant SectionJuridicaTecnica oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data != widget.data) {
      final d = widget.data;

      void sync(TextEditingController c, String? v) {
        final text = v ?? '';
        if (c.text != text) c.text = text;
      }

      sync(_contratoSocialCtrl, d.contratoSocialLink);
      sync(_cartaoCnpjCtrl, d.cartaoCnpjLink);
      sync(_atestadosStatusCtrl, d.atestadosStatus);
      sync(_atestadosLinksCtrl, d.atestadosLinks);
    }
  }

  @override
  void dispose() {
    _contratoSocialCtrl.dispose();
    _cartaoCnpjCtrl.dispose();
    _atestadosStatusCtrl.dispose();
    _atestadosLinksCtrl.dispose();
    super.dispose();
  }

  void _emitChange() {
    final updated = widget.data.copyWith(
      contratoSocialLink: _contratoSocialCtrl.text,
      cartaoCnpjLink: _cartaoCnpjCtrl.text,
      atestadosStatus: _atestadosStatusCtrl.text,
      atestadosLinks: _atestadosLinksCtrl.text,
    );
    widget.onChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w4 = inputW4(context, constraints);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionTitle(text: '4) Habilitação Jurídica e Técnica'),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: w4,
                  child: CustomTextField(
                    controller: _contratoSocialCtrl,
                    labelText: 'Contrato/Estatuto social (link/arquivo)',
                    enabled: widget.isEditable,
                    onChanged: (_) => _emitChange(),
                  ),
                ),
                SizedBox(
                  width: w4,
                  child: CustomTextField(
                    controller: _cartaoCnpjCtrl,
                    labelText: 'Cartão CNPJ (link/arquivo)',
                    enabled: widget.isEditable,
                    onChanged: (_) => _emitChange(),
                  ),
                ),
                SizedBox(
                  width: w4,
                  child: DropDownButtonChange(
                    enabled: widget.isEditable,
                    labelText: 'Atestados de capacidade técnica',
                    controller: _atestadosStatusCtrl,
                    items: HiringData.docAtestados,
                    onChanged: (v) {
                      _atestadosStatusCtrl.text = v ?? '';
                      _emitChange();
                    },
                  ),
                ),
                SizedBox(
                  width: w4,
                  child: CustomTextField(
                    controller: _atestadosLinksCtrl,
                    labelText: 'Links/observações dos atestados',
                    maxLines: 1,
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
