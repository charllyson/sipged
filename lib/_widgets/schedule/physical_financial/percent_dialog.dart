// lib/screens/_pages/physical_financial/widgets/table/percent_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:siged/_widgets/input/custom_text_field.dart';

Future<double?> showPhysFinPercentDialog({
  required BuildContext context,
  required double current,
  required double alreadyAllocatedPercent,
  required double serviceTotalReais,
}) async {
  final maxAllowed = (100.0 - alreadyAllocatedPercent).clamp(0.0, 100.0);
  final controller = TextEditingController(
    text: current == 0 ? '' : current.toStringAsFixed(current % 1 == 0 ? 0 : 1),
  );

  return showDialog<double>(
    context: context,
    barrierDismissible: false,
    builder: (c) {
      double? parsed;
      String? errorText;
      bool okEnabled = true;

      void recompute(String raw) {
        final txt = raw.replaceAll('.', '').replaceAll(',', '.');
        final v = double.tryParse(txt);
        if (v == null) {
          parsed = null; errorText = null; okEnabled = false; return;
        }
        if (v < 0) {
          parsed = null; errorText = 'Informe um valor positivo.'; okEnabled = false; return;
        }
        if (v > maxAllowed) {
          parsed = null; errorText = 'Máximo permitido: ${maxAllowed.toStringAsFixed(2)}%.'; okEnabled = false; return;
        }
        parsed = v; errorText = null; okEnabled = true;
      }

      recompute(controller.text);

      final restantePct = maxAllowed;
      final restanteReais = serviceTotalReais * (restantePct / 100.0);

      return StatefulBuilder(
        builder: (c, setState) {
          final previewPct = (parsed ?? 0);
          final previewReais = serviceTotalReais * (previewPct / 100.0);

          return AlertDialog(
            backgroundColor: Colors.white,
            title: const Text('Informe o percentual (%)'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CustomTextField(
                      width: 120,
                      labelText: 'Atual',
                      controller: controller,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
                      suffix: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('%', style: TextStyle(fontWeight: FontWeight.w600)),
                        ],
                      ),
                      outlined: true,
                      onChanged: (txt) => setState(() => recompute(txt)),
                    ),
                    const SizedBox(width: 12),
                    CustomTextField(
                      width: 140,
                      readOnly: true,
                      enabled: false,
                      labelText: 'Já distribuídos',
                      initialValue: '${alreadyAllocatedPercent.toStringAsFixed(2)}%',
                      outlined: true,
                    ),
                  ],
                ),
                if (errorText != null) ...[
                  const SizedBox(height: 8),
                  Text(errorText!, style: const TextStyle(color: Colors.red)),
                ],
                const SizedBox(height: 12),
                Text(
                  'Resta: ${restantePct.toStringAsFixed(2)}% '
                      '(${NumberFormat.simpleCurrency(locale: "pt_BR").format(restanteReais)})',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text(
                  'Este período (${previewPct.toStringAsFixed(2)}%): '
                      '${NumberFormat.simpleCurrency(locale: "pt_BR").format(previewReais)}',
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(c), child: const Text('Cancelar')),
              ElevatedButton(
                onPressed: okEnabled ? () => Navigator.pop(c, parsed) : null,
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    },
  );
}
