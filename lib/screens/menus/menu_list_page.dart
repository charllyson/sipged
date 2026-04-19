// lib/screens/menus/menu_list_page.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';

// ===== Process (core) =====
import 'package:sipged/_blocs/modules/contracts/_process/process_data.dart';
import 'package:sipged/_blocs/modules/contracts/_process/process_store.dart';

// ===== Dashboards / Stores auxiliares =====
import 'package:sipged/_blocs/modules/contracts/hiring/1Dfd/dfd_cubit.dart';

// ===== Setores (Operação) =====
import 'package:sipged/_blocs/modules/operation/operation/civil/civil_schedule_bloc.dart';
import 'package:sipged/_blocs/modules/operation/operation/civil/civil_schedule_event.dart';

// ✅ Road agora usa Cubit
import 'package:sipged/_blocs/modules/operation/operation/road/schedule_road_repository.dart';
import 'package:sipged/_blocs/modules/operation/operation/road/schedule_road_cubit.dart';

// ===== UI / Serviços =====
import 'package:sipged/_widgets/notification/notification_center.dart';
import 'package:sipged/_widgets/notification/app_notification.dart';
import 'package:sipged/_services/files/dxf/map_overlay_cubit.dart';
import 'package:sipged/_widgets/list/demand/list_demand_page.dart';
import 'package:sipged/screens/common/home/home_page.dart';
import 'package:sipged/screens/modules/financial/budget/budget_network_page.dart';
import 'package:sipged/screens/modules/financial/dashboard/financial_dashboard_network_page.dart';
import 'package:sipged/screens/modules/financial/empenhos/empenho_network_page.dart';

// ===== Páginas =====
import 'package:sipged/screens/modules/operation/schedule/financial/hiring_schedule_page.dart';
import 'package:sipged/screens/modules/traffic/accidents/dashboard/accident_dashboard_page.dart';
import 'package:sipged/screens/panels/specific-dashboard/specific_dashboard_page.dart';

import 'package:sipged/screens/modules/contracts/additive/tab_bar_additive_page.dart';
import 'package:sipged/screens/modules/contracts/apostilles/tab_bar_apostilles_page.dart';
import 'package:sipged/screens/modules/contracts/budget/hiring_budget_page.dart';
import 'package:sipged/screens/modules/contracts/hiring/tab_bar_hiring_page.dart';

import 'package:sipged/screens/panels/overview-dashboard/general_dashboard_page.dart';
import 'package:sipged/screens/modules/contracts/measurement/tab_bar_measurement_page.dart';
import 'package:sipged/screens/modules/contracts/validity/validity_tab_bar.dart';

import 'package:sipged/screens/modules/operation/schedule/physical/civil/schedule_civil_workspace_page.dart';
import 'package:sipged/_widgets/schedule/civil/schedule_civil_controller.dart';

import 'package:sipged/screens/modules/actives/airports/network/active_airports_network_page.dart';
import 'package:sipged/screens/modules/actives/airports/records/active_airports_records_page.dart';
import 'package:sipged/screens/modules/actives/railways/network/active_railways_network_page.dart';
import 'package:sipged/screens/modules/actives/railways/records/active_railways_records_page.dart';
import 'package:sipged/screens/modules/actives/oaes/network/active_oaes_network_page.dart';
import 'package:sipged/screens/modules/actives/oaes/records/active_oaes_records_page.dart';
import 'package:sipged/screens/modules/actives/roads/network/active_roads_network_page.dart';
import 'package:sipged/screens/modules/actives/roads/records/active_roads_records_page.dart';

import 'package:sipged/screens/modules/operation/schedule/physical/road/schedule_road_workspace_page.dart';
import 'package:sipged/screens/modules/planning/geo/geo_network_page.dart';
import 'package:sipged/screens/menus/menu_drawer.dart';

import 'package:sipged/_blocs/system/module/module_data.dart';
import 'package:sipged/_widgets/buttons/float_button_menu.dart';

import 'package:sipged/screens/modules/planning/land/land_page.dart';

import 'package:sipged/screens/modules/traffic/accidents/records/accidents_records_network_page.dart';
import 'package:sipged/screens/modules/traffic/infractions/infractions_dashboard_page.dart';
import 'package:sipged/screens/modules/traffic/infractions/infractions_records_page.dart';

// ===== Sistema / Usuários =====
import 'package:sipged/_blocs/system/user/user_bloc.dart';
import 'package:sipged/_blocs/system/user/user_event.dart';
import 'package:sipged/_blocs/system/user/user_state.dart';
import 'package:sipged/_blocs/system/user/user_data.dart';

// ===== DFD via BLoC =====
import 'package:sipged/_blocs/modules/contracts/hiring/1Dfd/dfd_data.dart';

// ===== Publicação (para número do contrato) =====
import 'package:sipged/_blocs/modules/contracts/hiring/10Publicacao/publicacao_extrato_cubit.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/10Publicacao/publicacao_extrato_data.dart';

class MenuListPage extends StatefulWidget {
  const MenuListPage({super.key});

  @override
  State<MenuListPage> createState() => _MenuListPageState();
}

class _MenuListPageState extends State<MenuListPage> {
  ModuleItem? _selectedItem;
  bool _didWarmupUserBloc = false;
  bool _didWarmupStores = false;

  @override
  void initState() {
    super.initState();
  }

  void _onSelectPage(ModuleItem item) {
    setState(() => _selectedItem = item);
    Navigator.of(context).maybePop();
  }

  void _goHome() {
    setState(() => _selectedItem = null);
    Navigator.of(context).maybePop();
  }

  Future<String> _buildContractLabel(
      BuildContext context,
      String contractId, {
        DfdData? dfdData,
      }) async {
    final dfdCubit = context.read<DfdCubit>();
    final pubCubit = context.read<PublicacaoExtratoCubit>();

    DfdData? dfd = dfdData;

    if (dfd == null) {
      try {
        dfd = await dfdCubit.getDataForContract(contractId);
      } catch (_) {}
    }

    PublicacaoExtratoData? publicacao;
    try {
      publicacao = await pubCubit.getDataForContract(contractId);
    } catch (_) {}

    final numero = (publicacao?.numeroContrato ?? '').trim();
    final descricao = (dfd?.descricaoObjeto ?? '').trim();

    if (numero.isNotEmpty && descricao.isNotEmpty) return '$numero - $descricao';
    if (numero.isNotEmpty) return numero;
    if (descricao.isNotEmpty) return descricao;

    return 'Contrato $contractId';
  }

  Future<void> _navigateByWorkType(
      BuildContext context,
      ProcessData contract,
      ) async {
    final navigator = Navigator.of(context);
    final dfdBloc = context.read<DfdCubit>();

    final contractId = contract.id ?? '';
    if (contractId.isEmpty) {
      NotificationCenter.instance.show(
        AppNotification(
          title: const Text('Contrato sem ID'),
          subtitle: const Text('Não foi possível abrir o cronograma.'),
          type: AppNotificationType.error,
        ),
      );
      return;
    }

    final DfdData? dfd = await dfdBloc.getDataForContract(contractId);
    if (!context.mounted) return;

    final tipoObra = (dfd?.tipoObra ?? '').trim().toUpperCase();

    final resumoContrato =
    await _buildContractLabel(context, contractId, dfdData: dfd);
    if (!context.mounted) return;

    if (tipoObra.isEmpty) {
      NotificationCenter.instance.show(
        AppNotification(
          title: const Text('Tipo de obra não definido no DFD'),
          subtitle: Text('Cadastre o tipo no DFD para: $resumoContrato'),
          type: AppNotificationType.error,
        ),
      );
      return;
    }

    final km = dfd?.extensaoKm ?? 0.0;
    final totalEstacas = ((km * 1000) / 20).ceil();

    if (tipoObra.contains('RODOV')) {
      navigator.push(
        MaterialPageRoute(
          builder: (_) => RepositoryProvider<ScheduleRoadRepository>(
            create: (_) => ScheduleRoadRepository(),
            child: BlocProvider<ScheduleRoadCubit>(
              create: (ctx) => ScheduleRoadCubit(
                repository: ctx.read<ScheduleRoadRepository>(),
              )..warmup(
                contractId: contractId,
                totalEstacas: totalEstacas,
                initialServiceKey: 'geral',
                summarySubjectContract: resumoContrato,
              ),
              child: Scaffold(
                body: ScheduleRoadWorkspacePage(contractData: contract),
              ),
            ),
          ),
        ),
      );
      return;
    }

    if (tipoObra.contains('CONSTRU')) {
      final scheduleCtrl = ScheduleCivilController();

      navigator.push(
        MaterialPageRoute(
          builder: (_) => MultiBlocProvider(
            providers: [
              BlocProvider<CivilScheduleBloc>(
                create: (ctx) =>
                CivilScheduleBloc()..add(CivilWarmupRequested(contractId)),
              ),
              BlocProvider<MapOverlayCubit>(
                create: (_) => MapOverlayCubit(),
              ),
            ],
            child: Scaffold(
              body: ScheduleCivilWorkspacePage(
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

    if (tipoObra.contains('OAE') || tipoObra.contains('ARTES ESPECIAIS')) {
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
        title: const Text('Tipo de obra não suportado'),
        subtitle: Text('Tipo lido no DFD: $tipoObra'),
        type: AppNotificationType.error,
      ),
    );
  }

  Widget _buildContractsListPage(
      DemandNavigationCallback onTap, {
        required String pageTitle,
      }) {
    return ListDemandPage(
      pageTitle: pageTitle,
      onTapItem: onTap,
    );
  }

  Widget _getPage(ModuleItem item, UserData currentUser) {
    switch (item) {
      case ModuleItem.overviewDashboard:
        return const GeneralDashboardPage();

      case ModuleItem.specificDashboard:
        return _buildContractsListPage((context, contract) async {
          final navigator = Navigator.of(context);
          final store = context.read<ProcessStore>();
          final dfdBloc = context.read<DfdCubit>();

          store.select(contract);

          final DfdData? dfd =
          await dfdBloc.getDataForContract(contract.id ?? '');
          if (!context.mounted) return;

          final km = dfd?.extensaoKm ?? 0.0;
          final totalEstacas = ((km * 1000) / 20).ceil();

          final contractId = contract.id ?? '';

          final resumoContrato =
          await _buildContractLabel(context, contractId, dfdData: dfd);
          if (!context.mounted) return;

          navigator.push(
            MaterialPageRoute(
              builder: (_) => RepositoryProvider<ScheduleRoadRepository>(
                create: (_) => ScheduleRoadRepository(),
                child: BlocProvider<ScheduleRoadCubit>(
                  create: (ctx) => ScheduleRoadCubit(
                    repository: ctx.read<ScheduleRoadRepository>(),
                  )..warmup(
                    contractId: contractId,
                    totalEstacas: totalEstacas,
                    initialServiceKey: 'geral',
                    summarySubjectContract: resumoContrato,
                  ),
                  child: SpecificDashboardPage(contractData: contract),
                ),
              ),
            ),
          );
        }, pageTitle: 'Planejamento específico');

      case ModuleItem.processHiringRecords:
        return _buildContractsListPage((context, contract) {
          final storesCtx = context;
          Navigator.of(context)
              .push(
            MaterialPageRoute(
              builder: (_) => TabBarHiringPage(contractData: contract),
            ),
          )
              .then((_) async {
            if (!storesCtx.mounted) return;
            await storesCtx.read<ProcessStore>().refresh();
          });
        }, pageTitle: 'Contratação');

      case ModuleItem.processValidityRecords:
        return _buildContractsListPage((context, contract) {
          context.read<ProcessStore>().select(contract);
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ValidityTabBarPage(contractData: contract),
            ),
          );
        }, pageTitle: 'Ordens e Vigência');

      case ModuleItem.processAdditiveRecords:
        return _buildContractsListPage((context, contract) {
          context.read<ProcessStore>().select(contract);
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => TabBarAdditivePage(contractData: contract),
            ),
          );
        }, pageTitle: 'Aditivos');

      case ModuleItem.processApostillesRecords:
        return _buildContractsListPage((context, contract) {
          context.read<ProcessStore>().select(contract);
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => TabBarApostillesPage(contractData: contract),
            ),
          );
        }, pageTitle: 'Apostilamentos');

      case ModuleItem.processHiringBudget:
        return _buildContractsListPage((context, contract) {
          context.read<ProcessStore>().select(contract);
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => HiringBudgetPage(contractData: contract),
            ),
          );
        }, pageTitle: 'Orçamento');

      case ModuleItem.processHiringSchedule:
        return _buildContractsListPage((context, contract) async {
          final navigator = Navigator.of(context);
          final store = context.read<ProcessStore>();
          final dfdBloc = context.read<DfdCubit>();

          store.select(contract);

          final contractId = contract.id ?? '';
          if (contractId.isEmpty) {
            NotificationCenter.instance.show(
              AppNotification(
                title: const Text('Contrato sem ID'),
                subtitle: const Text('Não foi possível abrir o cronograma.'),
                type: AppNotificationType.error,
              ),
            );
            return;
          }

          final DfdData? dfd = await dfdBloc.getDataForContract(contractId);
          if (!context.mounted) return;

          final km = dfd?.extensaoKm ?? 0.0;
          final totalEstacas = ((km * 1000) / 20).ceil();

          final resumoContrato =
          await _buildContractLabel(context, contractId, dfdData: dfd);
          if (!context.mounted) return;

          navigator.push(
            MaterialPageRoute(
              builder: (_) => RepositoryProvider<ScheduleRoadRepository>(
                create: (_) => ScheduleRoadRepository(),
                child: BlocProvider<ScheduleRoadCubit>(
                  create: (ctx) => ScheduleRoadCubit(
                    repository: ctx.read<ScheduleRoadRepository>(),
                  )..warmup(
                    contractId: contractId,
                    totalEstacas: totalEstacas,
                    initialServiceKey: 'geral',
                    summarySubjectContract: resumoContrato,
                  ),
                  child: HiringSchedulePage(contract: contract),
                ),
              ),
            ),
          );
        }, pageTitle: 'Cronograma');

      case ModuleItem.processMeasurementsRecords:
        return _buildContractsListPage((context, contract) {
          context.read<ProcessStore>().select(contract);
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => TabBarMeasurementPage(contractData: contract),
            ),
          );
        }, pageTitle: 'Medições');

      case ModuleItem.operationMonitoringWork:
        return _buildContractsListPage((context, contract) async {
          context.read<ProcessStore>().select(contract);
          await _navigateByWorkType(context, contract);
        }, pageTitle: 'Diário de Obra');

      case ModuleItem.planningProjectRegistration:
        return GeoNetworkPage();

      case ModuleItem.planningRightOfWayRecords:
        return _buildContractsListPage((context, contract) {
          context.read<ProcessStore>().select(contract);
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => LandPage(contractData: contract),
            ),
          );
        }, pageTitle: 'Desapropriações');

      case ModuleItem.planningEnvironmentRecords:
        return const GeoNetworkPage();

      case ModuleItem.trafficAccidentsDashboard:
        return const AccidentDashboardPage();

      case ModuleItem.trafficAccidentsRecords:
        return const AccidentsRecordsNetworkPage();

      case ModuleItem.trafficInfractionsDashboard:
        return const InfractionsDashboardPage();

      case ModuleItem.trafficInfractionsRecords:
        return const InfractionsRecordsPage();

      case ModuleItem.financialDashboard:
        return const FinancialDashboardNetworkPage();

      case ModuleItem.financialBudget:
        return _buildContractsListPage((context, contract) {
          context.read<ProcessStore>().select(contract);
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => BudgetNetworkPage(contractData: contract),
            ),
          );
        }, pageTitle: 'Orçamento (por contrato)');

      case ModuleItem.financialEmpenhos:
        return const EmpenhoNetworkPage();

      case ModuleItem.financialCommitmentRecords:
        return _buildContractsListPage((context, contract) {
          context.read<ProcessStore>().select(contract);
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) =>
                  FinancialDashboardNetworkPage(contractData: contract),
            ),
          );
        }, pageTitle: 'Financeiro (por contrato)');

      case ModuleItem.activeRoadNetwork:
        return const ActiveRoadsNetworkPage();

      case ModuleItem.activeRoadRegistration:
        return const ActiveRoadsRecordsPage();

      case ModuleItem.activesOAEsNetwork:
        return const ActiveOAEsNetworkPage();

      case ModuleItem.activeOAEsRegistration:
        return const ActiveOaesRecordsPage();

      case ModuleItem.activeAirportsNetwork:
        return const ActiveAirportNetworkPage();

      case ModuleItem.activeAirportsRegistration:
        return const ActiveAirportRecordsPage();

      case ModuleItem.activeRailwaysNetwork:
        return const ActiveRailwaysNetworkPage();

      case ModuleItem.activeRailwaysRegistration:
        return const ActiveRailwaysRecordsPage();

      case ModuleItem.activePortsNetwork:
        return const ActiveRoadsNetworkPage();

      case ModuleItem.activeRegistrationPorts:
        return const ActiveRoadsRecordsPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_didWarmupUserBloc) {
      _didWarmupUserBloc = true;
      final userBloc = context.read<UserBloc>();

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        userBloc.add(
          const UserWarmupRequested(
            listenRealtime: true,
            bindCurrentUser: true,
          ),
        );
      });
    }

    return BlocBuilder<UserBloc, UserState>(
      buildWhen: (prev, curr) =>
      prev.current != curr.current ||
          prev.isLoadingUsers != curr.isLoadingUsers,
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
          final processStore = context.read<ProcessStore>();

          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            processStore.warmup(currentUser);
          });
        }

        return Scaffold(
          backgroundColor: Colors.white,
          drawer: PointerInterceptor(
            child: DrawerMenu(
              onTap: _onSelectPage,
              onTapHome: _goHome,
            ),
          ),
          body: Stack(
            children: [
              if (_selectedItem == null)
                HomeBody(onSelect: _onSelectPage)
              else
                _getPage(_selectedItem!, currentUser),
              const FloatButtonMenu(),
            ],
          ),
        );
      },
    );
  }
}