// lib/_widgets/windows/show_window_dialog.dart
import 'package:flutter/material.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';

import 'package:sipged/_widgets/input/text_field_change.dart';
import 'package:sipged/_widgets/windows/window_dialog.dart';

Future<T?> showWindowDialog<T>({
  required BuildContext context,
  required Widget child,
  String? title,
  double? width,
  bool barrierDismissible = true,

  /// controla padding interno do WindowDialog
  EdgeInsets contentPadding = const EdgeInsets.fromLTRB(12, 0, 12, 0),

  /// impede vazamento de ponteiros (Flutter Web + Mapbox)
  bool usePointerInterceptor = true,

  /// 🔥 NOVO: controla SafeArea do showDialog
  bool useSafeArea = false,
}) {
  return showDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,

    // 🔥 AQUI ESTÁ O SEGREDO
    useSafeArea: useSafeArea,

    builder: (ctx) {
      final dialog = WindowDialog(
        title: title,
        width: width,
        contentPadding: contentPadding,
        onClose: () => Navigator.of(ctx).pop(),
        child: child,
      );

      return usePointerInterceptor
          ? PointerInterceptor(child: dialog)
          : dialog;
    },
  );
}


Future<bool> confirmDialog(BuildContext context, String msg) async {
  final result = await showWindowDialog<bool>(
    context: context,
    title: 'Confirmação',
    width: 420,
    usePointerInterceptor: true,
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

  return showWindowDialog<String>(
    context: ctx,
    title: 'Rótulo',
    width: 480,
    usePointerInterceptor: true,
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
                    onPressed: () => Navigator.of(dialogCtx).pop(ctrl.text.trim()),
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
  final result = await showWindowDialog<bool>(
    context: context,
    title: 'Confirmar exclusão',
    width: 420,
    barrierDismissible: true,
    usePointerInterceptor: true,
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
