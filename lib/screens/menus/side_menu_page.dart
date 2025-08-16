// lib/screens/menus/side_menu_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:sisged/_provider/user/user_provider.dart';
import 'package:sisged/screens/commons/listContracts/list_contract_page.dart';
import 'package:sisged/screens/sectors/financial/dashboard/dashboard_financial_page.dart';
import 'package:sisged/screens/sectors/financial/tab_bar_financial_page.dart';
import 'package:sisged/screens/sectors/operation/desapropriation/desapropriation_page.dart';
import 'package:sisged/screens/sectors/operation/schedule/physical_schedule.dart';
import 'package:sisged/screens/sectors/planning/planning_dashboard.dart';
import 'package:sisged/screens/sectors/planning/planning_registration_page.dart';
import 'package:sisged/screens/menus/drawer_menu.dart';
import 'package:sisged/screens/actives/oaes/records/modal_oaes_registration_page.dart';
import 'package:sisged/screens/actives/roads/dashboard/modal_road_dashboard.dart';
import 'package:sisged/screens/actives/roads/records/modal_road_registration_page.dart';

import 'package:sisged/_datas/system/pages_data.dart';
import 'package:sisged/_widgets/buttons/float_button_menu.dart';
import 'package:sisged/screens/actives/roads/network/modal_road_network_page.dart';
import 'package:sisged/screens/actives/oaes/network/modal_oaes_network_page.dart';
import 'package:sisged/screens/commons/listContracts/list_contracts_controller.dart';
import 'package:sisged/screens/documents/contract/tab_bar_contract_page.dart';
import 'package:sisged/screens/documents/measurement/tab_bar_measurement_page.dart';
import 'package:sisged/screens/sectors/operation/dashboard/dashboard_body.dart';
import 'package:sisged/screens/sectors/operation/dashboard/dashboard_controller.dart';
import 'package:sisged/screens/sectors/traffic/accidents/accidents_page.dart';
import 'package:sisged/screens/sectors/traffic/dashboard/accidents_dashboard_page.dart';
import 'package:sisged/screens/sectors/traffic/infrations/infractions_page.dart';

import '../../_datas/documents/contracts/contracts/contract_store.dart';

class SideMenuPage extends StatefulWidget {
  const SideMenuPage({super.key});

  @override
  State<SideMenuPage> createState() => _SideMenuPageState();
}

class _SideMenuPageState extends State<SideMenuPage> {
  MenuItem _selectedItem = MenuItem.documentsContractsRecords;

  void _onSelectPage(MenuItem item) {
    setState(() => _selectedItem = item);
    Navigator.of(context).pop();
  }

  Widget _buildContractsListPage(ContractNavigationCallback onTap) {
    return ChangeNotifierProvider<ListContractsController>(
      create: (ctx) => ListContractsController.create(ctx),
      child: ListContractsFilteredPage(onTapItem: onTap),
    );
  }

  Widget _getPage(MenuItem item) {
    switch (item) {
    /// SETOR DE DOCUMENTOS ///
      case MenuItem.documentsContractsDashboard:
        return ChangeNotifierProvider(
          create: (ctx) => DashboardController(
            store: ctx.read<ContractsStore>(),  // ⭐️ injeta o STORE
          )..initialize(),
          child: const Scaffold(
            backgroundColor: Colors.white,
            body: DashboardBody(),
          ),
        );

      case MenuItem.documentsContractsRecords:
        return _buildContractsListPage((context, contract) {
          // 🔹 grava o selecionado no store e navega
          context.read<ContractsStore>().select(contract);
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const TabBarContractPage()),
          );
        });

      case MenuItem.documentsMeasurementsDashboard:
        return ChangeNotifierProvider(
          create: (ctx) => DashboardController(
            store: ctx.read<ContractsStore>(),  // ⭐️ injeta o STORE
          )..initialize(),
          child: const Scaffold(
            backgroundColor: Colors.white,
            body: DashboardBody(),
          ),
        );

      case MenuItem.documentsMeasurementsRecords:
        return _buildContractsListPage((context, contract) {
          context.read<ContractsStore>().select(contract);
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const TabBarMeasurementPage()),
          );
        });

    /// SETOR DE OPERAÇÕES ///
      case MenuItem.operationMonitoringWork:
        return _buildContractsListPage((context, contract) {
          context.read<ContractsStore>().select(contract);
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const PhysicalSchedule()),
          );
        });

      case MenuItem.operationExpropriationDashboard:
        return ChangeNotifierProvider(
          create: (ctx) => DashboardController(
            store: ctx.read<ContractsStore>(),  // ⭐️ injeta o STORE
          )..initialize(),
          child: const Scaffold(
            backgroundColor: Colors.white,
            body: DashboardBody(),
          ),
        );

      case MenuItem.operationExpropriationRecords:
        return _buildContractsListPage((context, contract) {
          context.read<ContractsStore>().select(contract);
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => DesapropriationPage(contractData: contract), // pode migrar p/ const + store depois
            ),
          );
        });

    /// SETOR DE PLANEJAMENTO ///
      case MenuItem.planningDashboard:
        return const PlanningDashboardPage();
      case MenuItem.planningRegistration:
        return const PlanningRegistrationPage();

    /// SETOR DE TRANSPORTE ///
      case MenuItem.trafficAccidentsDashboard:
        return const AccidentsDashboardPage();
      case MenuItem.trafficAccidentsRecords:
        return const AccidentsRecordsPage();
      case MenuItem.trafficInfractionsDashboard:
        return const AccidentsDashboardPage();
      case MenuItem.trafficInfractionsRecords:
        return const InfractionsRecordsPage();

    /// SETOR FINANCEIRO ///
      case MenuItem.financialPaymentsDashboard:
        return const DashboardFinancialPage();

      case MenuItem.financialPaymentsRecords:
        return _buildContractsListPage((context, contract) {
          context.read<ContractsStore>().select(contract);
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const TabBarFinancialPage()),
          );
        });

      case MenuItem.financialCommitmentDashboard:
        return const DashboardFinancialPage();

      case MenuItem.financialCommitmentRecords:
        return _buildContractsListPage((context, contract) {
          context.read<ContractsStore>().select(contract);
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const TabBarFinancialPage()),
          );
        });

    /// ATIVOS DE RODOVIAS ///
      case MenuItem.activeRoadDashboard:
        return const ModalRoadDashboardPage();
      case MenuItem.activeRoadNetwork:
        return const ModalRoadNetworkPage();
      case MenuItem.activeRoadRegistration:
        return const ModalRoadRegistrationPage();

    /// ATIVOS DE OAEs ///
      case MenuItem.activeOAEsDashboard:
        return const ModalRoadDashboardPage();
      case MenuItem.activesOAEsNetwork:
        return const ModalOAEsNetworkPage();
      case MenuItem.activeOAEsRegistration:
        return const ModalOaesRegistrationPage();

    /// ATIVOS DE AEROPORTOS ///
      case MenuItem.activeAirportsDashboard:
        return const ModalRoadDashboardPage();
      case MenuItem.activeAirportsNetwork:
        return const ModalRoadNetworkPage();
      case MenuItem.activeAirportsRegistration:
        return const ModalRoadRegistrationPage();

    /// ATIVOS DE FERROVIAS ///
      case MenuItem.activeRailwaysDashboard:
        return const ModalRoadDashboardPage();
      case MenuItem.activeRailwaysNetwork:
        return const ModalRoadNetworkPage();
      case MenuItem.activeRailwaysRegistration:
        return const ModalRoadRegistrationPage();

    /// ATIVOS DE PORTOS ///
      case MenuItem.activePortsDashboard:
        return const ModalRoadDashboardPage();
      case MenuItem.activePortsNetwork:
        return const ModalRoadNetworkPage();
      case MenuItem.activeRegistrationPorts:
        return const ModalRoadRegistrationPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, _) {
        final userData = userProvider.userData;

        if (userData == null) {
          return const Scaffold(
            backgroundColor: Colors.white,
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // 🔹 garante a 1ª carga de contratos (idempotente)
        context.read<ContractsStore>().warmup(userData);

        return Scaffold(
          backgroundColor: Colors.white,
          drawer: DrawerMenu(onTap: _onSelectPage),
          body: Stack(
            children: [_getPage(_selectedItem), const FloatButtonMenu()],
          ),
        );
      },
    );
  }
}
