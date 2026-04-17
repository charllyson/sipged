import 'package:flutter/material.dart';
import 'package:sipged/_widgets/draw/background/background_change.dart';
import 'package:sipged/_blocs/modules/contracts/_process/process_data.dart';

import 'package:sipged/screens/modules/planning/land/land_tabs.dart';

import 'package:sipged/_widgets/notification/app_notification.dart';
import 'package:sipged/_widgets/notification/notification_center.dart';

class LandPanel extends StatelessWidget {
  final ProcessData contractData;
  final VoidCallback? onRequestMapRefresh;

  const LandPanel({
    super.key,
    required this.contractData,
    this.onRequestMapRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const BackgroundChange(),
        ListView(
          padding: const EdgeInsets.all(12),
          children: [
            Card(
              color: Colors.white,
              elevation: 0,
              margin: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Theme.of(context).dividerColor),
              ),
              child: ListTile(
                leading: const Icon(Icons.gavel_outlined),
                title: const Text('Adicionar DUP (Decreto de Utilidade Pública)'),
                subtitle: const Text('Cadastrar novo decreto vinculado ao contrato'),
                trailing: const Icon(Icons.check_circle, color: Colors.grey),
                onTap: () {
                  NotificationCenter.instance.show(
                    AppNotification(
                      title: const Text('Em implementação'),
                      subtitle: const Text('Ação: Adicionar DUP'),
                      type: AppNotificationType.info,
                      leadingLabel: const Text('Direito de Passagem'),
                      duration: const Duration(seconds: 4),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Card(
              color: Colors.white,
              elevation: 0,
              margin: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Theme.of(context).dividerColor),
              ),
              child: ListTile(
                leading: const Icon(Icons.home_work_outlined),
                title: const Text('Imóveis do Domínio'),
                subtitle: const Text('Cadastrar e listar propriedades afetadas'),
                trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                onTap: () async {
                  Navigator.of(context).pop();

                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      fullscreenDialog: true,
                      builder: (_) => LandTabs(
                        contractData: contractData,
                      ),
                    ),
                  );

                  onRequestMapRefresh?.call();
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}