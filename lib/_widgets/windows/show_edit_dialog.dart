import 'package:flutter/material.dart';
import 'package:sipged/_widgets/input/custom_text_field.dart';
import 'package:sipged/_widgets/windows/window_dialog.dart';

Future<String?> showEditDialog(
    BuildContext context, {
      required String title,
      required String initialValue,
    }) async {
  final ctrl = TextEditingController(text: initialValue);
  final formKey = GlobalKey<FormState>();

  return showDialog<String>(
    context: context,
    barrierDismissible: true,
    builder: (dialogCtx) {
      return WindowDialog(
        title: title,
        onClose: () => Navigator.of(dialogCtx).pop(),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomTextField(
                controller: ctrl,
                labelText: 'Novo nome',
                textInputAction: TextInputAction.done,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Informe um nome';
                  }
                  return null;
                },
                onSubmitted: (v) {
                  if (formKey.currentState?.validate() ?? false) {
                    Navigator.of(dialogCtx).pop(v.trim());
                  }
                },
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(dialogCtx).pop(),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () {
                      if (formKey.currentState?.validate() ?? false) {
                        Navigator.of(dialogCtx).pop(ctrl.text.trim());
                      }
                    },
                    child: const Text('Salvar'),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}
