// lib/screens/commons/listContracts/list_contracts_filtered_page.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sisged/_blocs/documents/contracts/contracts/contract_style.dart';
import 'package:sisged/_blocs/documents/contracts/contracts/contract_data.dart';
import 'package:sisged/_widgets/background/background_cleaner.dart';
import 'package:sisged/_widgets/buttons/contract_add_button.dart';
import 'package:sisged/_widgets/search/search_widget.dart';
import 'package:sisged/screens/commons/currentUser/user_greeting.dart';
import 'package:sisged/_widgets/footBar/foot_bar.dart';
import 'package:sisged/_widgets/upBar/up_bar.dart';

import 'package:sisged/_blocs/system/user/user_bloc.dart';
import 'package:sisged/_blocs/system/user/user_data.dart';

import '../../screens/documents/contract/tab_bar_contract_page.dart';
import 'list_contracts_controller.dart';
import 'list_contracts_status_widget.dart';

typedef ContractNavigationCallback = void Function(
    BuildContext context,
    ContractData contract,
    );

class ListContractsFilteredPage extends StatelessWidget {
  const ListContractsFilteredPage({
    super.key,
    required this.onTapItem,
  });

  final ContractNavigationCallback onTapItem;

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
                        ),

                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: ContractStyle.statusMenu.map((status) {
                              final label = status.$1;   // título visível
                              final rawKey = status.$2;  // chave de filtro/config
                              final k = rawKey.trim().toUpperCase();
                              final items = controller.cachedByStatus[k] ?? const <ContractData>[];

                              return ContractStatusExpandable(
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
                        ),

                        const SizedBox(height: 24),
                        // (Observação: Expanded dentro de IntrinsicHeight pode causar assert;
                        // mantenho como no seu layout original. Se preferir, troque por Spacer().)
                        const Expanded(child: SizedBox()),
                        const FootBar(),
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
              builder: (_) => TabBarContractPage(contractData: ContractData()),
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
