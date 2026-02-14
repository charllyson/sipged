// lib/screens/_pages/physical_financial/widgets/table/percent_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import 'package:sipged/_widgets/input/custom_text_field.dart';
import 'package:sipged/_widgets/windows/show_window_dialog.dart';

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

  double? parsed;
  String? errorText;
  bool okEnabled = true;

  void recompute(String raw) {
    final txt = raw.replaceAll('.', '').replaceAll(',', '.');
    final v = double.tryParse(txt);
    if (v == null) {
      parsed = null;
      errorText = null;
      okEnabled = false;
      return;
    }
    if (v < 0) {
      parsed = null;
      errorText = 'Informe um valor positivo.';
      okEnabled = false;
      return;
    }
    if (v > maxAllowed) {
      parsed = null;
      errorText = 'Máximo permitido: ${maxAllowed.toStringAsFixed(2)}%.';
      okEnabled = false;
      return;
    }
    parsed = v;
    errorText = null;
    okEnabled = true;
  }

  // valida o valor inicial (se houver)
  recompute(controller.text);

  final restantePct = maxAllowed;
  final restanteReais = serviceTotalReais * (restantePct / 100.0);

  return showWindowDialog<double>(
    context: context,
    title: 'Informe o percentual (%)',
    width: 520,
    barrierDismissible: false,
    child: StatefulBuilder(
      builder: (dialogCtx, setState) {
        final previewPct = (parsed ?? 0);
        final previewReais = serviceTotalReais * (previewPct / 100.0);

        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CustomTextField(
                    width: 120,
                    labelText: 'Atual',
                    controller: controller,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'[0-9.,]'),
                      ),
                    ],
                    suffix: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Text(
                          '%',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
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
                    initialValue:
                    '${alreadyAllocatedPercent.toStringAsFixed(2)}%',
                    outlined: true,
                  ),
                ],
              ),
              if (errorText != null) ...[
                const SizedBox(height: 8),
                Text(
                  errorText!,
                  style: const TextStyle(color: Colors.red),
                ),
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
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(dialogCtx).pop(),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: okEnabled
                        ? () => Navigator.of(dialogCtx).pop(parsed)
                        : null,
                    child: const Text('OK'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    ),
  );
}
