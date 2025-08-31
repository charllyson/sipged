import 'package:flutter/material.dart';
import 'package:siged/admPanel/migrateCollections/migration_service.dart';

class MigrationCollections extends StatelessWidget {
  const MigrationCollections({super.key});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.swap_horiz),
      tileColor: Colors.white10,
      onTap: () async {
        // Loading
        showDialog(
          context: context,
          barrierDismissible: false,
          builder:
              (_) => const Center(child: CircularProgressIndicator()),
        );
        try {
          await migrarMeasurementsParaColecoesNovas();
          if (context.mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Migração (renomeio) concluída!'),
              ),
            );
          }
        } catch (e) {
          if (context.mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Erro na migração: $e')),
            );
          }
        }
      },
      title: const Text(
        'Migrar Medições → novas coleções (campos simples)',
      ),
      subtitle: const Text(
        'Cria reports/adjustment/revisionMeasurement com {id, order, numberprocess, date, value}',
      ),
      trailing: const Icon(Icons.arrow_forward_ios),
    );
  }
}
