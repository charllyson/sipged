import 'package:flutter/material.dart';
import 'package:sipged/_services/firestore/migrate/migration_service.dart';

// ✅ notificações ricas
import 'package:sipged/_widgets/notification/app_notification.dart';
import 'package:sipged/_widgets/notification/notification_center.dart';

class MigrationCollections extends StatelessWidget {
  const MigrationCollections({super.key});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.swap_horiz),
      tileColor: Colors.white10,
      onTap: () async {
        // Loading modal
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => const Center(child: CircularProgressIndicator()),
        );
        try {
          await migrarMeasurementsParaColecoesNovas();

          if (!context.mounted) return;
          Navigator.pop(context); // fecha loading

          // 🔔 sucesso
          NotificationCenter.instance.show(
            AppNotification(
              title: const Text('Migração concluída'),
              subtitle: const Text('Medições renomeadas para novas coleções'),
              type: AppNotificationType.success,
              leadingLabel: const Text('Migração'),
              duration: const Duration(seconds: 5),
            ),
          );
        } catch (e) {
          if (!context.mounted) return;
          Navigator.pop(context); // fecha loading

          // 🔔 erro
          NotificationCenter.instance.show(
            AppNotification(
              title: const Text('Erro na migração'),
              subtitle: Text('$e'),
              type: AppNotificationType.error,
              leadingLabel: const Text('Migração'),
              duration: const Duration(seconds: 6),
            ),
          );
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
