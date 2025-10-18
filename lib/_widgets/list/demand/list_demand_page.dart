// lib/screens/commons/listContracts/list_contracts_filtered_page.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:siged/_blocs/panels/overview-dashboard/overview_dashboard_style.dart';
import 'package:siged/_blocs/process/contracts/contract_data.dart';
import 'package:siged/_widgets/background/background_cleaner.dart';
import 'package:siged/_widgets/buttons/contract_add_button.dart';
import 'package:siged/_widgets/search/search_widget.dart';
import 'package:siged/_widgets/user/user_greeting.dart';
import 'package:siged/_widgets/footBar/foot_bar.dart';
import 'package:siged/_widgets/upBar/up_bar.dart';

import 'package:siged/_blocs/system/user/user_bloc.dart';
import 'package:siged/_blocs/system/user/user_data.dart';
import 'package:siged/screens/process/hiring/tab_bar_contract_page.dart';

import '../../../_blocs/process/contracts/list_contracts_controller.dart';
import 'list_demand_status.dart';

typedef DemandNavigationCallback = void Function(
    BuildContext context,
    ContractData contract,
    );

class ListDemandPage extends StatelessWidget {
  const ListDemandPage({
    super.key,
    required this.onTapItem,
    this.pageTitle = '',
  });

  final DemandNavigationCallback onTapItem;
  final String pageTitle;

  @override
  Widget build(BuildContext context) {
    final controller = ListContractsController.of(context); // listen: true
    final User? firebaseUser = FirebaseAuth.instance.currentUser;

    // Lê o usuário atual do UserBloc (novo fluxo)
    final UserData? currentUser = context.select<UserBloc, UserData?>(
          (b) => b.state.current,
    );

    if (currentUser == null) {
      // Ainda carregando/bindando o usuário
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Inicializa o controller quando já temos o usuário
    controller.initIfNeeded(currentUser);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          const BackgroundClean(),
          LayoutBuilder(
            builder: (context, constraints) {
              if (!controller.loading && controller.cachedByStatus.isEmpty) {
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
                          actions: [
                            SearchAction(onSearch: controller.onSearchChanged),
                            UserGreeting(firebaseUser: firebaseUser),
                          ],
                          titleWidgets: [
                            Text(pageTitle)
                          ],
                        ),

                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: OverviewDashboardStyle.statusMenu.map((status) {
                            final label = status.$1;   // título visível
                            final rawKey = status.$2;  // chave de filtro/config
                            final k = rawKey.trim().toUpperCase();
                            final items = controller.cachedByStatus[k] ?? const <ContractData>[];

                            return ListDemandStatus(
                              title: label,
                              statusKey: k,
                              items: items,
                              constraints: constraints,
                              sortColumnIndex: controller.sortColumnIndex,
                              isAscending: controller.isAscending,
                              onSort: (index, getter) => controller.handleSort(index),
                              onDelete: (item) async {
                                controller.contractsBloc.deleteContract(item.id!);
                                await controller.refresh();
                              },
                              onTapItem: onTapItem,
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: ContractAddButton(
        isEditable: controller.isEditable,
        onAdd: () async {
          final result = await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => TabBarHiringPage(contractData: ContractData()),
            ),
          );
          if (result == true) {
            await controller.refresh();
          }
        },
      ),
    );
  }
}
