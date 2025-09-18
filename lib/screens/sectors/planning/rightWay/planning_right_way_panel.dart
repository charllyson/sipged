import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:siged/_widgets/background/background_cleaner.dart';

// util de import KML/KMZ/GeoJSON
import 'package:siged/_services/geoJson/send_firebase.dart';

// contrato
import 'package:siged/_blocs/documents/contracts/contracts/contract_data.dart';

// página de imóveis (tabs)
import 'package:siged/screens/sectors/planning/rightWay/planning_right_way_tabs.dart';

import '../../../../_blocs/sectors/planning/highway_domain/planning_highway_domain_bloc.dart';
import '../../../../_blocs/sectors/planning/highway_domain/planning_highway_domain_event.dart';

class PlanningRightWayPropertyPanel extends StatelessWidget {
  final ContractData contractData;

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
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Ação: Adicionar DUP (em implementação)')),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Importar traçado dentro do contrato
                  Card(
                    color: Colors.white,
                    elevation: 0,
                    margin: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Theme.of(context).dividerColor),
                    ),
                    child: ListTile(
                      leading: const Icon(Icons.edit_road),
                      title: const Text('Importar traçado (KML/KMZ/GeoJSON)'),
                      subtitle: Text('Salvar em contracts/${contractData.id}/planning_highway_domain'),
                      trailing: const Icon(Icons.check_circle, color: Colors.grey),
                      onTap: () async {
                        final bloc = context.read<PlanningHighwayDomainBloc>();
                        try {
                          await GeoJsonSendFirebase(
                            context,
                            fixedPath: 'contracts/${contractData.id}/planning_highway_domain',
                          );
                          bloc.add(PlanningHighwayDomainRefreshRequested(contractData.id!));
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Traçado importado com sucesso.')),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                backgroundColor: Colors.red.shade400,
                                content: Text('Falha ao importar: $e'),
                              ),
                            );
                          }
                        }
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
                              builder: (_) => TabBarRightWayPage(
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
