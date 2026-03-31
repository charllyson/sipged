import 'package:flutter/material.dart';
import 'package:sipged/_widgets/input/text_field_change.dart';
import 'package:sipged/_widgets/tiles/tile_widget.dart';
import 'package:sipged/_widgets/windows/show_window_dialog.dart';
import 'cleanup_subcollections_util.dart';

import 'package:sipged/_widgets/notification/app_notification.dart';
import 'package:sipged/_widgets/notification/notification_center.dart';

class CleanUpSubcollectionsTile extends StatelessWidget {
  const CleanUpSubcollectionsTile({super.key});

  @override
  Widget build(BuildContext context) {
    return TileWidget(
      leading: Icons.cleaning_services,
      tileColor: Colors.white10,
      title: 'Apagar subcoleções (genérico)',
      subtitle: 'Informe coleção e subcoleções (separadas por vírgula)',
      onTap: () async {
        // Use sempre o NavigatorState capturado para fechar diálogos.
        final nav = Navigator.of(context, rootNavigator: true);

        final params = await _askParams(context);
        if (params == null) return;

        final collectionPath = params.$1.trim();
        final subs = params.$2;

        // 1) Confirmação inicial (WindowDialog)
        final ok = await showWindowDialog<bool>(
          context: context,
          title: 'Confirmar limpeza',
          width: 520,
          barrierDismissible: true,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Isto irá APAGAR as subcoleções em TODOS os documentos de:\n'
                      'Coleção: $collectionPath\n'
                      'Subcoleções: ${subs.join(', ')}\n\n'
                      'As demais coleções não serão tocadas. Deseja continuar?',
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Cancelar'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.red.shade600,
                      ),
                      child: const Text('Apagar'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ) ?? false;

        if (!ok) return;

        // 2) DRY-RUN com loading
        if (context.mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => const Center(child: CircularProgressIndicator()),
          );
        }

        Map<String, Map<String, int>> dry = const {};
        try {
          final cleaner = SubcollectionCleaner();
          dry = await cleaner.deleteForCollectionPath(
            collectionPath,
            subs,
            dryRun: true,
          );
        } catch (e) {
          // fecha loading e informa erro
          if (nav.canPop()) nav.pop();
          NotificationCenter.instance.show(
            AppNotification(
              title: const Text('Falha no dry-run'),
              subtitle: Text('$e'),
              type: AppNotificationType.error,
              leadingLabel: const Text('Limpeza'),
              duration: const Duration(seconds: 6),
            ),
          );
          return;
        } finally {
          if (nav.canPop()) nav.pop(); // fecha o loading com segurança
        }

        if (!context.mounted) return;
        await _showPreviewDialog(context, dry, title: 'Prévia (dry-run)');

        // 3) Confirma apagar de verdade (usa confirmDialog, que já pode estar mac-izado)
        final ok2 = await confirmDialog(context, 'Apagar de verdade?');
        if (ok2 != true) return;

        // 4) Execução real com loading
        if (context.mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => const Center(child: CircularProgressIndicator()),
          );
        }

        Map<String, Map<String, int>> res = const {};
        try {
          final cleaner = SubcollectionCleaner();
          res = await cleaner.deleteForCollectionPath(
            collectionPath,
            subs,
            dryRun: false,
          );
        } catch (e) {
          // fecha loading e informa erro
          if (nav.canPop()) nav.pop();
          NotificationCenter.instance.show(
            AppNotification(
              title: const Text('Erro ao apagar subcoleções'),
              subtitle: Text('$e'),
              type: AppNotificationType.error,
              leadingLabel: const Text('Limpeza'),
              duration: const Duration(seconds: 6),
            ),
          );
          return;
        } finally {
          if (nav.canPop()) nav.pop(); // fecha o loading com segurança
        }

        if (!context.mounted) return;

        // ✅ sucesso via NotificationCenter
        NotificationCenter.instance.show(
          AppNotification(
            title: const Text('Subcoleções apagadas com sucesso!'),
            type: AppNotificationType.success,
            leadingLabel: const Text('Limpeza'),
            duration: const Duration(seconds: 4),
          ),
        );

        await _showPreviewDialog(context, res, title: 'Resumo da limpeza');
      },
    );
  }

  Future<(String, List<String>)?> _askParams(BuildContext context) async {
    final colCtrl = TextEditingController();
    final subCtrl = TextEditingController();

    final ok = await showWindowDialog<bool>(
      context: context,
      title: 'Limpeza de subcoleções',
      width: 520,
      barrierDismissible: true,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomTextField(
              controller: colCtrl,
              labelText: 'Caminho da coleção',
            ),
            const SizedBox(height: 12),
            CustomTextField(
              controller: subCtrl,
              labelText: 'Subcoleções (separadas por vírgula)',
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancelar'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () {
                    if (colCtrl.text.trim().isEmpty ||
                        subCtrl.text.trim().isEmpty) {
                      return;
                    }
                    Navigator.of(context).pop(true);
                  },
                  child: const Text('Continuar'),
                ),
              ],
            ),
          ],
        ),
      ),
    ) ?? false;

    if (!ok) return null;

    final subs = subCtrl.text
        .split(RegExp(r'[,\n]'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    return (colCtrl.text.trim(), subs);
  }

  Future<void> _showPreviewDialog(
      BuildContext context,
      Map<String, Map<String, int>> data, {
        required String title,
      }) async {
    final text = data.entries.map((docEntry) {
      final path = docEntry.key; // ex.: contracts/abc123
      final subs = docEntry.value;
      final subsStr =
      subs.entries.map((e) => '  ${e.key}: ${e.value}').join('\n');
      return '$path\n$subsStr';
    }).join('\n\n');

    await showWindowDialog<void>(
      context: context,
      title: title,
      width: 520,
      barrierDismissible: true,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 260,
              child: SingleChildScrollView(
                child: Text(
                  text.isEmpty ? '(sem itens)' : text,
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
