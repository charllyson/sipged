// lib/screens/modules/contracts/hiring/4Cotacao/fornecedor_card.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sipged/_utils/mask/sipged_masks.dart';
import 'package:sipged/_widgets/input/date_field_change.dart';
import 'package:sipged/_widgets/input/text_field_change.dart';
import 'package:sipged/_widgets/layout/responsive_utils.dart';
import 'package:sipged/_widgets/texts/section_text_name.dart';
import 'package:sipged/_widgets/input/drop_down_change.dart';

class FornecedorCard extends StatelessWidget {
  final String title;
  final TextEditingController nomeCtrl;
  final TextEditingController cnpjCtrl;
  final TextEditingController valorCtrl;
  final TextEditingController dataCtrl;
  final TextEditingController linkCtrl;
  final bool enabled;

  // 🔽 NOVOS PARÂMETROS para o dropdown
  final List<String> fornecedoresLabels;
  final Future<String?> Function(BuildContext context)? onAddNewEmpresa;
  final void Function(String? label)? onChangedFornecedor;

  const FornecedorCard({
    super.key,
    required this.title,
    required this.nomeCtrl,
    required this.cnpjCtrl,
    required this.valorCtrl,
    required this.dataCtrl,
    required this.linkCtrl,
    required this.enabled,
    this.fornecedoresLabels = const <String>[],
    this.onAddNewEmpresa,
    this.onChangedFornecedor,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        // padding horizontal de 12 + 12 = 24
        final w5 = inputWidth(
          context: context,
          inner: constraints,
          perLine: 5,
          minItemWidth: 260,
          extraPadding: 29,
          spacing: 12,
        );

        return Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            border: Border.all(color: cs.outlineVariant),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionTitle(text: title),
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  // 🔽 RAZÃO/NOME AGORA COMO DROPDOWN DE COMPANIESBODIES
                  SizedBox(
                    width: w5,
                    child: DropDownChange(
                      controller: nomeCtrl,
                      labelText: 'Razão/Nome',
                      enabled: enabled,
                      items: fornecedoresLabels,
                      showSpecialAlways: true,
                      specialItemLabel: 'Adicionar empresa',
                      onChanged: (label) {
                        if (onChangedFornecedor != null) {
                          onChangedFornecedor!(label);
                        } else {
                          nomeCtrl.text = label ?? '';
                        }
                      },
                      onAddNewItem: onAddNewEmpresa,
                    ),
                  ),
                  SizedBox(
                    width: w5,
                    child: CustomTextField(
                      controller: cnpjCtrl,
                      labelText: 'CNPJ',
                      enabled: false,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(14),
                        SipGedMasks.cnpj,
                      ],
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  SizedBox(
                    width: w5,
                    child: CustomTextField(
                      controller: valorCtrl,
                      labelText: 'Valor cotado (R\$)',
                      enabled: enabled,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  SizedBox(
                    width: w5,
                    child: DateFieldChange(
                      controller: dataCtrl,
                      enabled: enabled,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(8),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: w5,
                    child: CustomTextField(
                      controller: linkCtrl,
                      labelText: 'Link/Arquivo da proposta',
                      enabled: enabled,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
