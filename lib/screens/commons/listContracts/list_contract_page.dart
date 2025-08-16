import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sisged/_datas/documents/contracts/contracts/contract_style.dart';

import 'package:sisged/_widgets/background/background_cleaner.dart';
import 'package:sisged/screens/commons/footBar/foot_bar.dart';
import 'package:sisged/screens/commons/upBar/up_bar.dart';

import '../../../_datas/documents/contracts/contracts/contract_rules.dart';
import '../../../_datas/documents/contracts/contracts/contracts_data.dart';
import '../../../_provider/user/user_provider.dart';
import '../../../_widgets/buttons/contract_add_button.dart';
import '../../documents/contract/tab_bar_contract_page.dart';
import 'list_contracts_controller.dart'; // <— o controller acima
import 'package:sisged/screens/commons/listContracts/list_contracts_status_widget.dart';

typedef ContractNavigationCallback = void Function(BuildContext context, ContractData contract);

class ListContractsFilteredPage extends StatelessWidget {
  const ListContractsFilteredPage({
    super.key,
    required this.onTapItem,
  });

  final ContractNavigationCallback onTapItem;

  @override
  Widget build(BuildContext context) {
    final controller = ListContractsController.of(context); // listen: true (default)
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          const BackgroundCleaner(),
          Consumer<UserProvider>(
            builder: (context, userProvider, _) {
              final currentUser = userProvider.userData;
              if (currentUser == null) {
                return const Center(child: CircularProgressIndicator());
              }

              // garante init apenas quando há usuário
              controller.initIfNeeded(currentUser);

              return LayoutBuilder(
                builder: (context, constraints) {
                  // primeira carga: se mapa vazio e não está carregando,
                  // aplica filtros (defensivo para cenários sem init)
                  if (!controller.loading && controller.cachedByStatus.isEmpty) {
                    // microtask para não disparar no meio do build
                    Future.microtask(() => controller.applyFilters());
                  }

                  return SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: constraints.maxHeight),
                      child: IntrinsicHeight(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            UpBar(
                              onSearch: controller.onSearchChanged,
                            ),

                            // Seções por status (mantém a mesma API do seu widget atual)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: ContractStyle.statusMenu.map((status) {
                                final label = status.$1;
                                final filter = status.$2;
                                return ContractStatusWidget(
                                  contractsBloc: controller.contractsBloc,
                                  validityBloc: controller.validityBloc,
                                  currentUser: currentUser,
                                  statusLabel: label,
                                  statusFilter: filter,
                                  constraints: constraints,
                                  statusCtrl: controller.statusCtrl,
                                  searchCtrl: controller.searchCtrl,
                                  cachedContracts: controller.cachedByStatus,
                                  sortColumnIndex: controller.sortColumnIndex,
                                  isAscending: controller.isAscending,
                                  onSort: (index, getter) => controller.handleSort(index),
                                  onRefresh: controller.refresh,
                                  onTapItem: onTapItem,
                                );
                              }).toList(),
                            ),

                            const SizedBox(height: 40),
                            const Spacer(),
                            const FootBar(),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
      floatingActionButton: ContractAddButton(
        isEditable: controller.isEditable,
        onAdd: () async {
          final result = await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const TabBarContractPage()),
          );
          if (result == true) {
            await controller.refresh();
          }
        },
      ),
    );
  }
}
