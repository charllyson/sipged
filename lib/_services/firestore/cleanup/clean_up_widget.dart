import 'package:flutter/material.dart';
import 'package:siged/_services/firestore/cleanup/cleanup_subcollections.dart';

class CleanUpOldCollections extends StatelessWidget {
  const CleanUpOldCollections({super.key});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.cleaning_services),
      tileColor: Colors.white10,
      title: const Text('Apagar subcoleções antigas de medições'),
      subtitle: const Text('measurements, adjustmentMeasurement, revisionMeasurement'),
      trailing: const Icon(Icons.arrow_forward_ios),
      onTap: () async {
        // 1) Confirmação
        final ok = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Confirmar limpeza'),
            content: const Text(
                'Isto irá APAGAR as subcoleções antigas de TODOS os contratos:\n'
                    '• measurements\n• adjustmentMeasurement\n• revisionMeasurement\n\n'
                    'As novas coleções não serão tocadas. Deseja continuar?'
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
              ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Apagar')),
            ],
          ),
        ) ?? false;

        if (!ok) return;

        // 2) Mostra loading
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => const Center(child: CircularProgressIndicator()),
        );

        try {
          final cleaner = CleanupOldMeasurementSubcollections();

          // (opcional) Dry run: mostra o que será apagado
          final dry = await cleaner.deleteForAllContracts(dryRun: true);

          Navigator.pop(context); // fecha loading do dry-run
          await showDialog<void>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Prévia (dry-run)'),
              content: SingleChildScrollView(
                child: Text(
                  dry.entries.map((e) {
                    final cid = e.key;
                    final m = e.value;
                    return '$cid\n'
                        '  measurements: ${m['measurements']}\n'
                        '  adjustmentMeasurement: ${m['adjustmentMeasurement']}\n'
                        '  revisionMeasurement: ${m['revisionMeasurement']}';
                  }).join('\n\n'),
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Fechar')),
              ],
            ),
          );

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

          // 4) Executa real
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => const Center(child: CircularProgressIndicator()),
          );

          final res = await cleaner.deleteForAllContracts(dryRun: false);

          Navigator.pop(context); // fecha loading
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Subcoleções antigas apagadas com sucesso!')),
            );
          }

          // (opcional) Mostra um resumo do resultado real
          await showDialog<void>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Resumo da limpeza'),
              content: SingleChildScrollView(
                child: Text(
                  res.entries.map((e) {
                    final cid = e.key;
                    final m = e.value;
                    return '$cid\n'
                        '  measurements: ${m['measurements']}\n'
                        '  adjustmentMeasurement: ${m['adjustmentMeasurement']}\n'
                        '  revisionMeasurement: ${m['revisionMeasurement']}';
                  }).join('\n\n'),
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
              ],
            ),
          );
        } catch (e) {
          Navigator.pop(context); // fecha qualquer loading aberto
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Falha ao apagar: $e')),
            );
          }
        }
      },
    );
  }
}
