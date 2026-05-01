import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sipged/_blocs/system/notification/local/notification_cubit.dart';
import 'package:sipged/_blocs/system/notification/local/notification_data.dart';
import 'package:sipged/_blocs/system/notification/local/notification_type.dart';
import 'package:sipged/_services/firestore/migrate/migration_service.dart';
import 'package:sipged/_widgets/loading/loading_tree_dots.dart';

class MigrationCollections extends StatelessWidget {
  const MigrationCollections({super.key});

  void _notify(
      BuildContext context,
      String title, {
        NotificationType type = NotificationType.info,
        String? subtitle,
        Duration duration = const Duration(seconds: 5),
      }) {
    if (!context.mounted) return;

    context.read<NotificationCubit>().show(
      NotificationData(
        title: title,
        subtitle: subtitle,
        leadingLabel: 'Migração',
        type: type,
        duration: duration,
        extra: const <String, dynamic>{
          'module': 'migration_collections',
        },
      ),
      saveInFirebase: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.swap_horiz),
      tileColor: Colors.white10,
      onTap: () async {
        final nav = Navigator.of(context, rootNavigator: true);

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => const LoadingTreeDots(),
        );

        try {
          await migrarMeasurementsParaColecoesNovas();

          if (nav.canPop()) nav.pop();
          if (!context.mounted) return;

          _notify(
            context,
            'Migração concluída',
            subtitle: 'Medições renomeadas para novas coleções',
            type: NotificationType.success,
            duration: const Duration(seconds: 5),
          );
        } catch (e) {
          if (nav.canPop()) nav.pop();
          if (!context.mounted) return;

          _notify(
            context,
            'Erro na migração',
            subtitle: '$e',
            type: NotificationType.error,
            duration: const Duration(seconds: 6),
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