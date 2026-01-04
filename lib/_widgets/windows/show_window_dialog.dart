import 'package:flutter/material.dart';
import 'package:siged/_widgets/input/custom_text_field.dart';
import 'package:siged/_widgets/windows/window_dialog.dart';

Future<T?> showWindowDialogMac<T>({
  required BuildContext context,
  required Widget child,
  String? title,
  double? width,
  bool barrierDismissible = true,

  /// NOVO: permite controlar o padding interno do WindowDialog
  EdgeInsets contentPadding = const EdgeInsets.fromLTRB(12, 0, 12, 0),
}) {
  return showDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (ctx) {
      return WindowDialog(
        title: title,
        width: width,
        child: child,
        contentPadding: contentPadding,
        onClose: () => Navigator.of(ctx).pop(),
      );
    },
  );
}

Future<bool> confirmDialog(BuildContext context, String msg) async {
  final result = await showWindowDialogMac<bool>(
    context: context,
    title: 'Confirmação',
    width: 420,
    child: Builder(
      builder: (dialogCtx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                msg,
                style: Theme.of(dialogCtx).textTheme.bodyMedium,
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  FilledButton(
                    onPressed: () => Navigator.of(dialogCtx).pop(true),
                    child: const Text('Confirmar'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    ),
  );

  return result ?? false;
}

Future<String?> askLabelDialog(BuildContext ctx, String suggestion) async {
  final ctrl = TextEditingController(text: suggestion);

  return showWindowDialogMac<String>(
    context: ctx,
    title: 'Rótulo do arquivo',
    width: 480,
    child: Builder(
      builder: (dialogCtx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CustomTextField(
                controller: ctrl,
                labelText: 'Rótulo do arquivo',
                onSubmitted: (v) =>
                    Navigator.of(dialogCtx).pop(v.trim()),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  FilledButton(
                    onPressed: () =>
                        Navigator.of(dialogCtx).pop(
                          ctrl.text.trim(),
                        ),
                    child: const Text('Salvar'),
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

Future<void> confirmarExclusao<T>({
  required BuildContext context,
  required T item,
  required void Function(T item) onDelete,
}) async {
  final result = await showWindowDialogMac<bool>(
    context: context,
    title: 'Confirmar exclusão',
    width: 420,
    barrierDismissible: true,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Deseja realmente excluir este item?',
            style: TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                ),
                child: const Text('Excluir'),
              ),
            ],
          ),
        ],
      ),
    ),
  );

  if (result == true) {
    onDelete(item);
  }
}
