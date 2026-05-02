import 'package:flutter/material.dart';

import 'package:sipged/_widgets/loading/loading_tree_dots.dart';
import 'package:sipged/admPanel/firebase/migration_service.dart';

class MigrationCollections extends StatelessWidget {
  const MigrationCollections({super.key});

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
        } catch (_) {
          if (nav.canPop()) nav.pop();
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