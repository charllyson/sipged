import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:siged/_blocs/documents/measurement/adjustment/adjustment_measurement_store.dart';

import 'package:siged/_blocs/documents/measurement/report/report_measurement_store.dart';
import 'package:siged/_blocs/documents/measurement/revision/revision_measurement_store.dart';
import 'package:siged/screens/actives/airports/network/active_airports_network_page.dart';
import 'package:siged/screens/actives/airports/records/active_airports_records_page.dart';
import 'package:siged/screens/actives/railways/network/active_railways_network_page.dart';
import 'package:siged/screens/actives/railways/records/active_railways_records_page.dart';

import 'package:siged/screens/commons/listContracts/list_contracts_controller.dart';
import 'package:siged/screens/actives/oaes/network/active_oaes_network_page.dart';
import 'package:siged/screens/sectors/financial/dashboard/dashboard_financial_page.dart';
import 'package:siged/screens/sectors/financial/tab_bar_financial_page.dart';
import 'package:siged/screens/sectors/operation/desapropriation/desapropriation_page.dart';
import 'package:siged/screens/sectors/operation/schedule/schedule_page.dart';
import 'package:siged/screens/sectors/planning/environment/planning_environment_dashboard.dart';
import 'package:siged/screens/sectors/planning/projects/planning_projects_dashboard.dart';
import 'package:siged/screens/sectors/planning/projects/planning_projects_registration_page.dart';
import 'package:siged/screens/menus/menu_drawer.dart';
import 'package:siged/screens/actives/oaes/records/active_oaes_records_page.dart';
import 'package:siged/screens/actives/roads/records/active_roads_records_page.dart';

import 'package:siged/_blocs/system/pages/pages_data.dart';
import 'package:siged/_widgets/buttons/float_button_menu.dart';
import 'package:siged/screens/documents/contract/tab_bar_contract_page.dart';
import 'package:siged/screens/documents/measurement/tab_bar_measurement_page.dart';
import 'package:siged/screens/sectors/planning/rightOfWay/planning_right_of_way_dashboard.dart';
import 'package:siged/screens/sectors/planning/rightOfWay/planning_right_of_way_registration_page.dart';
import 'package:siged/screens/sectors/traffic/accidents/accidents_records_page.dart';
import 'package:siged/screens/sectors/traffic/dashboard/accidents_dashboard_page.dart';
import 'package:siged/screens/sectors/traffic/infrations/infractions_records_page.dart';

import 'package:siged/_blocs/sectors/operation/schedule_bloc.dart';
import 'package:siged/_blocs/documents/contracts/additives/additive_store.dart';
import 'package:siged/_blocs/documents/contracts/apostilles/apostilles_store.dart';
import 'package:siged/_blocs/documents/contracts/contracts/contract_store.dart';
import 'package:siged/screens/actives/roads/network/active_roads_network_page.dart';

import '../../_blocs/sectors/operation/schedule_repository.dart';
import '../commons/listContracts/list_contract_page.dart';
import '../documents/contract/dashboard/dashboard_contracts_page.dart';
import '../../_blocs/documents/contracts/contracts/contracts_controller.dart';
import '../sectors/traffic/infractions-dashboard/infractions_dashboard_page.dart';

// BLoC de usuário
import 'package:siged/_blocs/system/user/user_bloc.dart';
import 'package:siged/_blocs/system/user/user_event.dart';
import 'package:siged/_blocs/system/user/user_state.dart';
import 'package:siged/_blocs/system/user/user_data.dart';

class MenuListPage extends StatefulWidget {
  const MenuListPage({super.key});

  @override
  State<MenuListPage> createState() => _MenuListPageState();
}

class _MenuListPageState extends State<MenuListPage> {
  MenuItem _selectedItem = MenuItem.documentsContractsDashboard;
  bool _didWarmupUserBloc = false;   // warmup do UserBloc
  bool _didWarmupStores = false;     // warmup do ContractsStore

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

  Widget _getPage(MenuItem item, UserData currentUser) {
    switch (item) {
    /// SETOR DE DOCUMENTOS ///
      case MenuItem.documentsContractsDashboard:
      // documentsContractsDashboard
        return ChangeNotifierProvider(
          create: (ctx) {
            final ctrl = ContractsController(
              store: ctx.read<ContractsStore>(),
              additivesStore: ctx.read<AdditivesStore>(),
              apostillesStore: ctx.read<ApostillesStore>(),
              reportsMeasurementStore: ctx.read<ReportsMeasurementStore>(),
              adjustmentsStore: ctx.read<AdjustmentsMeasurementStore>(),   // 👈 novo
              revisionsStore: ctx.read<RevisionsMeasurementStore>(),       // 👈 novo
            );
            WidgetsBinding.instance.addPostFrameCallback((_) => ctrl.initialize());
            return ctrl;
          },
          child: const Scaffold(
            backgroundColor: Colors.white,
            body: DashboardContractPage(),
          ),
        );


      case MenuItem.documentsContractsRecords:
        return _buildContractsListPage((context, contract) {
          context.read<ContractsStore>().select(contract);
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => TabBarContractPage(contractData: contract),
            ),
          );
        });

      case MenuItem.documentsMeasurementsDashboard:
        return ChangeNotifierProvider(
          create: (ctx) => ContractsController(
            store: ctx.read<ContractsStore>(),
            additivesStore: ctx.read<AdditivesStore>(),
            apostillesStore: ctx.read<ApostillesStore>(),
            reportsMeasurementStore: ctx.read<ReportsMeasurementStore>(),
            adjustmentsStore: ctx.read<AdjustmentsMeasurementStore>(), // 👈
            revisionsStore: ctx.read<RevisionsMeasurementStore>(),     // 👈
          )..initialize(),
          child: const Scaffold(
            backgroundColor: Colors.white,
            body: DashboardContractPage(),
          ),
        );

      case MenuItem.documentsMeasurementsRecords:
        return _buildContractsListPage((context, contract) {
          context.read<ContractsStore>().select(contract);
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => TabBarMeasurementPage(contractData: contract),
            ),
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
                  create: (ctx) => ScheduleBloc(),
                  child: SchedulePage(contractData: contract), // 👈 importante
                ),
              ),
            ),
          );
        });



      case MenuItem.operationExpropriationDashboard:
        return ChangeNotifierProvider(
          create: (ctx) => ContractsController(
            store: ctx.read<ContractsStore>(),
            additivesStore: ctx.read<AdditivesStore>(),
            apostillesStore: ctx.read<ApostillesStore>(),
            reportsMeasurementStore: ctx.read<ReportsMeasurementStore>(),
            adjustmentsStore: ctx.read<AdjustmentsMeasurementStore>(), // 👈
            revisionsStore: ctx.read<RevisionsMeasurementStore>(),     // 👈
          )..initialize(),
          child: const Scaffold(
            backgroundColor: Colors.white,
            body: DashboardContractPage(),
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
      case MenuItem.planningProjectDashboard:
        return const PlanningProjectsDashboardPage();
      case MenuItem.planningProjectRegistration:
        return const PlanningProjectsRegistrationPage();
      case MenuItem.planningRightOfWayDashboard:
        return const PlanningRightOfWayDashboard();
      case MenuItem.planningRightOfWayRecords:
        return const PlanningRightOfWayRegistrationPage();
      case MenuItem.planningEnvironmentDashboard:
        return const PlanningEnvironmentDashboardPage();
      case MenuItem.planningEnvironmentRecords:
        return const PlanningEnvironmentDashboardPage();

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
            MaterialPageRoute(
              builder: (_) => TabBarFinancialPage(contractData: contract),
            ),
          );
        });

      case MenuItem.financialCommitmentDashboard:
        return const DashboardFinancialPage();

      case MenuItem.financialCommitmentRecords:
        return _buildContractsListPage((context, contract) {
          context.read<ContractsStore>().select(contract);
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => TabBarFinancialPage(contractData: contract),
            ),
          );
        });

    /// ATIVOS DE RODOVIAS ///
      case MenuItem.activeRoadNetwork:
        return const ActiveRoadsNetworkPage();
      case MenuItem.activeRoadRegistration:
        return const ActiveRoadsRecordsPage();

    /// ATIVOS DE OAEs ///
      case MenuItem.activesOAEsNetwork:
        return const ActiveOAEsNetworkPage();
      case MenuItem.activeOAEsRegistration:
        return const ActiveOaesRecordsPage();

    /// ATIVOS DE AEROPORTOS ///
      case MenuItem.activeAirportsNetwork:
        return const ActiveAirportsNetworkPage();
      case MenuItem.activeAirportsRegistration:
        return const ActiveAirportsRecordsPage();

    /// ATIVOS DE FERROVIAS ///
      case MenuItem.activeRailwaysNetwork:
        return const ActiveRailwaysNetworkPage();
      case MenuItem.activeRailwaysRegistration:
        return const ActiveRailwaysRecordsPage();

    /// ATIVOS DE PORTOS ///
      case MenuItem.activePortsNetwork:
        return const ActiveRoadsNetworkPage();
      case MenuItem.activeRegistrationPorts:
        return const ActiveRoadsRecordsPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Dispara warmup do UserBloc uma única vez
    if (!_didWarmupUserBloc) {
      _didWarmupUserBloc = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<UserBloc>().add(const UserWarmupRequested(
          listenRealtime: true,
          bindCurrentUser: true,
        ));
      });
    }

    return BlocBuilder<UserBloc, UserState>(
      buildWhen: (prev, curr) =>
      prev.current != curr.current || prev.isLoadingUsers != curr.isLoadingUsers,
      builder: (context, userState) {
        final currentUser = userState.current;

        if (currentUser == null) {
          return const Scaffold(
            backgroundColor: Colors.white,
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Warmup dos stores dependentes do usuário — uma vez
        if (!_didWarmupStores) {
          _didWarmupStores = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.read<ContractsStore>().warmup(currentUser);
            // Se houver outros stores que dependem do usuário, faça aqui também.
            // ex: context.read<AdditivesStore>().warmup(currentUser);
          });
        }

        return Scaffold(
          backgroundColor: Colors.white,
          drawer: DrawerMenu(onTap: _onSelectPage),
          body: Stack(
            children: [
              _getPage(_selectedItem, currentUser),
              const FloatButtonMenu(),
            ],
          ),
        );
      },
    );
  }
}
