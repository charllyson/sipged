// lib/screens/menus/menu_list_page.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';

// ===== Process (core) =====
import 'package:siged/_blocs/_process/process_data.dart';
import 'package:siged/_blocs/_process/process_storage_bloc.dart';
import 'package:siged/_blocs/_process/process_controller.dart';
import 'package:siged/_blocs/_process/process_store.dart';

// ===== Dashboards / Stores auxiliares =====
import 'package:siged/_blocs/panels/overview-dashboard/demands_dashboard_controller.dart';
import 'package:siged/_blocs/process/adjustment/adjustment_measurement_store.dart';
import 'package:siged/_blocs/process/hiring/5Edital/edital_bloc.dart';
import 'package:siged/_blocs/process/report/report_measurement_store.dart';
import 'package:siged/_blocs/process/revision/revision_measurement_store.dart';
import 'package:siged/_blocs/process/additives/additive_store.dart';
import 'package:siged/_blocs/process/apostilles/apostilles_store.dart';

// ===== Setores (Operação) =====
import 'package:siged/_blocs/sectors/operation/civil/civil_schedule_bloc.dart';
import 'package:siged/_blocs/sectors/operation/civil/civil_schedule_event.dart';
import 'package:siged/_blocs/sectors/operation/road/schedule_road_event.dart';
import 'package:siged/_blocs/sectors/operation/road/schedule_road_repository.dart';
import 'package:siged/_blocs/sectors/operation/road/schedule_road_bloc.dart';

// ===== UI / Serviços =====
import 'package:siged/_widgets/footBar/foot_bar.dart';
import 'package:siged/_widgets/notification/notification_center.dart';
import 'package:siged/_widgets/notification/app_notification.dart';
import 'package:siged/_services/dxf/map_overlay_cubit.dart';
import 'package:siged/_widgets/list/demand/list_demand_page.dart';
import 'package:siged/home_page.dart';

// ===== Páginas =====
import 'package:siged/screens-legal/crm/tab_bar_crm_precatory_page.dart';
import 'package:siged/screens/panels/specific-dashboard/specific_dashboard_page.dart';

import 'package:siged/screens/process/additive/tab_bar_additive_page.dart';
import 'package:siged/screens/process/apostilles/tab_bar_apostilles_page.dart';
import 'package:siged/screens/process/hiring/5Edital/hiring_budget_page.dart';
import 'package:siged/screens/process/hiring/5Edital/hiring_schedule_page.dart';
import 'package:siged/screens/process/hiring/tab_bar_hiring_page.dart';

import 'package:siged/screens/panels/overview-dashboard/overview_dashboard_page.dart';
import 'package:siged/screens/process/measurement/tab_bar_measurement_page.dart';
import 'package:siged/screens/process/validity/validity_tab_bar.dart';

import 'package:siged/screens/sectors/operation/schedule/civil/schedule_civil_workspace_page.dart';
import 'package:siged/_widgets/toolBox/tool_widget_controller.dart';

import 'package:siged/screens/actives/airports/network/active_airports_network_page.dart';
import 'package:siged/screens/actives/airports/records/active_airports_records_page.dart';
import 'package:siged/screens/actives/railways/network/active_railways_network_page.dart';
import 'package:siged/screens/actives/railways/records/active_railways_records_page.dart';
import 'package:siged/screens/actives/oaes/network/active_oaes_network_page.dart';
import 'package:siged/screens/actives/oaes/records/active_oaes_records_page.dart';
import 'package:siged/screens/actives/roads/network/active_roads_network_page.dart';
import 'package:siged/screens/actives/roads/records/active_roads_records_page.dart';

import 'package:siged/screens/sectors/financial/dashboard/dashboard_financial_page.dart';
import 'package:siged/screens/sectors/financial/tab_bar_financial_page.dart';

import 'package:siged/screens/sectors/operation/schedule/road/schedule_road_workspace_page.dart';
import 'package:siged/screens/sectors/planning/environment/planning_environment_dashboard.dart';
import 'package:siged/screens/menus/menu_drawer.dart';

import 'package:siged/_blocs/system/pages/pages_data.dart';
import 'package:siged/_widgets/buttons/float_button_menu.dart';

import 'package:siged/screens/sectors/planning/rightWay/planning_right_way_workspace_page.dart';

import 'package:siged/screens/sectors/traffic/accidents/accidents_records_network_page.dart';
import 'package:siged/screens/sectors/traffic/dashboard/accidents_dashboard_network_page.dart';
import 'package:siged/screens/sectors/traffic/infractions-dashboard/infractions_dashboard_page.dart';
import 'package:siged/screens/sectors/traffic/infrations-records/infractions_records_page.dart';

// ===== Sistema / Usuários =====
import 'package:siged/_blocs/system/user/user_bloc.dart';
import 'package:siged/_blocs/system/user/user_event.dart';
import 'package:siged/_blocs/system/user/user_state.dart';
import 'package:siged/_blocs/system/user/user_data.dart';

// ===== Planejamento =====
import '../sectors/planning/sigmine/sigmine_network_page.dart';

// ===== DFD via BLoC =====
import 'package:siged/_blocs/process/hiring/1Dfd/dfd_bloc.dart';
import 'package:siged/_blocs/process/hiring/1Dfd/dfd_data.dart';

// ===== Publicação (para número do contrato) =====
import 'package:siged/_blocs/process/hiring/10Publicacao/publicacao_extrato_bloc.dart';
import 'package:siged/_blocs/process/hiring/10Publicacao/publicacao_extrato_data.dart';

class MenuListPage extends StatefulWidget {
  const MenuListPage({super.key});

  @override
  State<MenuListPage> createState() => _MenuListPageState();
}

class _MenuListPageState extends State<MenuListPage> {
  MenuItem? _selectedItem;
  bool _didWarmupUserBloc = false;
  bool _didWarmupStores = false;

  @override
  void initState() {
    super.initState();
    debugPrint('MenuListPage.initState');
  }

  void _onSelectPage(MenuItem item) {
    debugPrint('MenuListPage: selecionando item de menu -> $item');
    setState(() => _selectedItem = item);
    Navigator.of(context).maybePop();
  }

  void _goHome() {
    debugPrint('MenuListPage: voltando para Home');
    setState(() => _selectedItem = null);
    Navigator.of(context).maybePop();
  }

  /// Monta o rótulo do contrato SEM usar campos legados do ProcessData.
  /// Prioridades:
  ///   1) PublicacaoExtratoData.numeroContrato
  ///   2) DfdData.descricaoObjeto
  ///   3) "Contrato {id}"
  Future<String> _buildContractLabel(
      BuildContext context,
      String contractId, {
        DfdData? dfdData,
      }) async {
    debugPrint('MenuListPage._buildContractLabel -> contractId=$contractId');

    DfdData? dfd = dfdData;

    // Garante DFD carregado
    if (dfd == null) {
      try {
        final dfdBloc = context.read<DfdBloc>();
        dfd = await dfdBloc.getDataForContract(contractId);
        debugPrint(
            'MenuListPage._buildContractLabel: DFD carregado para $contractId (descricaoObjeto="${dfd?.descricaoObjeto}")');
      } catch (e) {
        debugPrint(
            'MenuListPage._buildContractLabel: erro ao carregar DFD de $contractId -> $e');
      }
    }

    PublicacaoExtratoData? publicacao;
    try {
      final pubBloc = context.read<PublicacaoExtratoBloc>();
      publicacao = await pubBloc.getDataForContract(contractId);
      debugPrint(
          'MenuListPage._buildContractLabel: Publicacao carregada para $contractId (numeroContrato="${publicacao?.numeroContrato}")');
    } catch (e) {
      debugPrint(
          'MenuListPage._buildContractLabel: erro ao carregar Publicacao de $contractId -> $e');
    }

    final numero = (publicacao?.numeroContrato ?? '').trim();
    final descricao = (dfd?.descricaoObjeto ?? '').trim();

    if (numero.isNotEmpty && descricao.isNotEmpty) {
      return '$numero - $descricao';
    }
    if (numero.isNotEmpty) return numero;
    if (descricao.isNotEmpty) return descricao;

    return 'Contrato $contractId';
  }

  Future<void> _navigateByWorkType(
      BuildContext context,
      ProcessData contract,
      ) async {
    final contractId = contract.id ?? '';
    debugPrint('MenuListPage._navigateByWorkType -> contractId=$contractId');

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

    final dfdBloc = context.read<DfdBloc>();
    final DfdData? dfd = await dfdBloc.getDataForContract(contractId);

    final tipoObra = (dfd?.tipoObra ?? '').trim().toUpperCase();
    final resumoContrato =
    await _buildContractLabel(context, contractId, dfdData: dfd);

    debugPrint(
        'MenuListPage._navigateByWorkType: tipoObra="$tipoObra" | resumo="$resumoContrato"');

    if (tipoObra.isEmpty) {
      NotificationCenter.instance.show(
        AppNotification(
          title: const Text('Tipo de obra não definido no DFD'),
          subtitle: Text(
            'Cadastre o tipo no DFD para: $resumoContrato',
          ),
          type: AppNotificationType.error,
        ),
      );
      return;
    }

    final km = dfd?.extensaoKm ?? 0.0;
    final totalEstacas = ((km * 1000) / 20).ceil();
    debugPrint(
        'MenuListPage._navigateByWorkType: km=$km -> totalEstacas=$totalEstacas');

    if (tipoObra.contains('RODOV')) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => RepositoryProvider<ScheduleRoadRepository>(
            create: (_) => ScheduleRoadRepository(),
            child: BlocProvider<ScheduleRoadBloc>(
              create: (ctx) => ScheduleRoadBloc(
                repository: ctx.read<ScheduleRoadRepository>(),
              )
                ..add(
                  ScheduleWarmupRequested(
                    contractId: contractId,
                    totalEstacas: totalEstacas,
                    initialServiceKey: 'geral',
                    summarySubjectContract: resumoContrato,
                  ),
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
      Navigator.of(context).push(
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
    debugPrint(
        'MenuListPage._buildContractsListPage -> pageTitle="$pageTitle"');
    return ListDemandPage(
      pageTitle: pageTitle,
      onTapItem: onTap,
    );
  }

  Widget _getPage(MenuItem item, UserData currentUser) {
    debugPrint('MenuListPage._getPage -> $item');

    switch (item) {
      case MenuItem.overviewDashboard:
        return ChangeNotifierProvider(
          create: (ctx) {
            final ctrl = DemandsDashboardController(
              store: ctx.read<ProcessStore>(),
              additivesStore: ctx.read<AdditivesStore>(),
              apostillesStore: ctx.read<ApostillesStore>(),
              reportsMeasurementStore: ctx.read<ReportsMeasurementStore>(),
              adjustmentsStore: ctx.read<AdjustmentsMeasurementStore>(),
              revisionsStore: ctx.read<RevisionsMeasurementStore>(),
              dfdBloc: ctx.read<DfdBloc>(),
              editalBloc: ctx.read<EditalBloc>(),
            );
            WidgetsBinding.instance.addPostFrameCallback((_) {
              debugPrint('DemandsDashboardController.initialize() chamado');
              ctrl.initialize();
            });
            return ctrl;
          },
          child: const OverviewDashboardPage(),
        );

      case MenuItem.specificDashboard:
        return _buildContractsListPage((context, contract) async {
          debugPrint(
              'MenuItem.specificDashboard -> onTapItem, contrato=${contract.id}');
          context.read<ProcessStore>().select(contract);

          final dfdBloc = context.read<DfdBloc>();
          final DfdData? dfd = await dfdBloc.getDataForContract(contract.id ?? '');
          final km = dfd?.extensaoKm ?? 0.0;
          final totalEstacas = ((km * 1000) / 20).ceil();

          final contractId = contract.id ?? '';
          final resumoContrato =
          await _buildContractLabel(context, contractId, dfdData: dfd);

          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => RepositoryProvider<ScheduleRoadRepository>(
                create: (_) => ScheduleRoadRepository(),
                child: BlocProvider<ScheduleRoadBloc>(
                  create: (ctx) => ScheduleRoadBloc(
                    repository: ctx.read<ScheduleRoadRepository>(),
                  )
                    ..add(
                      ScheduleWarmupRequested(
                        contractId: contractId,
                        totalEstacas: totalEstacas,
                        initialServiceKey: 'geral',
                        summarySubjectContract: resumoContrato,
                      ),
                    ),
                  child: SpecificDashboardPage(
                    contractData: contract,
                  ),
                ),
              ),
            ),
          );
        }, pageTitle: 'Planejamento específico');

      case MenuItem.processHiringRecords:
        return _buildContractsListPage((context, contract) {
          debugPrint(
              'MenuItem.processHiringRecords -> contrato selecionado=${contract.id}');
          final storesCtx = context;

          Navigator.of(context)
              .push(
            MaterialPageRoute(
              builder: (_) => ChangeNotifierProvider<ProcessController>(
                create: (ctx) {
                  final ctrl = ProcessController(
                    store: storesCtx.read<ProcessStore>(),
                    additivesStore: storesCtx.read<AdditivesStore>(),
                    apostillesStore: storesCtx.read<ApostillesStore>(),
                    reportsMeasurementStore:
                    storesCtx.read<ReportsMeasurementStore>(),
                    adjustmentsStore:
                    storesCtx.read<AdjustmentsMeasurementStore>(),
                    revisionsStore:
                    storesCtx.read<RevisionsMeasurementStore>(),
                    processStorageBloc:
                    storesCtx.read<ProcessStorageBloc>(),
                  );
                  WidgetsBinding.instance.addPostFrameCallback((_) async {
                    debugPrint(
                        'ProcessController.init chamado para contrato ${contract.id}');
                    await ctrl.init(ctx, initial: contract);
                  });
                  return ctrl;
                },
                child: TabBarHiringPage(contractData: contract),
              ),
            ),
          )
              .then((_) async {
            debugPrint(
                'Retornou de TabBarHiringPage, chamando store.refresh()');
            await storesCtx.read<ProcessStore>().refresh();
          });
        }, pageTitle: 'Contratação');

      case MenuItem.processValidityRecords:
        return _buildContractsListPage((context, contract) {
          debugPrint(
              'MenuItem.processValidityRecords -> contrato=${contract.id}');
          context.read<ProcessStore>().select(contract);
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ValidityTabBarPage(contractData: contract),
            ),
          );
        }, pageTitle: 'Ordens e Vigência');

      case MenuItem.processAdditiveRecords:
        return _buildContractsListPage((context, contract) {
          debugPrint(
              'MenuItem.processAdditiveRecords -> contrato=${contract.id}');
          context.read<ProcessStore>().select(contract);
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => TabBarAdditivePage(contractData: contract),
            ),
          );
        }, pageTitle: 'Aditivos');

      case MenuItem.processApostillesRecords:
        return _buildContractsListPage((context, contract) {
          debugPrint(
              'MenuItem.processApostillesRecords -> contrato=${contract.id}');
          context.read<ProcessStore>().select(contract);
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => TabBarApostillesPage(contractData: contract),
            ),
          );
        }, pageTitle: 'Apostilamentos');

      case MenuItem.processHiringBudget:
        return _buildContractsListPage((context, contract) {
          debugPrint(
              'MenuItem.processHiringBudget -> contrato=${contract.id}');
          context.read<ProcessStore>().select(contract);
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => HiringBudgetPage(contractData: contract),
            ),
          );
        }, pageTitle: 'Orçamento');

      case MenuItem.processHiringSchedule:
        return _buildContractsListPage((context, contract) async {
          debugPrint(
              'MenuItem.processHiringSchedule -> contrato=${contract.id}');
          context.read<ProcessStore>().select(contract);

          final contractId = contract.id ?? '';
          if (contractId.isEmpty) {
            NotificationCenter.instance.show(
              AppNotification(
                title: const Text('Contrato sem ID'),
                subtitle:
                const Text('Não foi possível abrir o cronograma.'),
                type: AppNotificationType.error,
              ),
            );
            return;
          }

          final dfdBloc = context.read<DfdBloc>();
          final DfdData? dfd =
          await dfdBloc.getDataForContract(contractId);
          final km = dfd?.extensaoKm ?? 0.0;
          final totalEstacas = ((km * 1000) / 20).ceil();

          final resumoContrato =
          await _buildContractLabel(context, contractId, dfdData: dfd);

          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => RepositoryProvider<ScheduleRoadRepository>(
                create: (_) => ScheduleRoadRepository(),
                child: BlocProvider<ScheduleRoadBloc>(
                  create: (ctx) => ScheduleRoadBloc(
                    repository: ctx.read<ScheduleRoadRepository>(),
                  )
                    ..add(
                      ScheduleWarmupRequested(
                        contractId: contractId,
                        totalEstacas: totalEstacas,
                        initialServiceKey: 'geral',
                        summarySubjectContract: resumoContrato,
                      ),
                    ),
                  child: HiringSchedulePage(contract: contract),
                ),
              ),
            ),
          );
        }, pageTitle: 'Cronograma');

      case MenuItem.processMeasurementsRecords:
        return _buildContractsListPage((context, contract) {
          debugPrint(
              'MenuItem.processMeasurementsRecords -> contrato=${contract.id}');
          context.read<ProcessStore>().select(contract);
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => TabBarMeasurementPage(contractData: contract),
            ),
          );
        }, pageTitle: 'Medições');

      case MenuItem.operationMonitoringWork:
        return _buildContractsListPage((context, contract) async {
          debugPrint(
              'MenuItem.operationMonitoringWork -> contrato=${contract.id}');
          context.read<ProcessStore>().select(contract);
          await _navigateByWorkType(context, contract);
        }, pageTitle: 'Diário de Obra');

      case MenuItem.planningProjectRegistration:
        return SigmineNetworkPage();

      case MenuItem.planningRightOfWayRecords:
        return _buildContractsListPage((context, contract) {
          debugPrint(
              'MenuItem.planningRightOfWayRecords -> contrato=${contract.id}');
          context.read<ProcessStore>().select(contract);
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) =>
                  PlanningRightWayWorkspacePage(contractData: contract),
            ),
          );
        }, pageTitle: 'Desapropriações');

      case MenuItem.planningEnvironmentRecords:
        return const PlanningEnvironmentDashboardPage();

      case MenuItem.trafficAccidentsDashboard:
        return const AccidentsDashboardNetworkPage();

      case MenuItem.trafficAccidentsRecords:
        return const AccidentsRecordsNetworkPage();

      case MenuItem.trafficInfractionsDashboard:
        return const InfractionsDashboardPage();

      case MenuItem.trafficInfractionsRecords:
        return const InfractionsRecordsPage();

      case MenuItem.financialPaymentsDashboard:
        return const DashboardFinancialPage();

      case MenuItem.financialPaymentsRecords:
        return _buildContractsListPage((context, contract) {
          debugPrint(
              'MenuItem.financialPaymentsRecords -> contrato=${contract.id}');
          context.read<ProcessStore>().select(contract);
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) =>
                  TabBarFinancialPage(contractData: contract),
            ),
          );
        }, pageTitle: 'Pagamentos de medições');

      case MenuItem.financialCommitmentDashboard:
        return const DashboardFinancialPage();

      case MenuItem.financialCommitmentRecords:
        return _buildContractsListPage((context, contract) {
          debugPrint(
              'MenuItem.financialCommitmentRecords -> contrato=${contract.id}');
          context.read<ProcessStore>().select(contract);
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) =>
                  TabBarFinancialPage(contractData: contract),
            ),
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

      case MenuItem.crmLegal:
        return TabBarCrmPrecatoryPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Warmup do UserBloc (apenas 1x)
    if (!_didWarmupUserBloc) {
      _didWarmupUserBloc = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        debugPrint('MenuListPage: disparando UserWarmupRequested');
        context.read<UserBloc>().add(
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
          debugPrint('MenuListPage: currentUser ainda é null');
          return const Scaffold(
            backgroundColor: Colors.white,
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Warmup do ProcessStore (apenas 1x após usuário carregado)
        if (!_didWarmupStores) {
          _didWarmupStores = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            debugPrint(
                'MenuListPage: chamando ProcessStore.warmup para user=${currentUser.uid}');
            context.read<ProcessStore>().warmup(currentUser);
          });
        }

        return Scaffold(
          backgroundColor: Colors.white,
          drawer: DrawerMenu(
            onTap: _onSelectPage,
            onTapHome: _goHome,
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
          bottomNavigationBar: const FootBar(),
        );
      },
    );
  }
}
