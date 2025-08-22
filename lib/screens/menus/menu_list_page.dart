import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:sisged/_datas/documents/measurement/reports/report_measurement_store.dart';

import 'package:sisged/_blocs/system/user_provider.dart';
import 'package:sisged/screens/commons/listContracts/list_contract_page.dart';
import 'package:sisged/screens/sectors/financial/dashboard/dashboard_financial_page.dart';
import 'package:sisged/screens/sectors/financial/tab_bar_financial_page.dart';
import 'package:sisged/screens/sectors/operation/desapropriation/desapropriation_page.dart';
import 'package:sisged/screens/sectors/operation/schedule/schedule_page.dart';
import 'package:sisged/screens/sectors/planning/planning_dashboard.dart';
import 'package:sisged/screens/sectors/planning/planning_registration_page.dart';
import 'package:sisged/screens/menus/menu_drawer.dart';
import 'package:sisged/screens/actives/oaes/active_oaes_records_page.dart';
import 'package:sisged/screens/actives/roads/active_roads_dashboard_page.dart';
import 'package:sisged/screens/actives/roads/active_roads_records_page.dart';

import 'package:sisged/_datas/system/pages_data.dart';
import 'package:sisged/_widgets/buttons/float_button_menu.dart';
import 'package:sisged/screens/actives/oaes/active_oaes_network_page.dart';
import 'package:sisged/screens/commons/listContracts/list_contracts_controller.dart';
import 'package:sisged/screens/documents/contract/tab_bar_contract_page.dart';
import 'package:sisged/screens/documents/measurement/tab_bar_measurement_page.dart';
import 'package:sisged/screens/sectors/operation/dashboard/dashboard_body.dart';
import 'package:sisged/screens/sectors/operation/dashboard/dashboard_controller.dart';
import 'package:sisged/screens/sectors/traffic/accidents/accidents_records_page.dart';
import 'package:sisged/screens/sectors/traffic/dashboard/accidents_dashboard_page.dart';
import 'package:sisged/screens/sectors/traffic/infrations/infractions_records_page.dart';

import 'package:sisged/_blocs/sectors/operation/schedule_bloc.dart';
import 'package:sisged/_datas/actives/oaes/active_oaes_store.dart';
import 'package:sisged/_datas/documents/contracts/additive/additive_store.dart';
import 'package:sisged/_datas/documents/contracts/apostilles/apostilles_store.dart';
import 'package:sisged/_datas/documents/contracts/contracts/contract_store.dart';
import 'package:sisged/screens/actives/oaes/active_oaes_controller.dart';
import 'package:sisged/screens/actives/oaes/active_oaes_dashboard.dart';
import 'package:sisged/screens/actives/roads/active_roads_network_page.dart';

import '../../_repository/sectors/operation/schedule_repository.dart';
import '../sectors/traffic/infractions-dashboard/infractions_dashboard_page.dart';

class MenuListPage extends StatefulWidget {
  const MenuListPage({super.key});

  @override
  State<MenuListPage> createState() => _MenuListPageState();
}

class _MenuListPageState extends State<MenuListPage> {
  MenuItem _selectedItem = MenuItem.trafficAccidentsRecords;
  bool _didWarmup = false;

  void _onSelectPage(MenuItem item) {
    setState(() => _selectedItem = item);
    Navigator.of(context).pop();
  }

  Widget _buildContractsListPage(ContractNavigationCallback onTap) {
    return ChangeNotifierProvider<ListContractsController>(
      create: (ctx) => ListContractsController.create(ctx),
      child: ListContractsFilteredPage(
          onTapItem: onTap,
      ),
    );
  }

  Widget _getPage(MenuItem item) {
    switch (item) {
    /// SETOR DE DOCUMENTOS ///
      case MenuItem.documentsContractsDashboard:
        return ChangeNotifierProvider(
          create: (ctx) {
            final ctrl = DashboardController(
              store: ctx.read<ContractsStore>(),
              additivesStore: ctx.read<AdditivesStore>(),
              apostillesStore: ctx.read<ApostillesStore>(),
              reportsMeasurementStore: ctx.read<ReportsMeasurementStore>(),
            );
            WidgetsBinding.instance.addPostFrameCallback((_) => ctrl.initialize());
            return ctrl;
          },
          child: const Scaffold(
            backgroundColor: Colors.white,
            body: DashboardBody(),
          ),
        );

      case MenuItem.documentsContractsRecords:
        return _buildContractsListPage((context, contract) {
          context.read<ContractsStore>().select(contract);
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => TabBarContractPage(
                contractData: contract,
              ),
            ),
          );
        });

      case MenuItem.documentsMeasurementsDashboard:
        return ChangeNotifierProvider(
          create: (ctx) {
            final ctrl = DashboardController(
              store: ctx.read<ContractsStore>(),
              additivesStore: ctx.read<AdditivesStore>(),
              apostillesStore: ctx.read<ApostillesStore>(),
              reportsMeasurementStore: ctx.read<ReportsMeasurementStore>(),
            );
            WidgetsBinding.instance.addPostFrameCallback((_) => ctrl.initialize());
            return ctrl;
          },
          child: const Scaffold(
            backgroundColor: Colors.white,
            body: DashboardBody(),
          ),
        );

      case MenuItem.documentsMeasurementsRecords:
        return _buildContractsListPage((context, contract) {
          context.read<ContractsStore>().select(contract);
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => TabBarMeasurementPage(
              contractData: contract,
            )),
          );
        });

    /// SETOR DE OPERAÇÕES ///
      case MenuItem.operationMonitoringWork:
        return _buildContractsListPage((context, contract) {
          context.read<ContractsStore>().select(contract);
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => RepositoryProvider(
                create: (_) => ScheduleRepository(),
                child: BlocProvider(
                  create: (ctx) => ScheduleBloc(ctx.read<ScheduleRepository>()),
                  child: SchedulePage(contractData: contract),
                ),
              ),
            ),
          );
        });

      case MenuItem.operationExpropriationDashboard:
        return ChangeNotifierProvider(
          create: (ctx) {
            final ctrl = DashboardController(
              store: ctx.read<ContractsStore>(),
              additivesStore: ctx.read<AdditivesStore>(),
              apostillesStore: ctx.read<ApostillesStore>(),
              reportsMeasurementStore: ctx.read<ReportsMeasurementStore>(),
            );
            WidgetsBinding.instance.addPostFrameCallback((_) => ctrl.initialize());
            return ctrl;
          },
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
              builder: (_) => DesapropriationPage(contractData: contract),
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
        return const InfractionsDashboardPage();
      case MenuItem.trafficInfractionsRecords:
        return const InfractionsRecordsPage();

    /// SETOR FINANCEIRO ///
      case MenuItem.financialPaymentsDashboard:
        return const DashboardFinancialPage();

      case MenuItem.financialPaymentsRecords:
        return _buildContractsListPage((context, contract) {
          context.read<ContractsStore>().select(contract);
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => TabBarFinancialPage(
              contractData: contract, // ✅ passa o contrato selecionado
            )),
          );
        });

      case MenuItem.financialCommitmentDashboard:
        return const DashboardFinancialPage();

      case MenuItem.financialCommitmentRecords:
        return _buildContractsListPage((context, contract) {
          context.read<ContractsStore>().select(contract);
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => TabBarFinancialPage(
              contractData: contract, // ✅ passa o contrato selecionado
            )),
          );
        });

    /// ATIVOS DE RODOVIAS ///
      case MenuItem.activeRoadDashboard:
        return const ActiveRoadsDashboardPage();
      case MenuItem.activeRoadNetwork:
        return const ActiveRoadsNetworkPage();
      case MenuItem.activeRoadRegistration:
        return const ActiveRoadsRecordsPage();

    /// ATIVOS DE OAEs ///
      case MenuItem.activeOAEsDashboard:
        return const ActiveOaesDashboardPage();
      case MenuItem.activesOAEsNetwork:
        return ChangeNotifierProvider(
          create: (ctx) => ActiveOaesController(
            store: ctx.read<ActiveOaesStore>(),
            currentUser: ctx.read<UserProvider>().userData!, // já garantido antes
          ),
          child: const ActiveOAEsNetworkPage(),
        );

      case MenuItem.activeOAEsRegistration:
        return ChangeNotifierProvider(
          create: (ctx) => ActiveOaesController(
            store: ctx.read<ActiveOaesStore>(),
            currentUser: ctx.read<UserProvider>().userData!,
          ),
          child: const ActiveOaesRecordsPage(),
        );


    /// ATIVOS DE AEROPORTOS ///
      case MenuItem.activeAirportsDashboard:
        return const ActiveRoadsDashboardPage();
      case MenuItem.activeAirportsNetwork:
        return const ActiveRoadsNetworkPage();
      case MenuItem.activeAirportsRegistration:
        return const ActiveRoadsRecordsPage();

    /// ATIVOS DE FERROVIAS ///
      case MenuItem.activeRailwaysDashboard:
        return const ActiveRoadsDashboardPage();
      case MenuItem.activeRailwaysNetwork:
        return const ActiveRoadsNetworkPage();
      case MenuItem.activeRailwaysRegistration:
        return const ActiveRoadsRecordsPage();

    /// ATIVOS DE PORTOS ///
      case MenuItem.activePortsDashboard:
        return const ActiveRoadsDashboardPage();
      case MenuItem.activePortsNetwork:
        return const ActiveRoadsNetworkPage();
      case MenuItem.activeRegistrationPorts:
        return const ActiveRoadsRecordsPage();
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

        // ✅ Agende apenas uma vez após o primeiro frame
        if (!_didWarmup) {
          _didWarmup = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.read<ContractsStore>().warmup(userData);
          });
        }

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
