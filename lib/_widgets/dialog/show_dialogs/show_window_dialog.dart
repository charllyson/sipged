import 'package:flutter/material.dart';

import 'package:sipged/_widgets/input/text_field_change.dart';
import 'package:sipged/_widgets/dialog/windows/window_dialog.dart';

typedef WindowDialogWrapper = Widget Function(Widget dialog);

Future<T?> showWindowDialog<T>({
  required BuildContext context,
  required Widget child,
  String? title,
  double? width,
  bool barrierDismissible = true,

  /// Controla padding interno do WindowDialog.
  EdgeInsets contentPadding = const EdgeInsets.fromLTRB(12, 0, 12, 0),

  /// Controla SafeArea do showDialog.
  bool useSafeArea = false,

  /// Permite que telas específicas envolvam o dialog com PointerInterceptor,
  /// Sem fazer este helper depender do pacote pointer_interceptor.
  ///
  /// Exemplo:
  /// dialogWrapper: (dialog) => PointerInterceptor(child: dialog),
  WindowDialogWrapper? dialogWrapper,
}) {
  return showDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    useSafeArea: useSafeArea,
    builder: (ctx) {
      final dialog = WindowDialog(
        title: title,
        width: width,
        contentPadding: contentPadding,
        onClose: () => Navigator.of(ctx).pop(),
        child: child,
      );

      if (dialogWrapper != null) {
        return dialogWrapper(dialog);
      }

      return dialog;
    },
  );
}

Future<bool> confirmDialog(BuildContext context, String msg) async {
  final result = await showWindowDialog<bool>(
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

  try {
    return await showWindowDialog<String>(
      context: ctx,
      title: 'Rótulo',
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
                  labelText: 'Rótulo',
                  onSubmitted: (v) => Navigator.of(dialogCtx).pop(v.trim()),
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    FilledButton(
                      onPressed: () {
                        Navigator.of(dialogCtx).pop(ctrl.text.trim());
                      },
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
  } finally {
    ctrl.dispose();
  }
}

Future<void> confirmarExclusao<T>({
  required BuildContext context,
  required T item,
  required void Function(T item) onDelete,
}) async {
  final result = await showWindowDialog<bool>(
    context: context,
    title: 'Confirmar exclusão',
    width: 420,
    barrierDismissible: true,
    child: Builder(
      builder: (dialogCtx) {
        return Padding(
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
                    onPressed: () => Navigator.of(dialogCtx).pop(true),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                    ),
                    child: const Text('Excluir'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    ),
  );

  if (result == true) {
    onDelete(item);
  }
}