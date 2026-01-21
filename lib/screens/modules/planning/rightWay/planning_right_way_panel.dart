import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:siged/_widgets/background/background_cleaner.dart';

// contrato
import 'package:siged/_blocs/modules/contracts/_process/process_data.dart';

// página de imóveis (tabs)
import 'package:siged/screens/modules/planning/rightWay/lane_regularization_tabs.dart';

import '../../../../_blocs/modules/planning/highway_domain/planning_highway_domain_bloc.dart';
import '../../../../_blocs/modules/planning/highway_domain/planning_highway_domain_event.dart';

// ✅ notificações ricas
import 'package:siged/_widgets/notification/app_notification.dart';
import 'package:siged/_widgets/notification/notification_center.dart';

class PlanningRightWayPropertyPanel extends StatelessWidget {
  final ProcessData contractData;

  /// ✅ callback para forçar o refresh do mapa ao voltar do formulário
  final VoidCallback? onRequestMapRefresh;

  const PlanningRightWayPropertyPanel({
    super.key,
    required this.contractData,
    this.onRequestMapRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const BackgroundClean(),
        ListView(
          children: [
            const SizedBox(height: 12),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Column(
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
                        // 🔔 info (placeholder de funcionalidade)
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
                        try {
                          context
                              .read<PlanningHighwayDomainBloc>()
                              .add(PlanningHighwayDomainRefreshRequested(contractData.id!));
                        } catch (_) {}

                        if (context.mounted) {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              fullscreenDialog: true,
                              builder: (_) => TabLaneRegularizationPage(
                                contractData: contractData,
                              ),
                            ),
                          );

                          // ✅ sempre que voltar do formulário, peça refresh do mapa
                          onRequestMapRefresh?.call();
                        }
                      },
                    ),
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
