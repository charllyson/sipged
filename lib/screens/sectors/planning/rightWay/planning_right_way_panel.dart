import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:siged/_blocs/sectors/planning/highway_domain/planning_highway_domain_bloc.dart';
import 'package:siged/_blocs/sectors/planning/highway_domain/planning_highway_domain_event.dart';
import 'package:siged/_widgets/background/background_cleaner.dart';

// ⬇️ util de import KML/KMZ/GeoJSON
import 'package:siged/_services/geoJson/send_firebase.dart';

// 🔹 Data do contrato (agora vem pelo construtor)
import 'package:siged/_blocs/documents/contracts/contracts/contract_data.dart';

// 🔹 Página de imóveis
import 'package:siged/screens/sectors/planning/rightWay/right_way_property_page.dart';

class PlanningRightWayPanel extends StatelessWidget {
  final ContractData contractData; // <- recebido do Workspace
  const PlanningRightWayPanel({super.key, required this.contractData});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const BackgroundClean(), // fundo decorativo
        ListView(
          children: [
            const SizedBox(height: 12),

            // === Ação: Adicionar DUP ===
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
                        // TODO: substituir por navegação/form de DUP
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Ação: Adicionar DUP (em implementação)')),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 12),

                  // === Ação: Importar traçado (KML/KMZ/GeoJSON) ===
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
                      subtitle: const Text('Salvar em planning_highway_domain'),
                      trailing: const Icon(Icons.check_circle, color: Colors.grey),
                      onTap: () async {
                        final bloc = context.read<PlanningHighwayDomainBloc>();
                        try {
                          await GeoJsonSendFirebase(
                            context,
                            fixedPath: 'planning_highway_domain', // destino fixo
                          );
                          bloc.add(const PlanningHighwayDomainRefreshRequested());
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

                  // === Ação: Imóveis do Domínio (abre fullscreenDialog) ===
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
                        // Atualiza dados do domínio antes de abrir (se houver provider)
                        try {
                          context
                              .read<PlanningHighwayDomainBloc>()
                              .add(const PlanningHighwayDomainRefreshRequested());
                        } catch (_) {
                          // se o provider não existir aqui, apenas segue com a navegação
                        }

                        if (context.mounted) {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              fullscreenDialog: true, // 👈 conforme pedido
                              builder: (_) => RightWayPropertyPage(contract: contractData),
                            ),
                          );
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
