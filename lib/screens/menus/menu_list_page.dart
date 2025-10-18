// lib/screens/menus/menu_list_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:siged/_blocs/process/contracts/contract_data.dart';
import 'package:siged/_blocs/process/contracts/contract_storage_bloc.dart';
import 'package:siged/_blocs/process/contracts/contracts_controller.dart';
import 'package:siged/_blocs/process/adjustment/adjustment_measurement_store.dart';
import 'package:siged/_blocs/process/report/report_measurement_store.dart';
import 'package:siged/_blocs/process/revision/revision_measurement_store.dart';
import 'package:siged/_blocs/sectors/operation/civil/civil_schedule_bloc.dart';
import 'package:siged/_blocs/sectors/operation/civil/civil_schedule_event.dart';
import 'package:siged/_blocs/sectors/operation/road/schedule_road_event.dart';
import 'package:siged/_blocs/sectors/operation/road/schedule_road_repository.dart';
import 'package:siged/_widgets/footBar/foot_bar.dart';
import 'package:siged/_widgets/notification/notification_center.dart';
import 'package:siged/_widgets/notification/app_notification.dart';
import 'package:siged/_services/dxf/map_overlay_cubit.dart';
import 'package:siged/_widgets/list/demand/list_demand_page.dart';
import 'package:siged/home_page.dart';
import 'package:siged/screens/panels/specific-dashboard/specific_dashboard_page.dart';
import 'package:siged/screens/process/additive/tab_bar_additive_page.dart';
import 'package:siged/screens/process/apostilles/tab_bar_apostilles_page.dart';
import 'package:siged/screens/process/hiring/tab_bar_contract_page.dart';
import 'package:siged/screens/panels/overview-dashboard/overview_dashboard_page.dart';
import 'package:siged/screens/process/landRegularization/lane_regularization_tabs.dart';
import 'package:siged/screens/process/report/tab_bar_measurement_page.dart';
import 'package:siged/screens/process/validity/tab_bar_validity_page.dart';
import 'package:siged/screens/sectors/operation/schedule/civil/schedule_civil_page.dart';
import 'package:siged/_widgets/toolBox/tool_widget_controller.dart';
import 'package:siged/screens/actives/airports/network/active_airports_network_page.dart';
import 'package:siged/screens/actives/airports/records/active_airports_records_page.dart';
import 'package:siged/screens/actives/railways/network/active_railways_network_page.dart';
import 'package:siged/screens/actives/railways/records/active_railways_records_page.dart';
import 'package:siged/_blocs/process/contracts/list_contracts_controller.dart';
import 'package:siged/screens/actives/oaes/network/active_oaes_network_page.dart';
import 'package:siged/screens/sectors/financial/dashboard/dashboard_financial_page.dart';
import 'package:siged/screens/sectors/financial/tab_bar_financial_page.dart';
import 'package:siged/screens/sectors/operation/schedule/road/schedule_road_workspace_page.dart';
import 'package:siged/screens/sectors/planning/environment/planning_environment_dashboard.dart';
import 'package:siged/screens/menus/menu_drawer.dart';
import 'package:siged/screens/actives/oaes/records/active_oaes_records_page.dart';
import 'package:siged/screens/actives/roads/records/active_roads_records_page.dart';
import 'package:siged/_blocs/system/pages/pages_data.dart';
import 'package:siged/_widgets/buttons/float_button_menu.dart';
import 'package:siged/screens/sectors/planning/rightWay/planning_right_way_workspace.dart';
import 'package:siged/screens/sectors/traffic/accidents/accidents_records_page.dart';
import 'package:siged/screens/sectors/traffic/dashboard/accidents_dashboard_page.dart';
import 'package:siged/screens/sectors/traffic/infractions-dashboard/infractions_dashboard_page.dart';
import 'package:siged/screens/sectors/traffic/infrations-records/infractions_records_page.dart';
import 'package:siged/_blocs/sectors/operation/road/schedule_road_bloc.dart';
import 'package:siged/_blocs/process/additives/additive_store.dart';
import 'package:siged/_blocs/process/apostilles/apostilles_store.dart';
import 'package:siged/_blocs/process/contracts/contract_store.dart';
import 'package:siged/screens/actives/roads/network/active_roads_network_page.dart';
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
  MenuItem? _selectedItem;
  bool _didWarmupUserBloc = false;
  bool _didWarmupStores = false;

  void _onSelectPage(MenuItem item) {
    setState(() => _selectedItem = item);
    Navigator.of(context).maybePop(); // fecha o Drawer
  }

  void _goHome() {
    setState(() => _selectedItem = null);
    Navigator.of(context).maybePop(); // fecha o Drawer se aberto
  }

  void _navigateByWorkType(BuildContext context, ContractData contract) {
    final wt = (contract.workType ?? contract.contractType ?? '').trim().toUpperCase();
    final km = contract.contractExtKm ?? 0.0;
    final totalEstacas = ((km * 1000) / 20).ceil();
    final contractId = contract.id ?? '';

    if (wt.contains('RODOV')) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => RepositoryProvider<ScheduleRoadRepository>(
            create: (_) => ScheduleRoadRepository(),
            child: BlocProvider<ScheduleRoadBloc>(
              create: (ctx) => ScheduleRoadBloc(
                repository: ctx.read<ScheduleRoadRepository>(),
              )..add(ScheduleWarmupRequested(
                contractId: contractId,
                totalEstacas: totalEstacas,
                initialServiceKey: 'geral',
              )),
              child: Scaffold(
                body: ScheduleRoadWorkspacePage(contractData: contract),
              ),
            ),
          ),
        ),
      );
      return;
    }

    if (wt.contains('CONSTRU')) {
      final scheduleCtrl = ScheduleCivilController();
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => MultiBlocProvider(
            providers: [
              BlocProvider<CivilScheduleBloc>(
                create: (ctx) => CivilScheduleBloc()..add(CivilWarmupRequested(contractId)),
              ),
              BlocProvider<MapOverlayCubit>(create: (_) => MapOverlayCubit()),
            ],
            child: Scaffold(
              body: ScheduleCivilPage(
                title: 'Cronograma Residencial',
                pageNumber: 1,
                controller: scheduleCtrl,
                contractId: contractId,
              ),
            ),
          ),
        ),
      );
      return;
    }

    if (wt.contains('OAE') || wt.contains('ARTES ESPECIAIS')) {
      NotificationCenter.instance.show(
        AppNotification(
          title: const Text('Cronograma para OAEs ainda não disponível.'),
          type: AppNotificationType.warning,
        ),
      );
      return;
    }

    NotificationCenter.instance.show(
      AppNotification(
        title: const Text('Tipo de obra não definido'),
        subtitle: Text('Cadastre o tipo para: ${contract.summarySubjectContract ?? 'N/D'}'),
        type: AppNotificationType.error,
      ),
    );
  }

  Widget _buildContractsListPage(DemandNavigationCallback onTap, {required String pageTitle}) {
    return ChangeNotifierProvider<ListContractsController>(
      create: (ctx) => ListContractsController.create(ctx),
      child: ListDemandPage(
        pageTitle: pageTitle,
        onTapItem: onTap,
      ),
    );
  }

  Widget _getPage(MenuItem item, UserData currentUser) {
    switch (item) {
      case MenuItem.overviewDashboard:
        return ChangeNotifierProvider(
          create: (ctx) {
            final ctrl = ContractsController(
              store: ctx.read<ContractsStore>(),
              additivesStore: ctx.read<AdditivesStore>(),
              apostillesStore: ctx.read<ApostillesStore>(),
              reportsMeasurementStore: ctx.read<ReportsMeasurementStore>(),
              adjustmentsStore: ctx.read<AdjustmentsMeasurementStore>(),
              revisionsStore: ctx.read<RevisionsMeasurementStore>(),
              contractStorageBloc: ctx.read<ContractStorageBloc>(),
            );
            WidgetsBinding.instance.addPostFrameCallback((_) => ctrl.initialize());
            return ctrl;
          },
          child: const OverviewDashboardPage(),
        );

      case MenuItem.specificDashboard:
        return _buildContractsListPage((context, contract) {
          context.read<ContractsStore>().select(contract);
          final km = contract.contractExtKm ?? 0.0;
          final totalEstacas = ((km * 1000) / 20).ceil();
          final contractId = contract.id ?? '';

          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => RepositoryProvider<ScheduleRoadRepository>(
                create: (_) => ScheduleRoadRepository(),
                child: BlocProvider<ScheduleRoadBloc>(
                  create: (ctx) => ScheduleRoadBloc(
                    repository: ctx.read<ScheduleRoadRepository>(),
                  )..add(ScheduleWarmupRequested(
                    contractId: contractId,
                    totalEstacas: totalEstacas,
                    initialServiceKey: 'geral',
                    summarySubjectContract: contract.summarySubjectContract,
                  )),
                  child: SpecificDashboardPage(contractData: contract),
                ),
              ),
            ),
          );
        }, pageTitle: 'Planejamento específico');

      case MenuItem.processHiringRecords:
        return _buildContractsListPage((context, contract) {
          context.read<ContractsStore>().select(contract);
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => TabBarHiringPage(contractData: contract)),
          );
        }, pageTitle: 'Contratação');

      case MenuItem.processValidityRecords:
        return _buildContractsListPage((context, contract) {
          context.read<ContractsStore>().select(contract);
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => TabBarValidityPage(contractData: contract)),
          );
        }, pageTitle: 'Ordens e Vigência');

      case MenuItem.processAdditiveRecords:
        return _buildContractsListPage((context, contract) {
          context.read<ContractsStore>().select(contract);
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => TabBarAdditivePage(contractData: contract)),
          );
        }, pageTitle: 'Aditivos');

      case MenuItem.processApostillesRecords:
        return _buildContractsListPage((context, contract) {
          context.read<ContractsStore>().select(contract);
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => TabBarApostillesPage(contractData: contract)),
          );
        }, pageTitle: 'Apostilamentos');

      case MenuItem.processLandRegularizationRecords:
        return _buildContractsListPage((context, contract) {
          context.read<ContractsStore>().select(contract);
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => TabLaneRegularizationPage(contractData: contract)),
          );
        }, pageTitle: 'Apostilamentos');

      case MenuItem.processMeasurementsRecords:
        return _buildContractsListPage((context, contract) {
          context.read<ContractsStore>().select(contract);
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => TabBarMeasurementPage(contractData: contract)),
          );
        }, pageTitle: 'Medições');

      case MenuItem.operationMonitoringWork:
        return _buildContractsListPage((context, contract) {
          context.read<ContractsStore>().select(contract);
          _navigateByWorkType(context, contract);
        }, pageTitle: 'Cronograma Físico');

      case MenuItem.planningProjectRegistration:
        return _buildContractsListPage((context, contract) {
          context.read<ContractsStore>().select(contract);
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => BlocProvider<MapOverlayCubit>(
                create: (_) => MapOverlayCubit(),
                child: Container(),
              ),
            ),
          );
        }, pageTitle: 'Todos os contratos');

      case MenuItem.planningRightOfWayRecords:
        return _buildContractsListPage((context, contract) {
          context.read<ContractsStore>().select(contract);
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => PlanningRightWayPropertyWorkspace(contractData: contract),
            ),
          );
        }, pageTitle: 'Desapropriações');

      case MenuItem.planningEnvironmentRecords:
        return const PlanningEnvironmentDashboardPage();

      case MenuItem.trafficAccidentsDashboard:
        return const AccidentsDashboardPage();
      case MenuItem.trafficAccidentsRecords:
        return const AccidentsRecordsPage();
      case MenuItem.trafficInfractionsDashboard:
        return const InfractionsDashboardPage();
      case MenuItem.trafficInfractionsRecords:
        return const InfractionsRecordsPage();

      case MenuItem.financialPaymentsDashboard:
        return const DashboardFinancialPage();
      case MenuItem.financialPaymentsRecords:
        return _buildContractsListPage((context, contract) {
          context.read<ContractsStore>().select(contract);
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => TabBarFinancialPage(contractData: contract)),
          );
        }, pageTitle: 'Pagamentos de medições');

      case MenuItem.financialCommitmentDashboard:
        return const DashboardFinancialPage();
      case MenuItem.financialCommitmentRecords:
        return _buildContractsListPage((context, contract) {
          context.read<ContractsStore>().select(contract);
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => TabBarFinancialPage(contractData: contract)),
          );
        }, pageTitle: 'Pagamentos de medições');

      case MenuItem.activeRoadNetwork:
        return const ActiveRoadsNetworkPage();
      case MenuItem.activeRoadRegistration:
        return const ActiveRoadsRecordsPage();
      case MenuItem.activesOAEsNetwork:
        return const ActiveOAEsNetworkPage();
      case MenuItem.activeOAEsRegistration:
        return const ActiveOaesRecordsPage();
      case MenuItem.activeAirportsNetwork:
        return const ActiveAirportsNetworkPage();
      case MenuItem.activeAirportsRegistration:
        return const ActiveAirportsRecordsPage();
      case MenuItem.activeRailwaysNetwork:
        return const ActiveRailwaysNetworkPage();
      case MenuItem.activeRailwaysRegistration:
        return const ActiveRailwaysRecordsPage();
      case MenuItem.activePortsNetwork:
        return const ActiveRoadsNetworkPage();
      case MenuItem.activeRegistrationPorts:
        return const ActiveRoadsRecordsPage();
    }
  }

  @override
  Widget build(BuildContext context) {
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

        if (!_didWarmupStores) {
          _didWarmupStores = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.read<ContractsStore>().warmup(currentUser);
          });
        }

        return Scaffold(
          backgroundColor: Colors.white,
          drawer: DrawerMenu(
            onTap: _onSelectPage,
            onTapHome: _goHome, // 👈 agora o logo volta pra Home sem abrir nova rota
          ),
          body: Stack(
            children: [
              if (_selectedItem == null)
                HomeBody(onSelect: _onSelectPage) // corpo, sem Scaffold
                //AccidentsRecordsPage()
              else
                _getPage(_selectedItem!, currentUser),
              const FloatButtonMenu(),
            ],
          ),
          bottomNavigationBar: const FootBar(),
        );
      },
    );
  }
}
