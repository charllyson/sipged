// lib/screens/process/hiring/6Habilitacao/sections/_certidao_card.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:siged/_widgets/input/custom_text_field.dart';
import 'package:siged/_widgets/input/drop_down_botton_change.dart';
import 'package:siged/_widgets/layout/responsive_utils.dart';
import 'package:siged/_utils/formats/mask_class.dart';

class CertidaoCard extends StatelessWidget {
  final String titulo;
  final TextEditingController statusCtrl;
  final TextEditingController validadeCtrl;
  final TextEditingController linkCtrl;
  final List<String> itemsStatus;
  final bool enabled;

  const CertidaoCard({
    super.key,
    required this.titulo,
    required this.statusCtrl,
    required this.validadeCtrl,
    required this.linkCtrl,
    required this.itemsStatus,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    final cardBg = Colors.grey.shade100;
    final cardBorder = Colors.grey;

    return LayoutBuilder(
      builder: (context, constraints) {
        final w3 = inputWidth(
          context: context,
          inner: constraints,
          perLine: 3,
          minItemWidth: 260,
          extraPadding: 29,
          spacing: 12,
        );

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: cardBg,
            border: Border.all(color: cardBorder),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titulo,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  SizedBox(
                    width: w3,
                    child: DropDownButtonChange(
                      enabled: enabled,
                      labelText: 'Status',
                      controller: statusCtrl,
                      items: itemsStatus,
                      onChanged: (v) => statusCtrl.text = v ?? '',
                    ),
                  ),
                  SizedBox(
                    width: w3,
                    child: CustomTextField(
                      controller: validadeCtrl,
                      labelText: 'Validade',
                      hintText: 'dd/mm/aaaa',
                      enabled: enabled,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(8),
                        TextInputMask(mask: '99/99/9999'),
                      ],
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  SizedBox(
                    width: w3,
                    child: CustomTextField(
                      controller: linkCtrl,
                      labelText: 'Link/Arquivo',
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
