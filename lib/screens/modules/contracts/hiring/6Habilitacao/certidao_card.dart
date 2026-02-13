import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:sipged/_blocs/modules/contracts/hiring/0Stages/hiring_style.dart';
import 'package:sipged/_utils/mask/sipged_masks.dart';

import 'package:sipged/_widgets/input/custom_text_field.dart';
import 'package:sipged/_widgets/input/drop_down_botton_change.dart';
import 'package:sipged/_widgets/layout/responsive_utils.dart';

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

        return ValueListenableBuilder<TextEditingValue>(
          valueListenable: statusCtrl,
          builder: (context, value, _) {
            final status = value.text;
            final theme = Theme.of(context);
            final colors =
            HiringStyle.certidaoColorsForStatus(status, theme);

            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.background,
                border: Border.all(color: colors.border),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: colors.title,
                    ),
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
                            SipGedMasks.dateDDMMYYYY,
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
      },
    );
  }
}
