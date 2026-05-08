import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sipged/_blocs/modules/contracts/contract/contract_data.dart';
import 'package:sipged/_blocs/system/notification/local/notification_local_cubit.dart';
import 'package:sipged/_blocs/system/notification/notification_data.dart';
import 'package:sipged/_blocs/system/notification/notification_type.dart';

import 'package:sipged/_widgets/draw/background/background_change.dart';
import 'package:sipged/screens/modules/planning/land/land_tabs.dart';

class LandPanel extends StatelessWidget {
  final ContractData contractData;
  final VoidCallback? onRequestMapRefresh;

  const LandPanel({
    super.key,
    required this.contractData,
    this.onRequestMapRefresh,
  });

  void _notify(
      BuildContext context, {
        required String title,
        String? subtitle,
        NotificationStatus type = NotificationStatus.info,
        String leadingLabel = 'Direito de Passagem',
        Duration duration = const Duration(seconds: 4),
      }) {
    context.read<NotificationLocalCubit>().show(
      NotificationData(
        title: title,
        subtitle: subtitle,
        type: type,
        leadingLabel: leadingLabel,
        duration: duration,
      ),
    );
  }

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
                  _notify(
                    context,
                    title: 'Em implementação',
                    subtitle: 'Ação: Adicionar DUP',
                    type: NotificationStatus.info,
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