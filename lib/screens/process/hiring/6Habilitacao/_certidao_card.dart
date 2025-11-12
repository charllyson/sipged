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

  double _w(BuildContext ctx, {int itemsPerLine = 4}) => responsiveInputWidth(
      context: ctx, itemsPerLine: itemsPerLine, spacing: 12, margin: 12, extraPadding: 24);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: cs.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titulo, style: TextStyle(fontWeight: FontWeight.w600, color: cs.primary)),
          const SizedBox(height: 8),
          Wrap(spacing: 12, runSpacing: 12, children: [
            SizedBox(
              width: _w(context),
              child: DropDownButtonChange(
                enabled: enabled,
                labelText: 'Status',
                controller: statusCtrl,
                items: itemsStatus,
                onChanged: (v) => statusCtrl.text = v ?? '',
              ),
            ),
            SizedBox(
              width: _w(context),
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
              width: _w(context, itemsPerLine: 1),
              child: CustomTextField(
                controller: linkCtrl,
                labelText: 'Link/Arquivo',
                enabled: enabled,
              ),
            ),
          ]),
        ],
      ),
    );
  }
}
