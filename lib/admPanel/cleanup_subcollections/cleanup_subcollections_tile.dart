import 'package:flutter/material.dart';
import 'cleanup_subcollections_util.dart';

class CleanUpSubcollectionsTile extends StatelessWidget {
  const CleanUpSubcollectionsTile({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black12,
      child: ListTile(
        leading: const Icon(Icons.cleaning_services),
        tileColor: Colors.white10,
        title: const Text('Apagar subcoleções (genérico)'),
        subtitle: const Text('Informe coleção e subcoleções (separadas por vírgula)'),
        trailing: const Icon(Icons.arrow_forward_ios),
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
          ) ??
              false;
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
          ) ??
              false;

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
          } finally {
            if (nav.canPop()) nav.pop(); // fecha o loading com segurança
          }

          if (!context.mounted) return;

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Subcoleções apagadas com sucesso!')),
          );

          await _showPreviewDialog(context, res, title: 'Resumo da limpeza');
        },
      ),
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
    ) ??
        false;

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
