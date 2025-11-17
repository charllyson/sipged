import 'package:flutter/material.dart';
import 'package:siged/_widgets/tiles/tile_widget.dart';
import 'cleanup_subcollections_util.dart';

import 'package:siged/_widgets/notification/app_notification.dart';
import 'package:siged/_widgets/notification/notification_center.dart';

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

        // 1) Confirmação inicial
        final ok = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Confirmar limpeza'),
            content: Text(
              'Isto irá APAGAR as subcoleções em TODOS os documentos de:\n'
                  'Coleção: $collectionPath\n'
                  'Subcoleções: ${subs.join(', ')}\n\n'
                  'As demais coleções não serão tocadas. Deseja continuar?',
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
              ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Apagar')),
            ],
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
          dry = await cleaner.deleteForCollectionPath(collectionPath, subs, dryRun: true);
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

        // 3) Confirma apagar de verdade
        final ok2 = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Apagar agora?'),
            content: const Text('Deseja executar a limpeza de fato? Esta ação é irreversível.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Não')),
              ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Sim, apagar')),
            ],
          ),
        ) ?? false;

        if (!ok2) return;

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
          res = await cleaner.deleteForCollectionPath(collectionPath, subs, dryRun: false);
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

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Limpeza de subcoleções'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: colCtrl,
              decoration: const InputDecoration(
                labelText: 'Caminho da coleção',
                hintText: 'Ex.: contracts ou orgs/ABC/contracts',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: subCtrl,
              decoration: const InputDecoration(
                labelText: 'Subcoleções (separadas por vírgula)',
                hintText: 'Ex.: measurements, adjustmentMeasurement, revisionMeasurement',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              if (colCtrl.text.trim().isEmpty || subCtrl.text.trim().isEmpty) return;
              Navigator.pop(ctx, true);
            },
            child: const Text('Continuar'),
          ),
        ],
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
      final subsStr = subs.entries.map((e) => '  ${e.key}: ${e.value}').join('\n');
      return '$path\n$subsStr';
    }).join('\n\n');

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(child: Text(text.isEmpty ? '(sem itens)' : text)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
        ],
      ),
    );
  }
}
